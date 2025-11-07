// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartTotalItemsHash() => r'6a1240a9ea5c9ba440619fb4b7878bd018c03f39';

/// See also [cartTotalItems].
@ProviderFor(cartTotalItems)
final cartTotalItemsProvider = AutoDisposeProvider<int>.internal(
  cartTotalItems,
  name: r'cartTotalItemsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartTotalItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartTotalItemsRef = AutoDisposeProviderRef<int>;
String _$cartTotalPriceHash() => r'3d1d605a58aad928cca2bc7c4f40059fa75cd1a1';

/// See also [cartTotalPrice].
@ProviderFor(cartTotalPrice)
final cartTotalPriceProvider = AutoDisposeProvider<double>.internal(
  cartTotalPrice,
  name: r'cartTotalPriceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartTotalPriceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartTotalPriceRef = AutoDisposeProviderRef<double>;
String _$cartNotifierHash() => r'0ab9cec144854e4bb26ddc17e445335e94acdde8';

/// See also [CartNotifier].
@ProviderFor(CartNotifier)
final cartNotifierProvider =
    NotifierProvider<CartNotifier, List<CartItem>>.internal(
  CartNotifier.new,
  name: r'cartNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CartNotifier = Notifier<List<CartItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
