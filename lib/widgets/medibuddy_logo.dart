import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

// logo widget used on the auth screens
class MediBuddyLogo extends StatelessWidget {
  final String? tagline;

  const MediBuddyLogo({this.tagline});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // pill icon in a soft circle
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFF5DDD8),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: ClipOval(
                child: Image.asset('images/pill.png', fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // two-tone "MediBuddy" text
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'Medi', style: AppTextStyles.logoMedi),
              TextSpan(text: 'Buddy', style: AppTextStyles.logoBuddy),
            ],
          ),
        ),
        if (tagline != null) ...[
          const SizedBox(height: 6),
          Text(tagline!, style: AppTextStyles.subtitle),
        ],
      ],
    );
  }
}
