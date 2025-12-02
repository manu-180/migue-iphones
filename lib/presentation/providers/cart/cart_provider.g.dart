// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartTotalItemsHash() => r'92c001024c5339fca0b263b2c0c66a18563bdc22';

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
String _$cartTotalPriceHash() => r'9577970f2e7bbf84e9c32ca074cf7f1e38afa127';

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
String _$cartNotifierHash() => r'268e6204d0b80da7a91ef6e8183a140af084f45b';

/// See also [CartNotifier].
@ProviderFor(CartNotifier)
final cartNotifierProvider =
    AsyncNotifierProvider<CartNotifier, List<CartItem>>.internal(
  CartNotifier.new,
  name: r'cartNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CartNotifier = AsyncNotifier<List<CartItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
