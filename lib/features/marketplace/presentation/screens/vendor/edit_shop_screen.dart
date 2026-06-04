import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/platform/media_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/edit_shop_controller.dart';
import '../../controllers/my_shop_controller.dart';
import '../../../data/models/shop.dart';

class EditShopScreen extends ConsumerStatefulWidget {
  const EditShopScreen({super.key});

  @override
  ConsumerState<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends ConsumerState<EditShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Branding
  final _shopNameCtrl   = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  Uint8List? _newLogoBytes;
  Uint8List? _newBannerBytes;
  String? _existingLogoUrl;
  String? _existingBannerUrl;

  // Contact
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _streetCtrl  = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _stateCtrl   = TextEditingController();
  final _zipCtrl     = TextEditingController();

  // Policies
  final _returnCtrl   = TextEditingController();
  final _shippingCtrl = TextEditingController();

  // Social links
  final _websiteCtrl   = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl  = TextEditingController();
  final _tiktokCtrl    = TextEditingController();
  final _youtubeCtrl   = TextEditingController();

  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _shopNameCtrl, _descriptionCtrl,
      _emailCtrl, _phoneCtrl, _streetCtrl, _cityCtrl, _stateCtrl, _zipCtrl,
      _returnCtrl, _shippingCtrl,
      _websiteCtrl, _instagramCtrl, _facebookCtrl, _tiktokCtrl, _youtubeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _populate(Shop shop) {
    if (_initialised) return;
    _initialised = true;
    _shopNameCtrl.text    = shop.shopName;
    _descriptionCtrl.text = shop.description   ?? '';
    _existingLogoUrl      = shop.logoUrl;
    _existingBannerUrl    = shop.bannerUrl;
    _emailCtrl.text       = shop.businessEmail  ?? '';
    _phoneCtrl.text       = shop.businessPhone  ?? '';
    _streetCtrl.text      = shop.addressStreet  ?? '';
    _cityCtrl.text        = shop.addressCity    ?? '';
    _stateCtrl.text       = shop.addressState   ?? '';
    _zipCtrl.text         = shop.addressZip     ?? '';
    _returnCtrl.text      = shop.returnPolicy   ?? '';
    _shippingCtrl.text    = shop.shippingPolicy ?? '';
    final links = shop.socialLinks ?? {};
    _websiteCtrl.text   = (links['website']   as String?) ?? '';
    _instagramCtrl.text = (links['instagram'] as String?) ?? '';
    _facebookCtrl.text  = (links['facebook']  as String?) ?? '';
    _tiktokCtrl.text    = (links['tiktok']    as String?) ?? '';
    _youtubeCtrl.text   = (links['youtube']   as String?) ?? '';
  }

  Future<void> _pickImage({required bool isLogo}) async {
    final picked = await pickGalleryImage(imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      if (isLogo) {
        _newLogoBytes = bytes;
      } else {
        _newBannerBytes = bytes;
      }
    });
  }

  Future<void> _save(Shop current) async {
    String? v(String raw) => raw.trim().isEmpty ? null : raw.trim();

    final socialLinks = <String, String>{
      if (_websiteCtrl.text.trim().isNotEmpty)   'website':   _websiteCtrl.text.trim(),
      if (_instagramCtrl.text.trim().isNotEmpty) 'instagram': _instagramCtrl.text.trim(),
      if (_facebookCtrl.text.trim().isNotEmpty)  'facebook':  _facebookCtrl.text.trim(),
      if (_tiktokCtrl.text.trim().isNotEmpty)    'tiktok':    _tiktokCtrl.text.trim(),
      if (_youtubeCtrl.text.trim().isNotEmpty)   'youtube':   _youtubeCtrl.text.trim(),
    };

    final updated = current.copyWith(
      shopName:       _shopNameCtrl.text.trim(),
      description:    v(_descriptionCtrl.text),
      businessEmail:  v(_emailCtrl.text),
      businessPhone:  v(_phoneCtrl.text),
      addressStreet:  v(_streetCtrl.text),
      addressCity:    v(_cityCtrl.text),
      addressState:   v(_stateCtrl.text),
      addressZip:     v(_zipCtrl.text),
      returnPolicy:   v(_returnCtrl.text),
      shippingPolicy: v(_shippingCtrl.text),
      socialLinks:    socialLinks.isEmpty ? null : socialLinks,
    );

    await ref.read(editShopControllerProvider.notifier).saveShopDetails(
      updatedShop: updated,
      newLogo:     _newLogoBytes,
      newBanner:   _newBannerBytes,
    );

    if (!mounted) return;
    final saved = ref.read(editShopControllerProvider);
    if (saved.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved.error.toString()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _newLogoBytes   = null;
        _newBannerBytes = null;
        _existingLogoUrl   = saved.value?.logoUrl;
        _existingBannerUrl = saved.value?.bannerUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);
    final saveAsync = ref.watch(editShopControllerProvider);
    final isSaving  = saveAsync.isLoading;
    final pt        = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs        = Theme.of(context).colorScheme;
    final tt        = Theme.of(context).textTheme;

    return shopAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(e.toString())),
      ),
      data: (shop) {
        if (shop == null) {
          return const Scaffold(body: Center(child: Text('No shop found')));
        }
        _populate(shop);

        return Scaffold(
          backgroundColor: pt.surface1,
          appBar: AppBar(
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text('Edit Shop', style: tt.titleMedium),
            bottom: TabBar(
              controller: _tabController,
              labelStyle: tt.labelMedium!.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: tt.labelMedium,
              indicatorColor: AppColors.blue500,
              labelColor: AppColors.blue500,
              unselectedLabelColor: AppColors.ink500,
              tabs: const [
                Tab(text: 'Branding'),
                Tab(text: 'Contact Info'),
                Tab(text: 'Policies'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _BrandingTab(
                shopNameCtrl:    _shopNameCtrl,
                descriptionCtrl: _descriptionCtrl,
                logoBytes:       _newLogoBytes,
                bannerBytes:     _newBannerBytes,
                existingLogoUrl:   _existingLogoUrl,
                existingBannerUrl: _existingBannerUrl,
                onPickLogo:   () => _pickImage(isLogo: true),
                onPickBanner: () => _pickImage(isLogo: false),
              ),
              _ContactTab(
                emailCtrl:    _emailCtrl,
                phoneCtrl:    _phoneCtrl,
                streetCtrl:   _streetCtrl,
                cityCtrl:     _cityCtrl,
                stateCtrl:    _stateCtrl,
                zipCtrl:      _zipCtrl,
                websiteCtrl:   _websiteCtrl,
                instagramCtrl: _instagramCtrl,
                facebookCtrl:  _facebookCtrl,
                tiktokCtrl:    _tiktokCtrl,
                youtubeCtrl:   _youtubeCtrl,
              ),
              _PoliciesTab(
                returnCtrl:   _returnCtrl,
                shippingCtrl: _shippingCtrl,
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PrimaryPillButton(
              label:      'Save Changes',
              isLoading:  isSaving,
              isFullWidth: true,
              onPressed:  isSaving ? null : () => _save(shop),
            ),
          ),
        );
      },
    );
  }
}

// ── Branding Tab ───────────────────────────────────────────────────────────────

class _BrandingTab extends StatelessWidget {
  const _BrandingTab({
    required this.shopNameCtrl,
    required this.descriptionCtrl,
    required this.logoBytes,
    required this.bannerBytes,
    required this.existingLogoUrl,
    required this.existingBannerUrl,
    required this.onPickLogo,
    required this.onPickBanner,
  });

  final TextEditingController shopNameCtrl;
  final TextEditingController descriptionCtrl;
  final Uint8List? logoBytes;
  final Uint8List? bannerBytes;
  final String? existingLogoUrl;
  final String? existingBannerUrl;
  final VoidCallback onPickLogo;
  final VoidCallback onPickBanner;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Banner'),
          const SizedBox(height: 8),
          _BannerPicker(
            bytes:       bannerBytes,
            existingUrl: existingBannerUrl,
            onTap:       onPickBanner,
          ),
          const SizedBox(height: 20),
          _SectionLabel('Shop Logo'),
          const SizedBox(height: 8),
          _LogoPicker(
            bytes:       logoBytes,
            existingUrl: existingLogoUrl,
            onTap:       onPickLogo,
          ),
          const SizedBox(height: 24),
          _FormField(
            controller: shopNameCtrl,
            label: 'Shop Name',
            hint:  'e.g. Paws & Claws Store',
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: descriptionCtrl,
            label:    'Description',
            hint:     'Tell customers about your shop…',
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class _BannerPicker extends StatelessWidget {
  const _BannerPicker({
    required this.bytes,
    required this.existingUrl,
    required this.onTap,
  });

  final Uint8List? bytes;
  final String? existingUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    Widget child;
    if (bytes != null) {
      child = Image.memory(bytes!, fit: BoxFit.cover, width: double.infinity);
    } else if (existingUrl != null) {
      child = Image.network(existingUrl!, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (context2, error, stack) => _bannerPlaceholder(context2));
    } else {
      child = _bannerPlaceholder(context);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusLg),
          color: AppColors.line,
          boxShadow: pt.shadowE1,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Container(
              decoration: BoxDecoration(
                color: AppColors.ink950.withAlpha(60),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surface.withAlpha(220),
                  borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.blue500),
                    const SizedBox(width: 6),
                    Text(
                      'Change Banner',
                      style: Theme.of(context).textTheme.labelMedium!
                          .copyWith(color: AppColors.blue500, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerPlaceholder(BuildContext context) => Container(
    color: AppColors.blue500.withAlpha(15),
    child: const Icon(Icons.storefront_outlined, size: 40, color: AppColors.blue500),
  );
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.bytes,
    required this.existingUrl,
    required this.onTap,
  });

  final Uint8List? bytes;
  final String? existingUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    Widget image;
    if (bytes != null) {
      image = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (existingUrl != null) {
      image = Image.network(existingUrl!, fit: BoxFit.cover,
        errorBuilder: (context2, error, stack) => const Icon(
          Icons.storefront_outlined, size: 28, color: AppColors.blue500));
    } else {
      image = const Icon(Icons.storefront_outlined, size: 28, color: AppColors.blue500);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusLg),
          color: AppColors.blue500.withAlpha(15),
          border: Border.all(color: AppColors.line),
          boxShadow: pt.shadowE1,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: image),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.blue500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact Tab ────────────────────────────────────────────────────────────────

class _ContactTab extends StatelessWidget {
  const _ContactTab({
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.streetCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.zipCtrl,
    required this.websiteCtrl,
    required this.instagramCtrl,
    required this.facebookCtrl,
    required this.tiktokCtrl,
    required this.youtubeCtrl,
  });

  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController streetCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController zipCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController instagramCtrl;
  final TextEditingController facebookCtrl;
  final TextEditingController tiktokCtrl;
  final TextEditingController youtubeCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Business'),
          const SizedBox(height: 8),
          _FormField(
            controller: emailCtrl,
            label: 'Business Email',
            hint:  'shop@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: phoneCtrl,
            label: 'Business Phone',
            hint:  '+1 555 000 0000',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          _SectionLabel('Address'),
          const SizedBox(height: 8),
          _FormField(
            controller: streetCtrl,
            label: 'Street',
            hint:  '123 Main St',
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: cityCtrl,
            label: 'City',
            hint:  'New York',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  controller: stateCtrl,
                  label: 'State / Province',
                  hint:  'NY',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  controller: zipCtrl,
                  label: 'ZIP / Postal Code',
                  hint:  '10001',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('Social Links'),
          const SizedBox(height: 8),
          _FormField(
            controller: websiteCtrl,
            label: 'Website',
            hint:  'https://yourshop.com',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: instagramCtrl,
            label: 'Instagram',
            hint:  'https://instagram.com/yourshop',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: facebookCtrl,
            label: 'Facebook',
            hint:  'https://facebook.com/yourshop',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: tiktokCtrl,
            label: 'TikTok',
            hint:  'https://tiktok.com/@yourshop',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          _FormField(
            controller: youtubeCtrl,
            label: 'YouTube',
            hint:  'https://youtube.com/@yourshop',
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }
}

// ── Policies Tab ───────────────────────────────────────────────────────────────

class _PoliciesTab extends StatelessWidget {
  const _PoliciesTab({
    required this.returnCtrl,
    required this.shippingCtrl,
  });

  final TextEditingController returnCtrl;
  final TextEditingController shippingCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Return Policy'),
          const SizedBox(height: 8),
          _FormField(
            controller: returnCtrl,
            label:    'Return Policy',
            hint:     'Describe your return/refund policy…',
            maxLines: 6,
          ),
          const SizedBox(height: 24),
          _SectionLabel('Shipping Policy'),
          const SizedBox(height: 8),
          _FormField(
            controller: shippingCtrl,
            label:    'Shipping Policy',
            hint:     'Describe your shipping times and rates…',
            maxLines: 6,
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall!.copyWith(
        color: AppColors.ink500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium!.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller:   controller,
          maxLines:     maxLines,
          keyboardType: keyboardType,
          style:        tt.bodyMedium,
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: tt.bodyMedium!.copyWith(color: AppColors.ink300),
            filled:     true,
            fillColor:  cs.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical:   maxLines > 1 ? 12 : 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
              borderSide: BorderSide(color: AppColors.blue500, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
