import 'package:flutter_test/flutter_test.dart';

import 'package:pawly/main.dart';

void main() {
  test('PAWLY app constructor accepts signed-out state', () {
    const app = MyApp(isSignedIn: false);

    expect(app.isSignedIn, isFalse);
  });

  test('PAWLY app constructor accepts signed-in state', () {
    const app = MyApp(isSignedIn: true);

    expect(app.isSignedIn, isTrue);
  });
}
