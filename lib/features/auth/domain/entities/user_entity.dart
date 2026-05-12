import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;

  const UserEntity({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, email, username, avatarUrl];
}
