import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import '../../db/schemas/stock.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';

// Events
abstract class VanSaleEvent extends Equatable {
  const VanSaleEvent();

  @override
  List<Object?> get props => [];
}

class VanSaleLoadStock extends VanSaleEvent {}

class VanSaleSearchChanged extends VanSaleEvent {
  final String query;
  const VanSaleSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class VanSaleAddToCart extends VanSaleEvent {
  final String productId;
  final String productName;
  final double quantity;
  final double price;

  const VanSaleAddToCart({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  @override
  List<Object?> get props => [productId, productName, quantity, price];
}

class VanSaleRemoveFromCart extends VanSaleEvent {
  final String productId;
  const VanSaleRemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class VanSaleUpdateQuantity extends VanSaleEvent {
  final String productId;
  final double quantity;
  const VanSaleUpdateQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class VanSaleClientSelected extends VanSaleEvent {
  final String clientId;
  final String clientName;
  const VanSaleClientSelected(this.clientId, this.clientName);

  @override
  List<Object?> get props => [clientId, clientName];
}

class VanSaleSubmit extends VanSaleEvent {
  final String paymentMethod;
  const VanSaleSubmit(this.paymentMethod);

  @override
  List<Object?> get props => [paymentMethod];
}

class VanSaleClearCart extends VanSaleEvent {}

// Cart Item
class CartItem extends Equatable {
  final String productId;
  final String productName;
  final double quantity;
  final double price;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  CartItem copyWith({
    String? productId,
    String? productName,
    double? quantity,
    double? price,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  @override
  List<Object?> get props => [productId, productName, quantity, price];
}

// States
abstract class VanSaleState extends Equatable {
  const VanSaleState();

  @override
  List<Object?> get props => [];
}

class VanSaleInitial extends VanSaleState {}

class VanSaleLoading extends VanSaleState {}

class VanSaleLoaded extends VanSaleState {
  final List<Stock> stock;
  final List<Stock> filteredStock;
  final Map<String, CartItem> cart;
  final String? selectedClientId;
  final String? selectedClientName;
  final String searchQuery;

  const VanSaleLoaded({
    required this.stock,
    required this.filteredStock,
    required this.cart,
    this.selectedClientId,
    this.selectedClientName,
    this.searchQuery = '',
  });

  double get cartTotal => cart.values.fold(0, (sum, item) => sum + item.total);
  int get cartItemCount => cart.values.fold(0, (sum, item) => sum + item.quantity.toInt());

  VanSaleLoaded copyWith({
    List<Stock>? stock,
    List<Stock>? filteredStock,
    Map<String, CartItem>? cart,
    String? selectedClientId,
    String? selectedClientName,
    String? searchQuery,
  }) {
    return VanSaleLoaded(
      stock: stock ?? this.stock,
      filteredStock: filteredStock ?? this.filteredStock,
      cart: cart ?? this.cart,
      selectedClientId: selectedClientId ?? this.selectedClientId,
      selectedClientName: selectedClientName ?? this.selectedClientName,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        stock,
        filteredStock,
        cart,
        selectedClientId,
        selectedClientName,
        searchQuery,
      ];
}

class VanSaleSubmitting extends VanSaleState {
  final Map<String, CartItem> cart;
  final String paymentMethod;

  const VanSaleSubmitting(this.cart, this.paymentMethod);

  @override
  List<Object?> get props => [cart, paymentMethod];
}

class VanSaleSuccess extends VanSaleState {
  final String orderId;
  const VanSaleSuccess(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class VanSaleError extends VanSaleState {
  final String message;
  const VanSaleError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class VanSaleBloc extends Bloc<VanSaleEvent, VanSaleState> {
  final DatabaseService _db;
  final SyncService _sync;

  VanSaleBloc(this._db, this._sync) : super(VanSaleInitial()) {
    on<VanSaleLoadStock>(_onLoadStock);
    on<VanSaleSearchChanged>(_onSearchChanged);
    on<VanSaleAddToCart>(_onAddToCart);
    on<VanSaleRemoveFromCart>(_onRemoveFromCart);
    on<VanSaleUpdateQuantity>(_onUpdateQuantity);
    on<VanSaleClientSelected>(_onClientSelected);
    on<VanSaleSubmit>(_onSubmit);
    on<VanSaleClearCart>(_onClearCart);
  }

  Future<void> _onLoadStock(
    VanSaleLoadStock event,
    Emitter<VanSaleState> emit,
  ) async {
    emit(VanSaleLoading());
    try {
      // Workaround: get all stocks via list
      final stocks = await _db.isar.stocks.where().findAll();
      emit(VanSaleLoaded(
        stock: stocks,
        filteredStock: stocks,
        cart: const {},
      ));
    } catch (e) {
      emit(VanSaleError('Failed to load stock: $e'));
    }
  }

  void _onSearchChanged(
    VanSaleSearchChanged event,
    Emitter<VanSaleState> emit,
  ) {
    if (state is! VanSaleLoaded) return;
    final current = state as VanSaleLoaded;
    
    final filtered = event.query.isEmpty
        ? current.stock
        : current.stock.where((s) =>
            s.productName.toLowerCase().contains(event.query.toLowerCase())).toList();

    emit(current.copyWith(
      filteredStock: filtered,
      searchQuery: event.query,
    ));
  }

  void _onAddToCart(
    VanSaleAddToCart event,
    Emitter<VanSaleState> emit,
  ) {
    if (state is! VanSaleLoaded) return;
    final current = state as VanSaleLoaded;

    final newCart = Map<String, CartItem>.from(current.cart);
    final existing = newCart[event.productId];
    
    if (existing != null) {
      newCart[event.productId] = existing.copyWith(
        quantity: existing.quantity + event.quantity,
      );
    } else {
      newCart[event.productId] = CartItem(
        productId: event.productId,
        productName: event.productName,
        quantity: event.quantity,
        price: event.price,
      );
    }

    emit(current.copyWith(cart: newCart));
  }

  void _onRemoveFromCart(
    VanSaleRemoveFromCart event,
    Emitter<VanSaleState> emit,
  ) {
    if (state is! VanSaleLoaded) return;
    final current = state as VanSaleLoaded;

    final newCart = Map<String, CartItem>.from(current.cart);
    newCart.remove(event.productId);

    emit(current.copyWith(cart: newCart));
  }

  void _onUpdateQuantity(
    VanSaleUpdateQuantity event,
    Emitter<VanSaleState> emit,
  ) {
    if (state is! VanSaleLoaded) return;
    final current = state as VanSaleLoaded;

    if (event.quantity <= 0) {
      add(VanSaleRemoveFromCart(event.productId));
      return;
    }

    final newCart = Map<String, CartItem>.from(current.cart);
    final existing = newCart[event.productId];
    
    if (existing != null) {
      newCart[event.productId] = existing.copyWith(quantity: event.quantity);
    }

    emit(current.copyWith(cart: newCart));
  }

  void _onClientSelected(
    VanSaleClientSelected event,
    Emitter<VanSaleState> emit,
  ) {
    if (state is! VanSaleLoaded) return;
    final current = state as VanSaleLoaded;

    emit(current.copyWith(
      selectedClientId: event.clientId,
      selectedClientName: event.clientName,
    ));
  }

  Future<void> _onSubmit(
    VanSaleSubmit event,
    Emitter<VanSaleState> emit,
  ) async {
    if (state is! VanSaleLoaded) return;
    final current = state as VanSaleLoaded;

    if (current.cart.isEmpty) {
      emit(const VanSaleError('Cart is empty'));
      emit(current);
      return;
    }

    if (current.selectedClientId == null) {
      emit(const VanSaleError('Please select a client'));
      emit(current);
      return;
    }

    emit(VanSaleSubmitting(current.cart, event.paymentMethod));

    try {
      // Prepare items for sync
      final items = current.cart.values.map<Map<String, dynamic>>((item) => {
        'productId': item.productId,
        'quantity': item.quantity,
        'price': item.price,
      }).toList();

      // Queue van sale for sync
      await _sync.queueVanSale(
        current.selectedClientId!,
        items,
        paymentMethod: event.paymentMethod,
      );

      emit(const VanSaleSuccess('pending'));
    } catch (e) {
      emit(VanSaleError('Failed to create order: $e'));
      emit(current);
    }
  }

  void _onClearCart(
    VanSaleClearCart event,
    Emitter<VanSaleState> emit,
  ) {
    if (state is! VanSaleLoaded) return;
    final current = state as VanSaleLoaded;

    emit(current.copyWith(
      cart: const {},
      selectedClientId: null,
      selectedClientName: null,
    ));
  }
}
