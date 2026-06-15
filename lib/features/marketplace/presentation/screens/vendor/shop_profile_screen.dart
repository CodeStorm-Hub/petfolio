import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/platform/media_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../../../../core/widgets/tail_wag_loader.dart';
import '../../controllers/edit_shop_controller.dart';
import '../../controllers/my_shop_controller.dart';
import '../../../data/models/shop.dart';

class ShopProfileScreen extends ConsumerStatefulWidget {
  const ShopProfileScreen({super.key, this.isNew = false});

  final bool isNew;

  @override
  ConsumerState<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends ConsumerState<ShopProfileScreen>
    with SingleTickerProviderStateMixin {
  late bool _isNew;
  late final TabController _editTabController;

  // ── Setup form state ──────────────────────────────────────────────────────
  final _setupFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _setupDescCtrl = TextEditingController();
  bool _setupSaving = false;
  PayoutMethod _selectedPayout = PayoutMethod.stripe;
  bool _setupHydrated = false;

  // ── Edit form state ───────────────────────────────────────────────────────
  final _shopNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  Uint8List? _newLogoBytes;
  Uint8List? _newBannerBytes;
  String? _existingLogoUrl;
  String? _existingBannerUrl;
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _returnCtrl = TextEditingController();
  final _shippingCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  bool _editInitialised = false;

  @override
  void initState() {
    super.initState();
    _isNew = widget.isNew;
    _editTabController = TabController(length: 3, vsync: this);

    if (!_isNew) {
      final shop = ref.read(myShopProvider).value;
      if (shop != null) _hydrateSetup(shop);
    }
  }

  @override
  void dispose() {
    _editTabController.dispose();
    for (final c in [
      _nameCtrl, _slugCtrl, _setupDescCtrl,
      _shopNameCtrl, _descriptionCtrl,
      _emailCtrl, _phoneCtrl, _streetCtrl, _cityCtrl, _stateCtrl, _zipCtrl,
      _returnCtrl, _shippingCtrl,
      _websiteCtrl, _instagramCtrl, _facebookCtrl, _tiktokCtrl, _youtubeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrateSetup(Shop shop) {
    if (_setupHydrated) return;
    _setupHydrated = true;
    _nameCtrl.text = shop.shopName;
    _setupDescCtrl.text = shop.description ?? '';
    _selectedPayout = shop.payoutMethod;
  }

  void _populateEdit(Shop shop) {
    if (_editInitialised) return;
    _editInitialised = true;
    _shopNameCtrl.text = shop.shopName;
    _descriptionCtrl.text = shop.description ?? '';
    _existingLogoUrl = shop.logoUrl;
    _existingBannerUrl = shop.bannerUrl;
    _emailCtrl.text = shop.businessEmail ?? '';
    _phoneCtrl.text = shop.businessPhone ?? '';
    _streetCtrl.text = shop.addressStreet ?? '';
    _cityCtrl.text = shop.addressCity ?? '';
    _stateCtrl.text = shop.addressState ?? '';
    _zipCtrl.text = shop.addressZip ?? '';
    _returnCtrl.text = shop.returnPolicy ?? '';
    _shippingCtrl.text = shop.shippingPolicy ?? '';
    final links = shop.socialLinks ?? {};
    _websiteCtrl.text = (links['website'] as String?) ?? '';
    _instagramCtrl.text = (links['instagram'] as String?) ?? '';
    _facebookCtrl.text = (links['facebook'] as String?) ?? '';
    _tiktokCtrl.text = (links['tiktok'] as String?) ?? '';
    _youtubeCtrl.text = (links['youtube'] as String?) ?? '';
  }

  // ── Setup save ────────────────────────────────────────────────────────────

  Future<void> _setupSave() async {
    if (!_setupFormKey.currentState!.validate()) return;
    setState(() => _setupSaving = true);

    final isEdit = !widget.isNew;
    bool ok;
    if (isEdit) {
      ok = await ref.read(myShopProvider.notifier).updateShop(
            shopName: _nameCtrl.text.trim(),
            description: _setupDescCtrl.text.trim(),
          );
    } else {
      final slug = _slugCtrl.text.trim().toLowerCase().replaceAll(' ', '-');
      ok = await ref.read(myShopProvider.notifier).createShop(
            name: _nameCtrl.text.trim(),
            slug: slug,
            description: _setupDescCtrl.text.trim(),
            payoutMethod: _selectedPayout,
          );
    }

    if (!mounted) return;
    setState(() => _setupSaving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save shop. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!isEdit && _selectedPayout == PayoutMethod.manual) {
      context.pushReplacement('/seller/kyc');
    } else if (widget.isNew) {
      // Created — switch to full edit mode in-place
      setState(() => _isNew = false);
    } else {
      context.pop();
    }
  }

  // ── Edit save ─────────────────────────────────────────────────────────────

  Future<void> _editSave(Shop current) async {
    String? v(String raw) => raw.trim().isEmpty ? null : raw.trim();
    final socialLinks = <String, String>{
      if (_websiteCtrl.text.trim().isNotEmpty) 'website': _websiteCtrl.text.trim(),
      if (_instagramCtrl.text.trim().isNotEmpty) 'instagram': _instagramCtrl.text.trim(),
      if (_facebookCtrl.text.trim().isNotEmpty) 'facebook': _facebookCtrl.text.trim(),
      if (_tiktokCtrl.text.trim().isNotEmpty) 'tiktok': _tiktokCtrl.text.trim(),
      if (_youtubeCtrl.text.trim().isNotEmpty) 'youtube': _youtubeCtrl.text.trim(),
    };
    final updated = current.copyWith(
      shopName: _shopNameCtrl.text.trim(),
      description: v(_descriptionCtrl.text),
      businessEmail: v(_emailCtrl.text),
      businessPhone: v(_phoneCtrl.text),
      addressStreet: v(_streetCtrl.text),
      addressCity: v(_cityCtrl.text),
      addressState: v(_stateCtrl.text),
      addressZip: v(_zipCtrl.text),
      returnPolicy: v(_returnCtrl.text),
      shippingPolicy: v(_shippingCtrl.text),
      socialLinks: socialLinks.isEmpty ? null : socialLinks,
    );
    await ref.read(editShopControllerProvider.notifier).saveShopDetails(
          updatedShop: updated,
          newLogo: _newLogoBytes,
          newBanner: _newBannerBytes,
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
        _newLogoBytes = null;
        _newBannerBytes = null;
        _existingLogoUrl = saved.value?.logoUrl;
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isNew) return _buildSetup(context);
    return _buildEdit(context);
  }

  Widget _buildSetup(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create Shop',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.ink950),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Form(
                  key: _setupFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Shop name'),
                      const SizedBox(height: 6),
                      _SetupField(
                        controller: _nameCtrl,
                        hint: 'e.g. Pawsome Treats Co.',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      const _Label('URL slug'),
                      const SizedBox(height: 6),
                      _SetupField(
                        controller: _slugCtrl,
                        hint: 'e.g. pawsome-treats',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(v.trim())) {
                            return 'Use lowercase letters, numbers, and hyphens only';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const _Label('Description'),
                      const SizedBox(height: 6),
                      _SetupField(
                        controller: _setupDescCtrl,
                        hint: 'Tell buyers what makes your shop special…',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      const _Label('Payment location'),
                      const SizedBox(height: 10),
                      _LocationTile(
                        title: 'International',
                        subtitle: 'Receive payouts via Stripe',
                        icon: Icons.public_rounded,
                        selected: _selectedPayout == PayoutMethod.stripe,
                        onTap: () => setState(
                            () => _selectedPayout = PayoutMethod.stripe),
                      ),
                      const SizedBox(height: 10),
                      _LocationTile(
                        title: 'Bangladesh',
                        subtitle: 'Receive payouts via bank transfer',
                        icon: Icons.account_balance_rounded,
                        selected: _selectedPayout == PayoutMethod.manual,
                        onTap: () => setState(
                            () => _selectedPayout = PayoutMethod.manual),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PrimaryPillButton(
            label: 'Create shop',
            size: PillButtonSize.xl,
            isFullWidth: true,
            isLoading: _setupSaving,
            onPressed: _setupSaving ? null : _setupSave,
          ),
        ),
      ),
    );
  }

  Widget _buildEdit(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);
    final saveAsync = ref.watch(editShopControllerProvider);
    final isSaving = saveAsync.isLoading;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return shopAsync.when(
      loading: () => const Scaffold(
        body: Center(child: TailWagLoader()),
      ),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(e.toString()))),
      data: (shop) {
        if (shop == null) {
          return const Scaffold(
              body: Center(child: Text('No shop found')));
        }
        _populateEdit(shop);

        return Scaffold(
          backgroundColor: pt.surface1,
          appBar: AppBar(
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text('Edit Shop', style: tt.titleMedium),
            bottom: TabBar(
              controller: _editTabController,
              labelStyle: tt.labelMedium!
                  .copyWith(fontWeight: FontWeight.w600),
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
            controller: _editTabController,
            children: [
              _BrandingTab(
                shopNameCtrl: _shopNameCtrl,
                descriptionCtrl: _descriptionCtrl,
                logoBytes: _newLogoBytes,
                bannerBytes: _newBannerBytes,
                existingLogoUrl: _existingLogoUrl,
                existingBannerUrl: _existingBannerUrl,
                onPickLogo: () => _pickImage(isLogo: true),
                onPickBanner: () => _pickImage(isLogo: false),
              ),
              _ContactTab(
                emailCtrl: _emailCtrl,
                phoneCtrl: _phoneCtrl,
                streetCtrl: _streetCtrl,
                cityCtrl: _cityCtrl,
                stateCtrl: _stateCtrl,
                zipCtrl: _zipCtrl,
                websiteCtrl: _websiteCtrl,
                instagramCtrl: _instagramCtrl,
                facebookCtrl: _facebookCtrl,
                tiktokCtrl: _tiktokCtrl,
                youtubeCtrl: _youtubeCtrl,
              ),
              _PoliciesTab(
                returnCtrl: _returnCtrl,
                shippingCtrl: _shippingCtrl,
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PrimaryPillButton(
              label: 'Save Changes',
              isLoading: isSaving,
              isFullWidth: true,
              onPressed: isSaving ? null : () => _editSave(shop),
            ),
          ),
        );
      },
    );
  }
}

// ─── Setup form widgets ───────────────────────────────────────────────────────

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.title, required this.subtitle,
    required this.icon, required this.selected, required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface0,
          border: Border.all(
            color: selected ? AppColors.blue500 : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.blue500.withAlpha(20)
                    : AppColors.surface2,
              ),
              child: Icon(icon, size: 18,
                  color: selected ? AppColors.blue500 : AppColors.ink300),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.blue500 : AppColors.ink950,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.ink500)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.blue500 : AppColors.ink300,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink700),
    );
  }
}

class _SetupField extends StatelessWidget {
  const _SetupField({
    required this.controller, required this.hint,
    this.maxLines = 1, this.validator,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue500, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line, spreadRadius: 0.5),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.ink700),
      ),
    );
  }
}

// ─── Edit form tab widgets ────────────────────────────────────────────────────

class _BrandingTab extends StatelessWidget {
  const _BrandingTab({
    required this.shopNameCtrl, required this.descriptionCtrl,
    required this.logoBytes, required this.bannerBytes,
    required this.existingLogoUrl, required this.existingBannerUrl,
    required this.onPickLogo, required this.onPickBanner,
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
          _BannerPicker(bytes: bannerBytes, existingUrl: existingBannerUrl, onTap: onPickBanner),
          const SizedBox(height: 20),
          _SectionLabel('Shop Logo'),
          const SizedBox(height: 8),
          _LogoPicker(bytes: logoBytes, existingUrl: existingLogoUrl, onTap: onPickLogo),
          const SizedBox(height: 24),
          _FormField(controller: shopNameCtrl, label: 'Shop Name', hint: 'e.g. Paws & Claws Store'),
          const SizedBox(height: 16),
          _FormField(controller: descriptionCtrl, label: 'Description', hint: 'Tell customers about your shop…', maxLines: 4),
        ],
      ),
    );
  }
}

class _BannerPicker extends StatelessWidget {
  const _BannerPicker({required this.bytes, required this.existingUrl, required this.onTap});
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
          errorBuilder: (c, _, _) => _placeholder(c));
    } else {
      child = _placeholder(context);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140, width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusLg),
          color: AppColors.line, boxShadow: pt.shadowE1,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Container(decoration: BoxDecoration(color: AppColors.ink950.withAlpha(60))),
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
                    const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.blue500),
                    const SizedBox(width: 6),
                    Text('Change Banner', style: Theme.of(context).textTheme.labelMedium!
                        .copyWith(color: AppColors.blue500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
      color: AppColors.blue500.withAlpha(15),
      child: const Icon(Icons.storefront_outlined, size: 40, color: AppColors.blue500));
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.bytes, required this.existingUrl, required this.onTap});
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
          errorBuilder: (_, _, _) => const Icon(Icons.storefront_outlined, size: 28, color: AppColors.blue500));
    } else {
      image = const Icon(Icons.storefront_outlined, size: 28, color: AppColors.blue500);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, height: 80,
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
            Positioned(right: 4, bottom: 4,
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(color: AppColors.blue500, shape: BoxShape.circle),
                child: const Icon(Icons.edit, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTab extends StatelessWidget {
  const _ContactTab({
    required this.emailCtrl, required this.phoneCtrl,
    required this.streetCtrl, required this.cityCtrl,
    required this.stateCtrl, required this.zipCtrl,
    required this.websiteCtrl, required this.instagramCtrl,
    required this.facebookCtrl, required this.tiktokCtrl, required this.youtubeCtrl,
  });
  final TextEditingController emailCtrl, phoneCtrl, streetCtrl, cityCtrl,
      stateCtrl, zipCtrl, websiteCtrl, instagramCtrl, facebookCtrl, tiktokCtrl, youtubeCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Business'),
          const SizedBox(height: 8),
          _FormField(controller: emailCtrl, label: 'Business Email', hint: 'shop@example.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _FormField(controller: phoneCtrl, label: 'Business Phone', hint: '+1 555 000 0000', keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          const _SectionLabel('Address'),
          const SizedBox(height: 8),
          _FormField(controller: streetCtrl, label: 'Street', hint: '123 Main St'),
          const SizedBox(height: 16),
          _FormField(controller: cityCtrl, label: 'City', hint: 'New York'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _FormField(controller: stateCtrl, label: 'State / Province', hint: 'NY')),
            const SizedBox(width: 12),
            Expanded(child: _FormField(controller: zipCtrl, label: 'ZIP / Postal Code', hint: '10001', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 24),
          const _SectionLabel('Social Links'),
          const SizedBox(height: 8),
          _FormField(controller: websiteCtrl, label: 'Website', hint: 'https://yourshop.com', keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          _FormField(controller: instagramCtrl, label: 'Instagram', hint: 'https://instagram.com/yourshop', keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          _FormField(controller: facebookCtrl, label: 'Facebook', hint: 'https://facebook.com/yourshop', keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          _FormField(controller: tiktokCtrl, label: 'TikTok', hint: 'https://tiktok.com/@yourshop', keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          _FormField(controller: youtubeCtrl, label: 'YouTube', hint: 'https://youtube.com/@yourshop', keyboardType: TextInputType.url),
        ],
      ),
    );
  }
}

class _PoliciesTab extends StatelessWidget {
  const _PoliciesTab({required this.returnCtrl, required this.shippingCtrl});
  final TextEditingController returnCtrl;
  final TextEditingController shippingCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Return Policy'),
          const SizedBox(height: 8),
          _FormField(controller: returnCtrl, label: 'Return Policy', hint: 'Describe your return/refund policy…', maxLines: 6),
          const SizedBox(height: 24),
          const _SectionLabel('Shipping Policy'),
          const SizedBox(height: 8),
          _FormField(controller: shippingCtrl, label: 'Shipping Policy', hint: 'Describe your shipping times and rates…', maxLines: 6),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.ink500, letterSpacing: 0.8),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller, required this.label, required this.hint,
    this.maxLines = 1, this.keyboardType,
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
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: tt.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: tt.bodyMedium!.copyWith(color: AppColors.ink300),
            filled: true,
            fillColor: cs.surface,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 12 : 0),
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
              borderSide: const BorderSide(color: AppColors.blue500, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
