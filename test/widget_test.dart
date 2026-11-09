import 'package:flutter_test/flutter_test.dart';
import 'package:girlcare72/src/answer_bank.dart';

void main() {
  test('danger words always route to Get help', () {
    expect(bankAnswer('he raped me').help, isTrue);
    expect(bankAnswer('I was forced').help, isTrue);
  });

  test('answer bank finds reviewed answers offline', () {
    expect(bankAnswer('what is PEP').lesson, 2);
    expect(bankAnswer('my period hurts').lesson, 4);
    expect(bankAnswer('something unrelated xyz').source, 'none');
  });
}
