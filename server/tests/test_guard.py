import json

from app import guard


def test_금액_추출_한국어_단위():
    assert guard.amounts_in("키보드 15만 원 살까?") == {150000}
    assert guard.amounts_in("남은 예산 216,000원, 21만 6천 원, 5천 원, 990원") == {216000, 5000, 990}
    assert guard.amounts_in("1.5만원") == {15000}
    assert guard.amounts_in("이번 주 배달을 2번 줄이면 12일 남았어요") == set()


def _out(call_id, name, payload):
    return [
        {"type": "function_call", "call_id": call_id, "name": name, "arguments": "{}"},
        {"type": "function_call_output", "call_id": call_id, "output": json.dumps(payload, ensure_ascii=False)},
    ]


ITEMS = [
    {"role": "user", "content": "키보드 15만 원 살까?"},
    *_out("c1", "simulate_purchase", {"verdict": "postpone", "remaining_after": 66000, "remaining_after_text": "66,000원",
                                      "projected_over": 154321, "projected_over_text": "154,321원"}),
]


def test_툴_결과와_사용자_금액만_허용_표시용_내림도_허용():
    assert guard.unverified_amounts("남은 예산이 66,000원이 돼요. 키보드 15만 원", ITEMS) == set()
    assert guard.unverified_amounts("월말에 154,300원 넘을 수 있어요", ITEMS) == set()  # 100원 단위 내림
    assert guard.unverified_amounts("월말에 15만 원 넘어요", ITEMS) == set()  # 사용자 금액과 같음
    assert guard.unverified_amounts("남은 예산이 70,000원이 돼요", ITEMS) == {70000}


def test_판단_불일치():
    v = guard.last_verdict(ITEMS)
    assert v == "postpone"
    assert not guard.verdict_mismatch("[판단] 미루는 걸 추천\n[근거] ...", v)
    assert guard.verdict_mismatch("[판단] 괜찮아요\n[근거] ...", v)


def test_범위_밖_질문과_마스킹():
    assert guard.out_of_scope("삼성전자 주식 살까?")
    assert guard.out_of_scope("신용대출 받아도 돼?")
    assert not guard.out_of_scope("키보드 15만 원 살까?")
    assert guard.mask("카드 1234-5678-****-9012 승인번호 30968403") == "카드 ****-****-****-**** 승인번호 ******"
