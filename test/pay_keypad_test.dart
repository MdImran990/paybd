import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paybd/core/widgets/pay_keypad.dart';

Widget _app(Widget child) =>
    ProviderScope(child: MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('the keypad sends the pressed keys', (tester) async {
    final keys = <String>[];
    await tester.pumpWidget(_app(PayKeypad(onKey: keys.add)));

    await tester.tap(find.text('5'));
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));

    expect(keys, ['5', 'back', 'next']);
  });

  testWidgets('the decimal keypad has a dot key', (tester) async {
    final keys = <String>[];
    await tester.pumpWidget(
      _app(PayKeypad(kind: KeypadKind.decimal, onKey: keys.add)),
    );

    await tester.tap(find.text('.'));
    await tester.tap(find.text('0'));

    expect(keys, ['.', '0']);
  });

  testWidgets('the PIN keypad has no arrow key', (tester) async {
    await tester.pumpWidget(
      _app(PayKeypad(kind: KeypadKind.pin, onKey: (_) {})),
    );
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
  });
}
