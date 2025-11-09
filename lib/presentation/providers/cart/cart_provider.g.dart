// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartTotalItemsHash() => r'501e7642234d78f1d767a0777c3186050f9b087a';

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
String _$cartTotalPriceHash() => r'68f7642fdcf3b2052100e219520ce308840f82b4';

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
String _$cartNotifierHash() => r'f302675c252454a8ac6de67005fb999507cc5114';

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
