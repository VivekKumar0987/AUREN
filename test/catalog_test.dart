import 'package:auren/src/catalog/experience_catalog_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog contains exactly 160 validated experiences', () async {
    final catalog = await const ExperienceCatalogLoader().load();
    final errors = catalog.validate();

    expect(catalog.declaredCount, 160);
    expect(catalog.experiences, hasLength(160));
    expect(errors, isEmpty);
  });
}
