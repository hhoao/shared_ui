import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('TpBreakpoints tokens', () {
    test('match Tailwind screens', () {
      expect(TpBreakpoints.sm, 640);
      expect(TpBreakpoints.md, 768);
      expect(TpBreakpoints.lg, 1024);
      expect(TpBreakpoints.xl, 1280);
      expect(TpBreakpoints.xxl, 1536);
      expect(TpBreakpoints.of(TpBreakpoint.sm), 640);
      expect(TpBreakpoints.of(TpBreakpoint.xxl), 1536);
    });
  });

  group('up (mobile first)', () {
    test('sm boundary', () {
      expect(TpBreakpoints.up(639, TpBreakpoint.sm), isFalse);
      expect(TpBreakpoints.up(640, TpBreakpoint.sm), isTrue);
    });
  });

  group('down (desktop first / <token)', () {
    test('sm boundary', () {
      expect(TpBreakpoints.down(639, TpBreakpoint.sm), isTrue);
      expect(TpBreakpoints.down(640, TpBreakpoint.sm), isFalse);
    });
  });

  group('only (@token band)', () {
    test('sm is [640, 768)', () {
      expect(TpBreakpoints.only(639, TpBreakpoint.sm), isFalse);
      expect(TpBreakpoints.only(640, TpBreakpoint.sm), isTrue);
      expect(TpBreakpoints.only(767, TpBreakpoint.sm), isTrue);
      expect(TpBreakpoints.only(768, TpBreakpoint.sm), isFalse);
    });

    test('xxl is width >= 1536', () {
      expect(TpBreakpoints.only(1535, TpBreakpoint.xxl), isFalse);
      expect(TpBreakpoints.only(1536, TpBreakpoint.xxl), isTrue);
    });
  });
}
