import 'package:flutter_test/flutter_test.dart';
import 'package:hasabati/main.dart';

void main() {
  testWidgets('shows Hasabati app title', (tester) async {
    await tester.pumpWidget(const HasabatiApp());
    expect(find.text('حساباتي'), findsWidgets);
  });
}
