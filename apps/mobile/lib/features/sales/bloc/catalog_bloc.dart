import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/entities/product_entity.dart';
import '../../../data/repositories/product_repository.dart';

// Events
abstract class CatalogEvent extends Equatable {
  const CatalogEvent();
  @override
  List<Object?> get props => [];
}

class LoadCatalog extends CatalogEvent {
  final String? categoryId;
  const LoadCatalog({this.categoryId});
  @override
  List<Object?> get props => [categoryId];
}

class SearchProducts extends CatalogEvent {
  final String query;
  const SearchProducts(this.query);
  @override
  List<Object?> get props => [query];
}

class AddToCart extends CatalogEvent {
  final ProductEntity product;
  final double quantity;
  const AddToCart(this.product, {this.quantity = 1});
  @override
  List<Object?> get props => [product, quantity];
}

class RemoveFromCart extends CatalogEvent {
  final String productId;
  const RemoveFromCart(this.productId);
  @override
  List<Object?> get props => [productId];
}

class UpdateCartQuantity extends CatalogEvent {
  final String productId;
  final double quantity;
  const UpdateCartQuantity(this.productId, this.quantity);
  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCart extends CatalogEvent {
  const ClearCart();
}

class RefreshCatalog extends CatalogEvent {
  const RefreshCatalog();
}

// State
class CatalogState extends Equatable {
  final List<ProductEntity> products;
  final List<ProductEntity> filteredProducts;
  final List<ProductCategory> categories;
  final String? selectedCategoryId;
  final Map<String, CartItem> cart;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final String? searchQuery;

  const CatalogState({
    this.products = const [],
    this.filteredProducts = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.cart = const {},
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.searchQuery,
  });

  CatalogState copyWith({
    List<ProductEntity>? products,
    List<ProductEntity>? filteredProducts,
    List<ProductCategory>? categories,
    String? selectedCategoryId,
    Map<String, CartItem>? cart,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    String? searchQuery,
  }) {
    return CatalogState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        products,
        filteredProducts,
        categories,
        selectedCategoryId,
        cart,
        isLoading,
        isRefreshing,
        error,
        searchQuery,
      ];

  // Helpers
  int get cartItemCount => cart.values.fold(0, (sum, i) => sum + i.quantity.toInt());
  
  double get cartTotal => cart.values.fold(0, (sum, i) => sum + i.total);

  List<ProductEntity> get productsInCart {
    return products.where((p) => cart.containsKey(p.serverId ?? p.id.toString())).toList();
  }

  bool isInCart(String productId) => cart.containsKey(productId);

  double getCartQuantity(String productId) => cart[productId]?.quantity ?? 0;
}

// BLoC
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final ProductRepository _productRepository = ProductRepository();

  CatalogBloc() : super(const CatalogState()) {
    on<LoadCatalog>(_onLoadCatalog);
    on<SearchProducts>(_onSearchProducts);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartQuantity>(_onUpdateCartQuantity);
    on<ClearCart>(_onClearCart);
    on<RefreshCatalog>(_onRefreshCatalog);
  }

  Future<void> _onLoadCatalog(LoadCatalog event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Load from local DB (works offline!)
      final products = await _productRepository.getProducts(
        categoryId: event.categoryId,
      );

      final categories = await _productRepository.getCategories();

      emit(state.copyWith(
        products: products,
        filteredProducts: products,
        categories: categories,
        selectedCategoryId: event.categoryId,
        isLoading: false,
      ));

      // Background sync
      _productRepository.syncProducts();
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить каталог: $e',
      ));
    }
  }

  void _onSearchProducts(SearchProducts event, Emitter<CatalogState> emit) {
    if (event.query.isEmpty) {
      emit(state.copyWith(
        filteredProducts: state.products,
        searchQuery: null,
      ));
      return;
    }

    final query = event.query.toLowerCase();
    final filtered = state.products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          (p.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    emit(state.copyWith(
      filteredProducts: filtered,
      searchQuery: event.query,
    ));
  }

  void _onAddToCart(AddToCart event, Emitter<CatalogState> emit) {
    final productId = event.product.serverId ?? event.product.id.toString();
    final currentCart = Map<String, CartItem>.from(state.cart);

    final existingItem = currentCart[productId];
    if (existingItem != null) {
      // Update quantity
      currentCart[productId] = CartItem(
        productId: productId,
        productName: event.product.name,
        price: event.product.currentPrice,
        quantity: existingItem.quantity + event.quantity,
        unit: event.product.unit,
        imageUrl: event.product.mainImage,
      );
    } else {
      // Add new item
      currentCart[productId] = CartItem(
        productId: productId,
        productName: event.product.name,
        price: event.product.currentPrice,
        quantity: event.quantity,
        unit: event.product.unit,
        imageUrl: event.product.mainImage,
      );
    }

    emit(state.copyWith(cart: currentCart));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CatalogState> emit) {
    final currentCart = Map<String, CartItem>.from(state.cart);
    currentCart.remove(event.productId);
    emit(state.copyWith(cart: currentCart));
  }

  void _onUpdateCartQuantity(UpdateCartQuantity event, Emitter<CatalogState> emit) {
    final currentCart = Map<String, CartItem>.from(state.cart);
    final item = currentCart[event.productId];
    
    if (item != null) {
      if (event.quantity <= 0) {
        currentCart.remove(event.productId);
      } else {
        currentCart[event.productId] = CartItem(
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          quantity: event.quantity,
          unit: item.unit,
          imageUrl: item.imageUrl,
        );
      }
    }

    emit(state.copyWith(cart: currentCart));
  }

  void _onClearCart(ClearCart event, Emitter<CatalogState> emit) {
    emit(state.copyWith(cart: {}));
  }

  Future<void> _onRefreshCatalog(RefreshCatalog event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      await _productRepository.syncProducts();
      
      // Reload
      final products = await _productRepository.getProducts(
        categoryId: state.selectedCategoryId,
      );

      emit(state.copyWith(
        products: products,
        filteredProducts: state.searchQuery == null 
            ? products 
            : _filterProducts(products, state.searchQuery!),
        isRefreshing: false,
      ));
    } catch (e) {
      emit(state.copyWith(isRefreshing: false));
    }
  }

  List<ProductEntity> _filterProducts(List<ProductEntity> products, String query) {
    final lowerQuery = query.toLowerCase();
    return products.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          p.sku.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
