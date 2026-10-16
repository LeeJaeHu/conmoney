import 'package:flutter/widgets.dart';

/// 스크롤 화면의 바깥 여백. Android 15부터 앱이 화면 끝까지 그려져서(edge-to-edge)
/// 맨 아래 내용이 시스템 내비게이션 바에 가려진다 → 그 높이만큼 아래 여백을 더한다(10/16 사용자 제보).
EdgeInsets pagePadding(BuildContext context, {double all = 16, double bottom = 16}) =>
    EdgeInsets.fromLTRB(all, all, all, bottom + MediaQuery.viewPaddingOf(context).bottom);
