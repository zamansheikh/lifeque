import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/home_widget/services/home_widget_service.dart';

void main() {
  test('parses the set the providers publish, keeping the tags verbatim', () {
    final sizes = parseWidgetSizes('465x350,615x350');
    expect(sizes.map((s) => s.tag), ['465x350', '615x350']);
    expect(sizes.first.size, const Size(465, 350));
  });

  test('two instances of the same size share one bitmap', () {
    expect(parseWidgetSizes('615x350,615x350').length, 1);
  });

  test('ignores junk without dropping the good entries', () {
    final sizes = parseWidgetSizes(' 465x350 ,,oops,12x9,615x350');
    expect(sizes.map((s) => s.tag), ['465x350', '615x350']);
  });

  test('nothing reported yet means an empty list, not a crash', () {
    expect(parseWidgetSizes(null), isEmpty);
    expect(parseWidgetSizes(''), isEmpty);
  });

  test('the tag for a Size matches what Kotlin would have written', () {
    // Kotlin writes the ints from the widget options; a parsed size must
    // round-trip to the identical string or no provider will find its bitmap.
    expect(widgetSizeTag(const Size(465, 350)), '465x350');
    expect(widgetSizeTag(parseWidgetSizes('465x350').single.size), '465x350');
  });
}
