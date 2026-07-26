import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('renders the previewer app bar', (tester) async {
    await tester.pumpWidget(const PreviewExampleApp());

    expect(find.text('Onion Theme Previewer'), findsOneWidget);
  });
}
