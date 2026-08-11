import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CoachProfileOverview extends StatelessWidget {
  const CoachProfileOverview({
    super.key,
    required this.profile,
    required this.email,
    required this.connectedClients,
    required this.pendingClients,
  });

  final Map<String, dynamic> profile;
  final String email;
  final int connectedClients;
  final int pendingClients;

  String _value(String key) => (profile[key] ?? '').toString().trim();

  List<String> _strings(String key) {
    final value = profile[key];
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _maps(String key) {
    final value = profile[key];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _date(String value) {
    if (value.isEmpty) return 'Chưa cập nhật';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _gender(String value) => switch (value.toLowerCase()) {
    'male' => 'Nam',
    'female' => 'Nữ',
    'other' => 'Khác',
    _ => 'Chưa cập nhật',
  };

  @override
  Widget build(BuildContext context) {
    final name = _value('fullName').isEmpty ? 'PT / Coach' : _value('fullName');
    final avatarUrl = _value('avatarUrl');
    final headline = _value('headline');
    final specialty = _value('specialty');
    final city = _value('city');
    final phone = _value('phoneNumber');
    final bio = _value('bio');
    final achievements = _value('achievements');
    final status = _value('applicationStatus');
    final experience = _value('experienceYears');
    final languages = _strings('languages');
    final styles = _strings('coachingStyles');
    final levels = _strings('clientLevels');
    final certificates = _maps('certificates');
    final gallery = _strings('galleryUrls');
    final specialties = specialty
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final approved = status.toLowerCase() == 'approved';

    return Column(
      children: [
        _ProfileHero(
          name: name,
          avatarUrl: avatarUrl,
          headline: headline.isEmpty ? specialty : headline,
          city: city,
          experience: experience,
          languages: languages,
          approved: approved,
        ),
        const SizedBox(height: 14),
        _ProfileSection(
          icon: Icons.insights_outlined,
          title: 'Hoạt động của bạn',
          child: Row(
            children: [
              _ActivityMetric(
                value: '$connectedClients',
                label: 'Học viên',
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              _ActivityMetric(
                value: '$pendingClients',
                label: 'Chờ duyệt',
                color: const Color(0xFFD97706),
              ),
              const SizedBox(width: 10),
              _ActivityMetric(
                value: approved ? 'Đã duyệt' : _statusLabel(status),
                label: 'Hồ sơ',
                color: approved ? AppColors.primary : const Color(0xFFD97706),
                compact: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ProfileSection(
          icon: Icons.lock_outline_rounded,
          title: 'Thông tin riêng tư',
          description: 'Chỉ bạn và Admin có thể xem các thông tin này.',
          child: Column(
            children: [
              _PrivateInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email.isEmpty ? 'Chưa cập nhật' : email,
              ),
              _PrivateInfoRow(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: phone.isEmpty ? 'Chưa cập nhật' : phone,
              ),
              _PrivateInfoRow(
                icon: Icons.cake_outlined,
                label: 'Ngày sinh',
                value: _date(_value('dateOfBirth')),
              ),
              _PrivateInfoRow(
                icon: Icons.wc_outlined,
                label: 'Giới tính',
                value: _gender(_value('gender')),
                showDivider: false,
              ),
            ],
          ),
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProfileSection(
            icon: Icons.person_outline_rounded,
            title: 'Giới thiệu',
            child: Text(
              bio,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
        if (specialties.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProfileSection(
            icon: Icons.fitness_center_rounded,
            title: 'Chuyên môn',
            child: _TagWrap(values: specialties, color: AppColors.primary),
          ),
        ],
        if (styles.isNotEmpty || levels.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProfileSection(
            icon: Icons.tune_rounded,
            title: 'Phương pháp huấn luyện',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (styles.isNotEmpty) ...[
                  const _FieldLabel('Phong cách'),
                  const SizedBox(height: 8),
                  _TagWrap(values: styles, color: const Color(0xFF2563EB)),
                ],
                if (styles.isNotEmpty && levels.isNotEmpty)
                  const SizedBox(height: 16),
                if (levels.isNotEmpty) ...[
                  const _FieldLabel('Học viên phù hợp'),
                  const SizedBox(height: 8),
                  _TagWrap(values: levels, color: const Color(0xFF7C3AED)),
                ],
              ],
            ),
          ),
        ],
        if (certificates.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProfileSection(
            icon: Icons.verified_user_outlined,
            title: 'Chứng chỉ chuyên môn',
            trailing: '${certificates.length} chứng chỉ',
            child: Column(
              children: [
                for (var index = 0; index < certificates.length; index++) ...[
                  _CertificateCard(certificate: certificates[index]),
                  if (index < certificates.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
        if (achievements.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProfileSection(
            icon: Icons.emoji_events_outlined,
            title: 'Thành tích nổi bật',
            child: Text(
              achievements,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
        if (gallery.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ProfileSection(
            icon: Icons.photo_library_outlined,
            title: 'Hình ảnh hoạt động',
            trailing: '${gallery.length} ảnh',
            child: SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: gallery.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 190,
                    child: Image.network(
                      gallery[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ImageFallback(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _statusLabel(String status) => switch (status.toLowerCase()) {
    'pendingreview' => 'Chờ duyệt',
    'needsrevision' => 'Cần sửa',
    'rejected' => 'Từ chối',
    'suspended' => 'Tạm khóa',
    _ => 'Bản nháp',
  };
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.avatarUrl,
    required this.headline,
    required this.city,
    required this.experience,
    required this.languages,
    required this.approved,
  });

  final String name, avatarUrl, headline, city, experience;
  final List<String> languages;
  final bool approved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _Avatar(imageUrl: avatarUrl),
                  if (approved)
                    Positioned(
                      right: -5,
                      bottom: -5,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (headline.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (city.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              city,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroMetric(
                icon: Icons.workspace_premium_outlined,
                value: '${experience.isEmpty ? '0' : experience} năm',
                label: 'Kinh nghiệm',
              ),
              const SizedBox(width: 10),
              _HeroMetric(
                icon: Icons.translate_rounded,
                value: languages.isEmpty
                    ? 'Đang cập nhật'
                    : '${languages.length} ngôn ngữ',
                label: languages.isEmpty ? 'Thông tin' : languages.join(', '),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 82,
        height: 82,
        child: imageUrl.isEmpty
            ? const _ImageFallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImageFallback(),
              ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF63A985)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_gymnastics_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.25,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.child,
    this.description,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? description, trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.value,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String value, label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11.5 : 19,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateInfoRow extends StatelessWidget {
  const _PrivateInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label, value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.values, required this.color});

  final List<String> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.certificate});

  final Map<String, dynamic> certificate;

  String _value(String key) => (certificate[key] ?? '').toString().trim();

  String _date(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }

  @override
  Widget build(BuildContext context) {
    final name = _value('name');
    final issuer = _value('issuer');
    final issued = _value('issuedDate');
    final expiry = _value('expiryDate');
    final imageUrl = _value('imageUrl');
    final dates = [
      if (issued.isNotEmpty) 'Cấp ${_date(issued)}',
      if (expiry.isNotEmpty) 'Hết hạn ${_date(expiry)}',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: imageUrl.isEmpty
                  ? _certificateFallback()
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _certificateFallback(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Chứng chỉ chuyên môn' : name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (issuer.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    issuer,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
                if (dates.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    dates.join(' • '),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _certificateFallback() => Container(
    color: AppColors.primary.withValues(alpha: 0.09),
    child: const Icon(Icons.card_membership_rounded, color: AppColors.primary),
  );
}
