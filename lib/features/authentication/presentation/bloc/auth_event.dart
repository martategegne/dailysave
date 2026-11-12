import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String defaultCurrency;
  final String language;

  const RegisterSubmitted({
    required this.email,
    required this.password,
    required this.fullName,
    this.defaultCurrency = 'ETB',
    this.language = 'en',
  });

  @override
  List<Object?> get props => [email, password, fullName, defaultCurrency, language];
}

class LogoutSubmitted extends AuthEvent {}
