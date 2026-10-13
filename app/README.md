# conmoney 앱

Flutter 앱 + Kotlin 알림 리스너. 전체 설명은 저장소 루트의 `CLAUDE.md`, `docs/`를 본다.

- `lib/core/` — 계산 로직(순수 Dart, Flutter 의존 없음). Spec 3장
- `lib/platform/` — Kotlin과 통신하는 MethodChannel
- `lib/features/` — 화면
- `android/app/src/main/kotlin/.../PaymentNotificationListener.kt` — 카드사 알림 수신, 원문 저장

```bash
flutter test
```
