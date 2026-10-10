import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modules/profile/profile_photo.dart';

/// The user's profile photo in a circle (or a person icon when there is none).
/// Give two avatars the same [heroTag] to animate between screens.
class UserAvatar extends ConsumerWidget {
  final double radius;
  final String? heroTag;

  const UserAvatar({super.key, required this.radius, this.heroTag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(profilePhotoProvider);
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      backgroundImage: path != null ? FileImage(File(path)) : null,
      child: path == null
          ? Icon(Icons.person_rounded, color: Colors.white, size: radius * 1.1)
          : null,
    );
    final tag = heroTag;
    return tag == null ? avatar : Hero(tag: tag, child: avatar);
  }
}
