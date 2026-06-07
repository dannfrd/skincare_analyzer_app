import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_analyzer_app/services/ingredient_text_filter.dart';

void main() {
  test('keeps text between ingredient header and packaging metadata', () {
    final result = IngredientTextFilter.selectFromPlainText('''
Brightening Serum
INGREDIENTS: Aqua, Glycerin,
Niacinamide, Panthenol, Allantoin
BPOM NA18240123456
Netto 20 ml
''');

    expect(result, 'Aqua, Glycerin,\nNiacinamide, Panthenol, Allantoin');
    expect(result, isNot(contains('Brightening')));
    expect(result, isNot(contains('BPOM')));
  });

  test('uses ingredient-like lines when header is not recognized', () {
    final result = IngredientTextFilter.selectFromPlainText('''
ACNE CARE SERUM
Aqua, Glycerin, Niacinamide
Panthenol, Sodium Hyaluronate
Customer Service 0800 123
''');

    expect(result, contains('Aqua, Glycerin, Niacinamide'));
    expect(result, contains('Panthenol, Sodium Hyaluronate'));
    expect(result, isNot(contains('Customer Service')));
  });
}
