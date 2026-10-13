"""카드사 이용내역 파일(카드내역/)을 하나의 CSV로 합친다.

지원 형식
- 롯데카드: 이용내역 다운로드(.xls, 실제로는 HTML). 국내/해외 표가 따로 있음
- 현대카드: 이용대금명세서(.xls, HTML). 파일명 월 = 이용월, 할부는 회차별로 여러 파일에 반복 등장
- 신한카드: 이용대금명세서(.xls, HTML). 모바일후불티머니 월 합산(교통비). 2026-09 이후 사용 안 함(과거 기록만)
- 토스뱅크카드: 후불교통 이용내역서(.pdf). pypdf 필요(없으면 건너뜀)

검수 라벨: data/labels.csv(사용자 검수본 transactions_checked.csv + 10/13 추가 수정)가 있으면 같은 거래의 category·is_foreign·cancelled를
가져와 category 열(정답)과 해당 열에 덮어쓴다. category_guess는 항상 규칙 추정값이다.

사용: python tools/import_statements.py [카드내역 폴더] [출력 CSV]
"""
import csv
import re
import sys
from collections import Counter, defaultdict
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class _TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.rows, self._row, self._cell = [], None, None

    def handle_starttag(self, tag, attrs):
        if tag == "tr":
            self._row = []
        elif tag in ("td", "th"):
            self._cell = ""

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self._row is not None and self._cell is not None:
            self._row.append(re.sub(r"\s+", " ", self._cell).strip())
            self._cell = None
        elif tag == "tr" and self._row is not None:
            self.rows.append(self._row)
            self._row = None

    def handle_data(self, data):
        if self._cell is not None:
            self._cell += data


def read_html_rows(path):
    raw = path.read_bytes()
    for enc in ("utf-8", "cp949"):
        try:
            text = raw.decode(enc)
            break
        except UnicodeDecodeError:
            continue
    p = _TableParser()
    p.feed(text)
    return p.rows


def won(s):
    s = (s or "").replace(",", "").strip()
    if s in ("", "-"):
        return 0
    return int(float(s))


def tx(**kw):
    base = dict(date="", time="", card="", merchant_raw="", merchant="", amount=0,
                installment_months=1, is_foreign=False, currency="KRW", original_amount="",
                cancelled=False, source="", category_guess="", is_unusual=False)
    base.update(kw)
    return base


# ---------------------------------------------------------------- 롯데카드
def parse_lotte(path):
    out, mode = [], None
    for r in read_html_rows(path):
        if r[:2] == ["이용일자", "이용시간"]:
            mode = "foreign" if "현지통화" in r else "domestic"
            continue
        if not r or not re.match(r"\d{4}\.\d{2}\.\d{2}$", r[0]):
            continue
        date = r[0].replace(".", "-")
        if mode == "domestic":
            months = 1 if r[7] in ("-", "") else int(r[7])
            out.append(tx(date=date, time=r[1], card="롯데 " + r[2].replace("본인 ", ""),
                          merchant_raw=r[3], amount=won(r[5]), installment_months=months,
                          cancelled=(r[9] == "Y" and won(r[11]) == -won(r[5])), source=path.name))
        else:
            # 통화 없이 매입 N인 행은 해외 가승인(카드 확인용 소액)이라 합계에서 빠진다
            if not r[6] and r[12] == "N":
                continue
            out.append(tx(date=date, time=r[1], card="롯데 " + r[2].replace("본인 ", ""),
                          merchant_raw=r[3], amount=won(r[13]), is_foreign=(r[6] != "KRW"),
                          currency=r[6], original_amount=f"{r[6]} {r[7]}", source=path.name))
    return out


# ---------------------------------------------------------------- 현대카드
_PG_PREFIX = re.compile(r"^(KCP|나이스|\(주\)이니시스|토스페이먼츠(주식회사)?|한국정보통신|카카오|씨제이시스템즈\(주\)|다날|KG모빌리언스|신한은행)\s*-\s*")


def parse_hyundai(path):
    out = []
    for r in read_html_rows(path):
        if len(r) < 10:
            continue
        m = re.match(r"(\d{4})년 (\d{2})월 (\d{2})일$", r[0])
        if not m:
            continue
        date = "-".join(m.groups())
        merchant = r[2]
        if merchant == "연회비":
            out.append(tx(date=date, card="현대 ZERO", merchant_raw="연회비", amount=won(r[9]),
                          source=path.name))
            continue
        foreign = re.search(r",(USD|KRW|JPY|EUR):([\d.]+)$", merchant)
        months, seq = 1, None
        if re.match(r"\d+/\d+$", r[4]):
            months, seq = map(int, r[4].split("/"))
        out.append(tx(date=date, card="현대 ZERO", merchant_raw=merchant, amount=won(r[3]),
                      installment_months=months, is_foreign=bool(foreign) and foreign.group(1) != "KRW",
                      currency=foreign.group(1) if foreign else "KRW",
                      original_amount=f"{foreign.group(1)} {foreign.group(2)}" if foreign else "",
                      source=path.name, _seq=seq))
    return out


# ---------------------------------------------------------------- 신한카드
def parse_shinhan(path):
    out = []
    for r in read_html_rows(path):
        if len(r) >= 7 and re.match(r"\d{4}\.\d{2}\.\d{2}$", r[0]) and r[1].startswith("본인"):
            months = int(r[4]) if r[4].isdigit() else 1
            out.append(tx(date=r[0].replace(".", "-"), card="신한 " + r[1].replace("본인", ""),
                          merchant_raw=r[2], amount=won(r[3]), installment_months=months,
                          source=path.name))
    return out


# ---------------------------------------------------------------- 토스 후불교통
def parse_toss_transit(path):
    try:
        import pypdf
    except ImportError:
        print(f"[건너뜀] {path.name}: pypdf가 없습니다 (pip install pypdf)", file=sys.stderr)
        return []
    text = "\n".join(p.extract_text() for p in pypdf.PdfReader(str(path)).pages)
    text = re.sub(r"\n\d+ / \d+\n", "\n", text)
    text = re.sub(r"이용일\s*카드번호.*?\(원\)", "", text, flags=re.S)  # 페이지마다 반복되는 표 머리글
    text = text.split("발급일자")[0]
    out = []
    chunks = re.split(r"(?=\b\d{4}\.\d{2}\.\d{2} \d{4}\b)", text)
    for c in chunks:
        m = re.match(r"(\d{4})\.(\d{2})\.(\d{2}) (\d{4})", c)
        if not m:
            continue
        flat = re.sub(r"\s+", " ", c)
        kind = "버스" if flat[16:].lstrip().startswith("버스") else "지하철"
        times = re.findall(r"\b\d{2}:\d{2}\b", flat)
        amount = won(re.findall(r"([\d,]+)\s*$", flat.strip())[0])
        out.append(tx(date=f"{m[1]}-{m[2]}-{m[3]}", time=times[0] if times else "",
                      card="토스뱅크 " + m[4], merchant_raw=f"후불교통 {kind}", amount=amount,
                      source=path.name))
    return out


# ---------------------------------------------------------------- 정규화·분류
def norm_merchant(raw):
    s = _PG_PREFIX.sub("", raw)
    s = re.sub(r",(USD|KRW|JPY|EUR):[\d.]+$", "", s)
    s = re.sub(r"^\(주\)|^㈜|\(주\)$|㈜$", "", s).strip()
    if "우아한형제들" in s or "배민" in s:
        return "배민클럽" if "배민클럽_" in s else "배달의민족"
    if "쿠팡" in s:
        return "쿠팡 와우멤버십" if "와우" in s else "쿠팡"
    if s.startswith("#KT통"):
        return "KT 휴대폰"
    if s.startswith("#한국전력공사"):
        return "한국전력 전기료"
    if "비케이알" in s:
        return "버거킹(비케이알)"
    if "구글페이먼트" in s:
        return "구글플레이"
    # 같은 가맹점이 카드사마다 다르게 찍힌다(현대는 20자에서 잘림, 롯데는 '_법인명'이 붙음)
    if s.startswith("CURSOR"):
        return "Cursor"
    if s.startswith("STEAM"):
        return "Steam"
    if s.startswith("네이버플러스"):
        return "네이버플러스 멤버십"
    if "네이버페이" in s:
        return "네이버페이"
    if s in ("카카오페이", "주식회사 카카오"):
        return "카카오"
    return s


# 위에서부터 처음 맞는 규칙을 쓴다. 카테고리 목록은 검수(2026-10-13)에서 API·영화·연회비가 추가됨
CATEGORY_RULES = [
    ("통신", r"KT 휴대폰|KT인터넷"),
    ("공과금", r"한국전력|yesco|도시가스"),
    ("연회비", r"연회비"),
    ("API", r"OPENAI|GROK|ANLATAN|TYPESAFE"),
    ("구독", r"와우멤버십|배민클럽|네이버플러스|유투브프리미엄|유튜브|컬리_멤버스|피클플러스|^Apple$|^카카오$|CURSOR|야쿠르트"),
    ("교통", r"티머니|택시|고속버스|시외버스|현장발권|후불교통|코레일|SRT"),
    ("카페·간식", r"커피|컴포즈|메가|스타벅스|이디야|투썸|빽다방|엔제리너스|카페|아이스|빵|베이커리|디저트"),
    ("식비", r"배달의민족|요기요|버거|KFC|초밥|훠궈|샤브|쿠우쿠우|맘스|식당|김밥|마트|컬리|이마트|편의점|세븐일레븐|GS\)?25|지에스|씨유|CU"),
    ("게임", r"닌텐도|구글플레이|스팀|STEAM|넥슨|BOARDGAM"),
    ("교육", r"교보문고|와이비엠|YBM|크몽"),
    ("의료", r"약국|의원|병원|치과"),
    ("경조사·선물", r"선물하기"),
    ("쇼핑", r"쿠팡|유니클로|에스에스지|SSG|안경|무신사|올리브영|다이소|글리티|KW JAPAN|네이버페이"),
    ("영화", r"시네마|씨지브이|CGV|메가박스"),
]


# 특이 지출로 표시할 가맹점(평소 패턴 통계에서 제외). 2026-10-13 결정: 닌텐도
UNUSUAL_RULES = [r"닌텐도"]


def guess_category(merchant, amount=0):
    # 가맹점 이름만으로 정할 수 없는 경우(검수 결과)
    if merchant == "구글클라우드코리아":
        return "기타" if amount >= 10000 else "API"  # 만 원 이상은 평소와 다른 결제
    for cat, pat in CATEGORY_RULES:
        if re.search(pat, merchant, re.I):
            return cat
    return ""


def load_all(src):
    rows = []
    for p in sorted(src.glob("롯데카드/*.xls")):
        rows += parse_lotte(p)
    for p in sorted(src.glob("신한카드/*.xls")):
        rows += parse_shinhan(p)
    for p in sorted(src.glob("토스/*.pdf")):
        rows += parse_toss_transit(p)

    # 현대카드: 같은 할부 거래가 회차마다 다른 명세서에 나오므로 (이용일, 가맹점, 금액)으로 하나만 남긴다.
    # 일시불은 한 명세서에만 나오지만 같은 날 같은 금액이 여러 번일 수 있어 파일별 등장 횟수의 최댓값을 쓴다.
    hd_counts, hd_rows = defaultdict(Counter), {}
    for p in sorted(src.glob("현대카드/*.xls")):
        for r in parse_hyundai(p):
            key = (r["date"], r["merchant_raw"], r["amount"], r["installment_months"])
            hd_counts[key][p.name] += 1
            hd_rows.setdefault(key, r)
    for key, per_file in hd_counts.items():
        n = 1 if key[3] > 1 else max(per_file.values())
        for _ in range(n):
            r = dict(hd_rows[key])
            r.pop("_seq", None)
            rows.append(r)

    for r in rows:
        r["merchant"] = norm_merchant(r["merchant_raw"])
        r["category_guess"] = guess_category(r["merchant"], r["amount"])
        r["is_unusual"] = any(re.search(p, r["merchant"]) for p in UNUSUAL_RULES)
    mark_repeating_as_subscription(rows, merchants=("구글플레이",))
    rows.sort(key=lambda r: (r["date"], r["time"]))
    return rows


def mark_repeating_as_subscription(rows, merchants, min_months=3):
    """구독과 추가 결제가 섞이는 가맹점: 같은 금액이 서로 다른 달에 min_months번 이상 나오면 구독."""
    months = defaultdict(set)
    for r in rows:
        if r["merchant"] in merchants:
            months[(r["merchant"], r["amount"])].add(r["date"][:7])
    for r in rows:
        if len(months.get((r["merchant"], r["amount"]), ())) >= min_months:
            r["category_guess"] = "구독"


def _label_key(r, seen):
    k = (r["date"], r["card"], r["merchant_raw"], str(r["amount"]))
    seen[k] += 1
    return k + (seen[k],)


def _bool(v):
    return str(v).strip().upper() == "TRUE"


def apply_labels(rows, labels_path):
    """검수한 CSV에서 category·is_foreign·cancelled를 가져온다. 맞는 행 수를 돌려준다."""
    with labels_path.open(encoding="utf-8-sig") as f:
        labeled = list(csv.DictReader(f))
    seen = Counter()
    by_key = {_label_key(r, seen): r for r in labeled}
    seen, hit = Counter(), 0
    for r in rows:
        lab = by_key.get(_label_key(r, seen))
        if not lab:
            continue
        hit += 1
        r["category"] = lab.get("category") or lab.get("category_guess", "")
        r["is_foreign"] = _bool(lab["is_foreign"])
        r["cancelled"] = _bool(lab["cancelled"])
    return hit


FIELDS = ["date", "time", "card", "merchant", "merchant_raw", "amount", "installment_months",
          "is_foreign", "currency", "original_amount", "cancelled", "category", "category_guess",
          "is_unusual", "source"]


def main():
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "카드내역"
    dst = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "data" / "transactions.csv"
    rows = load_all(src)
    labels = ROOT / "data" / "labels.csv"
    if labels.exists() and labels.resolve() != dst.resolve():
        hit = apply_labels(rows, labels)
        print(f"검수 라벨 {hit}/{len(rows)}건 적용 ← {labels.name}")
    dst.parent.mkdir(parents=True, exist_ok=True)
    with dst.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    print(f"{len(rows)}건 → {dst}")


if __name__ == "__main__":
    main()
