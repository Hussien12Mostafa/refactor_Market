part of 'orders_bloc.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  const OrdersLoaded(this.orders);
  @override
  List<Object> get props => [orders];
}

class OrdersLoading extends OrdersState {}

class OrdersLoadingFailed extends OrdersState {}
