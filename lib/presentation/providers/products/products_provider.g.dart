// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productsRepositoryHash() =>
    r'de34aabfcf50cc3376f475d01b1a0f2568c00a5f';

/// See also [productsRepository].
@ProviderFor(productsRepository)
final productsRepositoryProvider = Provider<ProductsRepositoryImpl>.internal(
  productsRepository,
  name: r'productsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductsRepositoryRef = ProviderRef<ProductsRepositoryImpl>;
String _$filteredProductsHash() => r'77f6a2f5254b028acab7d759e584cf2cb67653c6';

/// See also [filteredProducts].
@ProviderFor(filteredProducts)
final filteredProductsProvider =
    AutoDisposeProvider<AsyncValue<List<Product>>>.internal(
  filteredProducts,
  name: r'filteredProductsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredProductsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredProductsRef = AutoDisposeProviderRef<AsyncValue<List<Product>>>;
String _$productFilterNotifierHash() =>
    r'30657813ccdbfb9ed934d990694ee2edc8397246';

/// See also [ProductFilterNotifier].
@ProviderFor(ProductFilterNotifier)
final productFilterNotifierProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>.internal(
  ProductFilterNotifier.new,
  name: r'productFilterNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productFilterNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProductFilterNotifier = Notifier<ProductFilter>;
String _$productsNotifierHash() => r'4b0e869be0d00e1564f51b473265a0b44d3c76fa';

/// See also [ProductsNotifier].
@ProviderFor(ProductsNotifier)
final productsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ProductsNotifier, List<Product>>.internal(
  ProductsNotifier.new,
  name: r'productsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProductsNotifier = AutoDisposeAsyncNotifier<List<Product>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
