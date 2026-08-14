import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosmart_app/core/widgets/ai/markdown_text.dart';

/// The bug this guards: the chat bubble printed `**7,000 km**` verbatim.
/// Every case below is a shape RideMate actually produces.
void main() {
  const style = TextStyle(fontSize: 15);

  Future<String> render(WidgetTester tester, String source) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 400, child: MarkdownText(source, style: style)),
        ),
      ),
    );
    final buffer = StringBuffer();
    for (final w in tester.widgetList<SelectableText>(find.byType(SelectableText))) {
      buffer.write(w.textSpan?.toPlainText() ?? w.data ?? '');
      buffer.write('\n');
    }
    return buffer.toString();
  }

  testWidgets('strips bold and italic markers', (tester) async {
    final out = await render(tester, 'Service is due at **7,000 km** or *6 months*.');
    expect(out, contains('Service is due at 7,000 km or 6 months.'));
    expect(out, isNot(contains('*')));
  });

  testWidgets('bold renders at w700', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MarkdownText('Due at **7,000 km** now.', style: style)),
      ),
    );
    final span = tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!;
    final weights = <FontWeight?>[];
    span.visitChildren((s) {
      if (s is TextSpan && s.text != null) weights.add(s.style?.fontWeight);
      return true;
    });
    expect(weights, contains(FontWeight.w700));
  });

  testWidgets('bullets become markers, not asterisks', (tester) async {
    final out = await render(tester, 'Check:\n- Tyre pressure\n- Chain slack');
    expect(out, contains('Tyre pressure'));
    expect(out, contains('Chain slack'));
    expect(out, isNot(contains('- Tyre')));
    expect(find.text('•'), findsNWidgets(2));
  });

  testWidgets('numbered lists keep their numbers', (tester) async {
    await render(tester, '1. Stop riding\n2. Call the dealer');
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
  });

  testWidgets('wrapped lines join into one paragraph', (tester) async {
    final out = await render(tester, 'The engine oil\nshould be changed\nevery 3,000 km.');
    expect(out, contains('The engine oil should be changed every 3,000 km.'));
  });

  testWidgets('inline code survives with its content', (tester) async {
    final out = await render(tester, 'The code `P0301` means a misfire.');
    expect(out, contains('P0301'));
    expect(out, isNot(contains('`')));
  });

  testWidgets('a bare asterisk is not treated as emphasis', (tester) async {
    final out = await render(tester, 'Rated 4 * out of 5 by owners.');
    expect(out, contains('4 * out of 5'));
  });

  testWidgets('plain prose passes through untouched', (tester) async {
    final out = await render(tester, 'Your next service is due next month.');
    expect(out, contains('Your next service is due next month.'));
  });

  testWidgets('empty content renders nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MarkdownText('', style: style))),
    );
    expect(find.byType(SelectableText), findsNothing);
  });
}
