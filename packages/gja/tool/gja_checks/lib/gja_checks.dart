/// Verificações de conformidade do framework GJA: arquitetura, tokens,
/// specs e catálogo.
library;

export 'src/architecture_check.dart' show checkImports, checkPublicApi;
export 'src/catalog_check.dart' show CatalogItem, catalogFile, checkCatalog, loadCatalog;
export 'src/graph.dart' show findCycles;
export 'src/repo.dart' show Repo, frameworkLayers;
export 'src/specs_check.dart'
    show SpecFile, SpecRequirement, checkSpecs, loadChangeSpecs, loadMainSpecs, requiredWidgetTags;
export 'src/tokens_check.dart' show TokenException, checkTokens, tokenExceptionsFile, tokenPatterns;
export 'src/violation.dart' show Violation;
