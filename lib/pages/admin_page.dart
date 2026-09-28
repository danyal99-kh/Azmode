// ignore_for_file: unnecessary_underscores, use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:azmode/model.dart';
import 'package:azmode/models/proforma_item.dart';
import 'package:azmode/models/proforma.dart';
import 'package:azmode/pages/product_image.dart';
import 'package:azmode/providers/auth_provider.dart';
import 'package:azmode/providers/proforma_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    final store = context.read<StoreProvider>();
    await Future.wait([
      store.loadProducts(),
      store.loadCategories(),
      store.loadPackagingTypes(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('دسترسی غیرمجاز')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(context.rs.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'شما دسترسی لازم برای مشاهده این صفحه را ندارید.',
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyLarge,
                ),
                SizedBox(height: context.rs.md),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('بازگشت'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fs = context.fontScale;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'داشبورد مدیریت',
            style: context.textStyles.titleLarge?.withColor(
              AppColors.primaryWhite,
            ),
          ),
          actions: [
            IconButton(
              icon: store.isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: store.isRefreshing ? null : _refreshAll,
              tooltip: 'بروزرسانی',
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primaryWhite,
            unselectedLabelColor: AppColors.outlineGray,
            indicatorColor: AppColors.deepTeal,
            labelStyle: TextStyle(
              fontSize: (14.0 * fs).clamp(12.5, 16.0),
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: (14.0 * fs).clamp(12.5, 16.0),
            ),
            tabs: const [
              Tab(text: 'محصولات'),
              Tab(text: 'دسته‌بندی‌ها'),
              Tab(text: 'انبار'),
              Tab(text: 'فاکتورها'),
              Tab(text: 'بسته‌بندی'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AdminProductsTab(onRefresh: _refreshAll),
            _AdminCategoriesTab(onRefresh: _refreshAll),
            _AdminWarehouseTab(onRefresh: _refreshAll),
            _AdminInvoicesTab(onRefresh: _refreshAll),
            _AdminPackagingTypesTab(onRefresh: _refreshAll),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// تب دسته‌بندی‌ها
// ═══════════════════════════════════════════════════════════════
class _AdminCategoriesTab extends StatefulWidget {
  final VoidCallback? onRefresh;

  const _AdminCategoriesTab({this.onRefresh});

  @override
  State<_AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends State<_AdminCategoriesTab> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final ui = context.uiScale;

    if (store.isLoadingCategories && store.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.categoriesError != null && store.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.rs.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store.categoriesError!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge,
              ),
              SizedBox(height: context.rs.md),
              ElevatedButton(
                onPressed: () => store.loadCategories(),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.deepTeal,
      onRefresh: () async {
        await store.loadCategories();
        widget.onRefresh?.call();
      },
      child: context.centerMaxWidth(
        ListView(
          padding: EdgeInsets.all(context.rs.md),
          children: [
            ElevatedButton.icon(
              icon: store.isCategoryCrudLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('افزودن دسته‌بندی جدید'),
              onPressed: store.isCategoryCrudLoading
                  ? null
                  : () => _showCategoryDialog(context),
            ),
            SizedBox(height: context.rs.md),
            ...store.categories.map((cat) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceWhite,
                    child: Icon(Icons.category, color: AppColors.deepTeal),
                  ),
                  title: Text(cat.name, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.deepTeal),
                        onPressed: store.isCategoryCrudLoading
                            ? null
                            : () => _showCategoryDialog(context, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: store.isCategoryCrudLoading
                            ? null
                            : () => _deleteCategory(context, store, cat),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        maxWidth: 800 * ui.clamp(0.95, 1.15),
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    StoreProvider store,
    ProductCategory cat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف دسته‌بندی'),
        content: Text('آیا از حذف «${cat.name}» اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await store.deleteCategory(cat.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('دسته‌بندی «${cat.name}» حذف شد.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف دسته‌بندی: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCategoryDialog(BuildContext context, [ProductCategory? category]) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CategoryDialog(category: category),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final ProductCategory? category;
  const _CategoryDialog({this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameCtrl;
  Uint8List? _imageBytes;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');

    final existingUrl = widget.category?.imageUrl;
    if (existingUrl != null && existingUrl.trim().isNotEmpty) {
      if (detectImageSource(existingUrl) == ProductImageSource.base64) {
        try {
          _imageBase64 = existingUrl;
          _imageBytes = base64Decode(existingUrl);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در انتخاب تصویر: $e')));
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageBase64 = null;
    });
  }

  Future<void> _submit() async {
    final text = _nameCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final store = context.read<StoreProvider>();
      if (widget.category == null) {
        await store.addCategory(text, imageBase64: _imageBase64);
      } else {
        await store.updateCategory(
          widget.category!.id,
          text,
          imageBase64: _imageBase64,
          clearImage: _imageBase64 == null,
        );
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره دسته‌بندی: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final rr = context.rr;

    return AlertDialog(
      title: Text(
        widget.category == null ? 'افزودن دسته‌بندی' : 'ویرایش دسته‌بندی',
        style: context.textStyles.titleMedium?.bold,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth(context)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outlineGray),
                        borderRadius: BorderRadius.circular(rr.md),
                        color: AppColors.surfaceWhite,
                      ),
                      child: _imageBytes != null
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                          : const Icon(
                              Icons.category_outlined,
                              size: 40,
                              color: AppColors.outlineGray,
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: rs.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('انتخاب تصویر'),
                  ),
                  if (_imageBytes != null)
                    TextButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'حذف تصویر',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
              SizedBox(height: rs.sm),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'نام دسته‌بندی'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => context.pop(),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('ذخیره'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// تب محصولات
// ═══════════════════════════════════════════════════════════════
class _AdminProductsTab extends StatefulWidget {
  final VoidCallback? onRefresh;

  const _AdminProductsTab({this.onRefresh});

  @override
  State<_AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<_AdminProductsTab> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final ui = context.uiScale;

    final thumbSize = (50.0 * ui).clamp(44.0, 60.0);
    final thumbRadius = (6.0 * ui).clamp(5.0, 9.0);
    final placeholderIcon = (22.0 * ui).clamp(18.0, 28.0);

    if (store.isLoadingProducts && store.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.productsError != null && store.products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.rs.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store.productsError!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge,
              ),
              SizedBox(height: context.rs.md),
              ElevatedButton(
                onPressed: () => store.loadProducts(),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.deepTeal,
      onRefresh: () async {
        await store.loadProducts();
        widget.onRefresh?.call();
      },
      child: context.centerMaxWidth(
        ListView(
          padding: EdgeInsets.all(context.rs.md),
          children: [
            ElevatedButton.icon(
              icon: store.isProductCrudLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('افزودن محصول جدید'),
              onPressed: store.isProductCrudLoading
                  ? null
                  : () => _showProductDialog(context),
            ),
            SizedBox(height: context.rs.md),
            ...store.products.map((prod) {
              final cat = store.getCategoryById(prod.categoryId);
              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: thumbSize,
                    height: thumbSize,
                    child: ProductImage(
                      imageUrl: prod.imageUrl,
                      imageSource: prod.imageSource,
                      borderRadius: BorderRadius.circular(thumbRadius),
                      placeholderIconSize: placeholderIcon,
                    ),
                  ),
                  title: Text(
                    prod.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    'قیمت: ${prod.price} | موجودی: ${prod.stock} | دسته: ${cat?.name ?? '-'}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.deepTeal),
                        onPressed: store.isProductCrudLoading
                            ? null
                            : () => _showProductDialog(context, prod),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: store.isProductCrudLoading
                            ? null
                            : () => _deleteProduct(context, store, prod),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        maxWidth: 900 * ui.clamp(0.95, 1.15),
      ),
    );
  }

  void _showProductDialog(BuildContext context, [Product? product]) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ProductFormDialog(
        product: product,
        onSaved: () {},
      ),
    );
  }

  Future<void> _deleteProduct(
    BuildContext context,
    StoreProvider store,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف محصول'),
        content: Text('آیا از حذف «${product.name}» اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await store.deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('محصول «${product.name}» حذف شد.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف محصول: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// دیالوگ فرم محصول
// ═══════════════════════════════════════════════════════════════
class _ProductFormDialog extends StatefulWidget {
  final Product? product;
  final VoidCallback? onSaved;

  const _ProductFormDialog({this.product, this.onSaved});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  List<String> _colors = [];
  final TextEditingController _colorInputController = TextEditingController();
  late TextEditingController _nameCtrl,
      _priceCtrl,
      _descCtrl,
      _imgCtrl,
      _colorCtrl,
      _sizeCtrl,
      _brandCtrl,
      _skuCtrl,
      _specCtrl;
  String? _categoryId;
  String? _selectedImageBase64;
  Uint8List? _imageBytes;
  ImageAspectRatio _selectedAspectRatio = ImageAspectRatio.square;
  PackagingType? _selectedPackagingType;
  final TextEditingController _packagingTypeInputController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _colors = List<String>.of(p?.colors ?? const []);
    _imgCtrl = TextEditingController(
      text: p?.imageUrl ?? 'assets/images/pipe_null_1785319134530.jpg',
    );
    _colorCtrl = TextEditingController(text: p?.color ?? '');
    _sizeCtrl = TextEditingController(text: p?.size ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _specCtrl = TextEditingController(text: p?.specifications ?? '');
    _categoryId = p?.categoryId;
    _selectedPackagingType = p?.packagingType;
    _selectedAspectRatio = p?.imageAspectRatio ?? ImageAspectRatio.square;

    if (p != null && p.imageSource == ProductImageSource.base64) {
      try {
        _selectedImageBase64 = p.imageUrl;
        _imageBytes = base64Decode(p.imageUrl);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _imgCtrl.dispose();
    _colorCtrl.dispose();
    _sizeCtrl.dispose();
    _brandCtrl.dispose();
    _skuCtrl.dispose();
    _specCtrl.dispose();
    _packagingTypeInputController.dispose();
    _colorInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _selectedImageBase64 = base64Encode(bytes);
          _imageChanged = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در انتخاب تصویر: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreProvider>();
    if (_categoryId == null && store.categories.isNotEmpty) {
      _categoryId = store.categories.first.id;
    }

    final rs = context.rs;
    final rr = context.rr;
    final ui = context.uiScale;

    final maxDialogHeight = context.screenHeight * 0.82;

    final previewMaxWidth = (260.0 * ui).clamp(220.0, 320.0);
    final previewRadius = (8.0 * ui).clamp(6.0, 12.0);
    final previewInnerRadius = (previewRadius - 1).clamp(4.0, 11.0);
    final previewPlaceholderIcon = (44.0 * ui).clamp(36.0, 56.0);

    final chipAvatarIcon = (18.0 * ui).clamp(16.0, 22.0);
    final chipDeleteIcon = (16.0 * ui).clamp(14.0, 20.0);

    final compactInputPadding = EdgeInsets.symmetric(
      horizontal: (12.0 * ui).clamp(10.0, 16.0),
      vertical: (8.0 * ui).clamp(6.0, 12.0),
    );

    return AlertDialog(
      title: Text(
        widget.product == null ? 'افزودن محصول' : 'ویرایش محصول',
        style: context.textStyles.titleMedium?.bold,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth(context),
          maxHeight: maxDialogHeight,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: previewMaxWidth),
                    child: AspectRatio(
                      aspectRatio: _selectedAspectRatio.ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineGray),
                          borderRadius: BorderRadius.circular(previewRadius),
                          color: AppColors.surfaceWhite,
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  previewInnerRadius,
                                ),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image,
                                  size: previewPlaceholderIcon,
                                  color: AppColors.outlineGray,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: rs.sm),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('انتخاب تصویر'),
                  ),
                ),
                SizedBox(height: rs.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'قالب نمایش عکس:',
                    style: context.textStyles.bodyMedium?.bold,
                  ),
                ),
                SizedBox(height: rs.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'این قالب در صفحه اصلی و صفحه جزئیات محصول یکسان اعمال می‌شود.',
                    style: context.textStyles.bodySmall?.withColor(
                      AppColors.outlineGray,
                    ),
                  ),
                ),
                SizedBox(height: rs.sm),
                Wrap(
                  spacing: rs.sm,
                  runSpacing: rs.sm,
                  children: ImageAspectRatio.values.map((r) {
                    final isSelected = r == _selectedAspectRatio;
                    return ChoiceChip(
                      avatar: Icon(
                        r.icon,
                        size: chipAvatarIcon,
                        color: isSelected
                            ? AppColors.primaryWhite
                            : AppColors.deepTeal,
                      ),
                      label: Text('${r.label} (${r.ratioText})'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedAspectRatio = r),
                      selectedColor: AppColors.deepTeal,
                      backgroundColor: AppColors.surfaceWhite,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primaryWhite
                            : AppColors.primaryBlack,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(rr.sm),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.deepTeal
                              : AppColors.outlineGray,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: rs.sm),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  items: store.categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _categoryId = val),
                  decoration: const InputDecoration(
                    labelText: 'دسته‌بندی (الزامی)',
                  ),
                  validator: (val) =>
                      val == null ? 'انتخاب دسته‌بندی الزامی است' : null,
                ),
                SizedBox(height: rs.sm),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'نام محصول (الزامی)',
                  ),
                  validator: (v) => v!.isEmpty ? 'الزامی' : null,
                ),
                SizedBox(height: rs.sm),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: 'قیمت (الزامی)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'الزامی';
                    }
                    if (double.tryParse(v.trim()) == null) {
                      return 'لطفاً یک عدد معتبر وارد کنید';
                    }
                    return null;
                  },
                ),
                SizedBox(height: rs.sm),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات (الزامی)',
                  ),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'الزامی' : null,
                ),
                Divider(height: rs.xl),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'فیلدهای اختیاری',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: rs.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رنگ‌ها (اختیاری)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: rs.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _colorInputController,
                            decoration: InputDecoration(
                              hintText: 'مثلاً قرمز',
                              contentPadding: compactInputPadding,
                            ),
                            onSubmitted: _addColor,
                          ),
                        ),
                        SizedBox(width: rs.sm),
                        ElevatedButton(
                          onPressed: () =>
                              _addColor(_colorInputController.text),
                          child: const Text('افزودن'),
                        ),
                      ],
                    ),
                    SizedBox(height: rs.sm),
                    Wrap(
                      spacing: rs.sm,
                      runSpacing: rs.sm,
                      children: _colors.map((color) {
                        return Chip(
                          label: Text(color),
                          onDeleted: () => _removeColor(color),
                          deleteIcon: Icon(Icons.close, size: chipDeleteIcon),
                          backgroundColor: _getColorFromName(
                            color,
                          )?.withValues(alpha: 0.2),
                          side: BorderSide(
                            color:
                                _getColorFromName(color) ??
                                AppColors.outlineGray,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(rr.sm),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                SizedBox(height: rs.sm),
                TextFormField(
                  controller: _sizeCtrl,
                  decoration: const InputDecoration(labelText: 'اندازه'),
                ),
                SizedBox(height: rs.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نوع بسته‌بندی (اختیاری)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: rs.sm),
                    if (store.packagingTypes.isNotEmpty)
                      Wrap(
                        spacing: rs.sm,
                        runSpacing: rs.sm,
                        children: store.packagingTypes.map((type) {
                          final isSelected =
                              type.id == _selectedPackagingType?.id;
                          return ChoiceChip(
                            label: Text(type.name),
                            selected: isSelected,
                            onSelected: (_) => setState(
                              () => _selectedPackagingType = isSelected
                                  ? null
                                  : type,
                            ),
                            selectedColor: AppColors.deepTeal,
                            backgroundColor: AppColors.surfaceWhite,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryWhite
                                  : AppColors.primaryBlack,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    SizedBox(height: rs.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _packagingTypeInputController,
                            decoration: InputDecoration(
                              hintText: 'مثلاً شاخه‌ای، کارتونی، متری...',
                              contentPadding: compactInputPadding,
                            ),
                            onSubmitted: _addPackagingType,
                          ),
                        ),
                        SizedBox(width: rs.sm),
                        ElevatedButton(
                          onPressed: () => _addPackagingType(
                            _packagingTypeInputController.text,
                          ),
                          child: const Text('افزودن'),
                        ),
                      ],
                    ),
                  ],
                ),
                TextFormField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(labelText: 'برند'),
                ),
                SizedBox(height: rs.sm),
                TextFormField(
                  controller: _skuCtrl,
                  decoration: const InputDecoration(labelText: 'کد کالا (SKU)'),
                ),
                SizedBox(height: rs.sm),
                TextFormField(
                  controller: _specCtrl,
                  decoration: const InputDecoration(labelText: 'مشخصات فنی'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => context.pop(),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProduct,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('ذخیره'),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;

    setState(() => _isSaving = true);

    try {
      String finalImageUrl;
      if (_selectedImageBase64 != null) {
        finalImageUrl = _selectedImageBase64!;
      } else if (_imgCtrl.text.trim().isNotEmpty) {
        finalImageUrl = _imgCtrl.text.trim();
      } else {
        finalImageUrl = 'assets/images/pipe_null_1785319134530.jpg';
      }

      final imageSource = detectImageSource(finalImageUrl);
      final newProduct = Product(
        id: widget.product?.id,
        name: _nameCtrl.text,
        categoryId: _categoryId!,
        price: double.parse(_priceCtrl.text),
        description: _descCtrl.text,
        imageUrl: finalImageUrl,
        imageSource: imageSource,
        colors: _colors,
        packagingType: _selectedPackagingType,
        size: _sizeCtrl.text.isEmpty ? null : _sizeCtrl.text,
        brand: _brandCtrl.text.isEmpty ? null : _brandCtrl.text,
        sku: _skuCtrl.text.isEmpty ? null : _skuCtrl.text,
        specifications: _specCtrl.text.isEmpty ? null : _specCtrl.text,
        stock: widget.product?.stock ?? 0,
        imageAspectRatio: _selectedAspectRatio,
        createdAt: widget.product?.createdAt,
      );

      final store = context.read<StoreProvider>();
      if (widget.product == null) {
        await store.addProduct(newProduct);
      } else {
        final Product productToUpdate;
        if (_imageChanged) {
          productToUpdate = newProduct;
        } else {
          productToUpdate = Product(
            id: newProduct.id,
            name: newProduct.name,
            categoryId: newProduct.categoryId,
            price: newProduct.price,
            description: newProduct.description,
            imageUrl: widget.product!.imageUrl,
            imageSource: widget.product!.imageSource,
            colors: newProduct.colors,
            packagingType: newProduct.packagingType,
            size: newProduct.size,
            brand: newProduct.brand,
            sku: newProduct.sku,
            specifications: newProduct.specifications,
            stock: newProduct.stock,
            imageAspectRatio: newProduct.imageAspectRatio,
            createdAt: newProduct.createdAt,
          );
        }
        await store.updateProduct(widget.product!.id, productToUpdate);
      }

      if (mounted) {
        context.pop();
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره محصول: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addColor(String color) {
    final trimmed = color.trim();
    if (trimmed.isNotEmpty && !_colors.contains(trimmed)) {
      setState(() {
        _colors.add(trimmed);
        _colorInputController.clear();
      });
    }
  }

  void _addPackagingType(String value) {
    final trimmed = value.trim();

    final packagingType = context
        .read<StoreProvider>()
        .packagingTypes
        .cast<PackagingType?>()
        .firstWhere((item) => item?.name == trimmed, orElse: () => null);

    if (packagingType == null) return;

    setState(() {
      _selectedPackagingType = packagingType;
      _packagingTypeInputController.clear();
    });
  }

  Color? _getColorFromName(String colorName) {
    final colors = {
      'قرمز': Colors.red,
      'سبز': Colors.green,
      'آبی': Colors.blue,
      'زرد': Colors.yellow,
      'مشکی': Colors.black,
      'سفید': Colors.white,
      'نارنجی': Colors.orange,
      'بنفش': Colors.purple,
      'صورتی': Colors.pink,
      'طوسی': Colors.grey,
      'نقره‌ای': Colors.grey.shade400,
      'طلایی': Colors.amber,
      'قهوه‌ای': Colors.brown,
    };
    return colors[colorName];
  }

  void _removeColor(String color) {
    setState(() {
      _colors.remove(color);
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// تب فاکتورها
// ═══════════════════════════════════════════════════════════════
class _AdminInvoicesTab extends StatefulWidget {
  final VoidCallback? onRefresh;

  const _AdminInvoicesTab({this.onRefresh});

  @override
  State<_AdminInvoicesTab> createState() => _AdminInvoicesTabState();
}

class _AdminInvoicesTabState extends State<_AdminInvoicesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProformaProvider>().loadAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final proforma = context.watch<ProformaProvider>();
    final rs = context.rs;

    if (proforma.allOrdersLoading && proforma.allOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (proforma.allOrdersError != null && proforma.allOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(rs.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                proforma.allOrdersError!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge,
              ),
              SizedBox(height: rs.md),
              ElevatedButton(
                onPressed: () => proforma.loadAllOrders(),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    final orders = proforma.allOrders;

    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: rs.xl),
          child: Text(
            'هیچ فاکتوری برای نمایش وجود ندارد.',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyLarge,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.deepTeal,
      onRefresh: proforma.loadAllOrders,
      child: context.centerMaxWidth(
        ListView.separated(
          padding: EdgeInsets.all(rs.md),
          itemCount: orders.length,
          separatorBuilder: (_, __) => SizedBox(height: rs.md),
          itemBuilder: (context, index) {
            final order = orders[index];
            final statusColor = _statusColor(order.status);
            final isPending = order.status == ProformaStatus.pending;

            return Card(
              child: Padding(
                padding: EdgeInsets.all(rs.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InvoiceHeader(order: order, statusColor: statusColor),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.outlineGray,
                        ),
                        SizedBox(width: context.rs.xs),
                        Expanded(
                          child: Text(
                            order.customerName,
                            style: context.textStyles.bodyMedium?.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.rs.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            _statusText(order.status),
                            style: context.textStyles.bodySmall
                                ?.withColor(statusColor)
                                .bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.rs.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: AppColors.outlineGray,
                        ),
                        SizedBox(width: context.rs.xs),
                        SelectableText(
                          order.customerPhone,
                          style: context.textStyles.bodyMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: rs.sm),
                    ...order.items.map((item) => _InvoiceItemRow(item: item)),

                    Divider(height: rs.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('جمع کل:', style: context.textStyles.titleMedium),
                        SizedBox(width: rs.sm),
                        Flexible(
                          child: Text(
                            '${order.totalAmount} تومان',
                            style: context.textStyles.titleMedium?.bold
                                .withColor(AppColors.deepTeal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: rs.md),
                    _InvoiceActions(
                      isPending: isPending,
                      onReject: () => _updateStatus(
                        context,
                        order,
                        ProformaStatus.rejected,
                      ),
                      onApprove: () => _updateStatus(
                        context,
                        order,
                        ProformaStatus.approved,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        maxWidth: 800 * context.uiScale.clamp(0.95, 1.15),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    ProformaOrder order,
    ProformaStatus status,
  ) async {
    final error = await context.read<ProformaProvider>().updateOrderStatus(
      order,
      status,
    );
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  String _statusText(ProformaStatus status) {
    switch (status) {
      case ProformaStatus.pending:
        return 'در انتظار تایید';
      case ProformaStatus.approved:
        return 'تایید شده';
      case ProformaStatus.rejected:
        return 'رد شده';
    }
  }

  Color _statusColor(ProformaStatus status) {
    switch (status) {
      case ProformaStatus.pending:
        return AppColors.warning;
      case ProformaStatus.approved:
        return AppColors.success;
      case ProformaStatus.rejected:
        return AppColors.error;
    }
  }
}

class _InvoiceHeader extends StatelessWidget {
  final ProformaOrder order;
  final Color statusColor;

  const _InvoiceHeader({required this.order, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final rr = context.rr;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'فاکتور #${order.id}',
            style: context.textStyles.titleMedium?.bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: rs.sm),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: rs.sm,
            vertical: (rs.xs * 0.8).clamp(3.0, 6.0),
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(rr.sm),
            border: Border.all(color: statusColor.withValues(alpha: 0.25)),
          ),
          child: Text(
            _statusText(),
            style: context.textStyles.bodySmall?.withColor(statusColor).bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _statusText() {
    switch (order.status) {
      case ProformaStatus.pending:
        return 'در انتظار تایید';
      case ProformaStatus.approved:
        return 'تایید شده';
      case ProformaStatus.rejected:
        return 'رد شده';
    }
  }
}

class _InvoiceItemRow extends StatelessWidget {
  final ProformaOrderItem item;
  const _InvoiceItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    final name =
        '${item.productName} (x${item.quantity})'
        '${item.selectedColor != null && item.selectedColor!.trim().isNotEmpty ? ' - ${item.selectedColor}' : ''}';

    return Padding(
      padding: EdgeInsets.only(bottom: rs.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ui = context.uiScale;
          final isNarrow = constraints.maxWidth < 300 * ui;

          final nameText = Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyMedium,
          );

          final priceText = Text(
            '${item.totalPrice} تومان',
            style: context.textStyles.bodyMedium?.bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nameText,
                Padding(
                  padding: EdgeInsets.only(top: rs.xs * 0.5),
                  child: priceText,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: nameText),
              SizedBox(width: rs.sm),
              priceText,
            ],
          );
        },
      ),
    );
  }
}

class _InvoiceActions extends StatelessWidget {
  final bool isPending;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _InvoiceActions({
    required this.isPending,
    required this.onReject,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 320 * ui;

        final rejectBtn = OutlinedButton.icon(
          onPressed: isPending ? onReject : null,
          icon: const Icon(Icons.close, color: AppColors.error),
          label: const FittedBox(fit: BoxFit.scaleDown, child: Text('رد کردن')),
        );

        final approveBtn = ElevatedButton.icon(
          onPressed: isPending ? onApprove : null,
          icon: const Icon(Icons.check, color: AppColors.primaryWhite),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('تایید فاکتور'),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rejectBtn,
              SizedBox(height: rs.sm),
              approveBtn,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: rejectBtn),
            SizedBox(width: rs.md),
            Expanded(child: approveBtn),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// تب انبار
// ═══════════════════════════════════════════════════════════════
class _AdminWarehouseTab extends StatefulWidget {
  final VoidCallback? onRefresh;

  const _AdminWarehouseTab({this.onRefresh});

  @override
  State<_AdminWarehouseTab> createState() => _AdminWarehouseTabState();
}

class _AdminWarehouseTabState extends State<_AdminWarehouseTab> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final rs = context.rs;
    final ui = context.uiScale;

    if (store.isLoadingProducts && store.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      color: AppColors.deepTeal,
      onRefresh: () async {
        await store.loadProducts();
        widget.onRefresh?.call();
      },
      child: context.centerMaxWidth(
        ListView.builder(
          padding: EdgeInsets.all(rs.md),
          itemCount: store.products.length,
          itemBuilder: (context, index) {
            final prod = store.products[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: rs.sm),
              child: Padding(
                padding: EdgeInsets.all(rs.md),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 320 * ui;

                    final info = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prod.name,
                          style: context.textStyles.titleMedium?.bold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: rs.xs * 0.5),
                        Text(
                          'موجودی فعلی: ${prod.stock}',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: prod.stock > 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );

                    final button = ElevatedButton(
                      onPressed: store.isAdjustingStock
                          ? null
                          : () => _showAdjustStockDialog(context, prod),
                      child: store.isAdjustingStock
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('تغییر موجودی'),
                            ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          info,
                          SizedBox(height: rs.sm),
                          button,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: info),
                        SizedBox(width: rs.sm),
                        button,
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
        maxWidth: 800 * ui.clamp(0.95, 1.15),
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => _AdjustStockDialog(product: product),
    );
  }
}

class _AdjustStockDialog extends StatefulWidget {
  final Product product;
  const _AdjustStockDialog({required this.product});

  @override
  State<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<_AdjustStockDialog> {
  final _qtyCtrl = TextEditingController();
  late final TextEditingController _reasonCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController(text: 'ورود به انبار');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final change = int.tryParse(_qtyCtrl.text) ?? 0;
    if (change == 0) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<StoreProvider>().adjustStock(
            widget.product.id,
            change,
            _reasonCtrl.text,
          );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('موجودی «${widget.product.name}» به‌روزرسانی شد.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در تغییر موجودی: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    return AlertDialog(
      title: Text(
        'تغییر موجودی ${widget.product.name}',
        style: context.textStyles.titleMedium?.bold,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth(context)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'موجودی فعلی: ${widget.product.stock}',
                style: context.textStyles.bodyMedium,
              ),
              SizedBox(height: rs.sm),
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مقدار تغییر (مثبت یا منفی)',
                ),
              ),
              SizedBox(height: rs.sm),
              TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(labelText: 'دلیل تغییر'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => context.pop(),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('ثبت'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// تب بسته‌بندی
// ═══════════════════════════════════════════════════════════════
class _AdminPackagingTypesTab extends StatefulWidget {
  final VoidCallback? onRefresh;

  const _AdminPackagingTypesTab({this.onRefresh});

  @override
  State<_AdminPackagingTypesTab> createState() => _AdminPackagingTypesTabState();
}

class _AdminPackagingTypesTabState extends State<_AdminPackagingTypesTab> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final rs = context.rs;
    final ui = context.uiScale;

    if (store.isLoadingPackagingTypes && store.packagingTypes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store.packagingTypesError != null && store.packagingTypes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(rs.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store.packagingTypesError!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge,
              ),
              SizedBox(height: rs.md),
              ElevatedButton(
                onPressed: () => store.loadPackagingTypes(),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.deepTeal,
      onRefresh: () async {
        await store.loadPackagingTypes();
        widget.onRefresh?.call();
      },
      child: context.centerMaxWidth(
        ListView(
          padding: EdgeInsets.all(rs.md),
          children: [
            ElevatedButton.icon(
              icon: store.isPackagingTypeCrudLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('افزودن نوع بسته‌بندی جدید'),
              onPressed: store.isPackagingTypeCrudLoading
                  ? null
                  : () => _showAddDialog(context),
            ),
            SizedBox(height: rs.md),
            ...store.packagingTypes.map((type) {
              return Card(
                child: ListTile(
                  leading: Icon(Icons.inventory_2, color: AppColors.deepTeal),
                  title: Text(type.name, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.deepTeal),
                        onPressed: store.isPackagingTypeCrudLoading
                            ? null
                            : () => _showEditDialog(context, type),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: store.isPackagingTypeCrudLoading
                            ? null
                            : () => _deletePackagingType(context, store, type),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        maxWidth: 800 * ui.clamp(0.95, 1.15),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('افزودن نوع بسته‌بندی'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'نام نوع بسته‌بندی'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                await context.read<StoreProvider>().addPackagingType(name);
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('خطا در افزودن نوع بسته‌بندی: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, PackagingType type) {
    final controller = TextEditingController(text: type.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش نوع بسته‌بندی'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'نام نوع بسته‌بندی'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                await context.read<StoreProvider>()
                    .updatePackagingType(type.id, name);
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('خطا در ویرایش نوع بسته‌بندی: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePackagingType(
    BuildContext context,
    StoreProvider store,
    PackagingType type,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف نوع بسته‌بندی'),
        content: Text('آیا از حذف «${type.name}» اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await store.deletePackagingType(type.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('نوع بسته‌بندی «${type.name}» حذف شد.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف نوع بسته‌بندی: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
