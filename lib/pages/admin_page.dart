import 'dart:convert';
import 'dart:typed_data';

import 'package:azmode/model.dart';
import 'package:azmode/pages/product_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();

    if (!store.isAdmin) {
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
          bottom: TabBar(
            isScrollable: context.isMobile && context.screenWidth < 420,
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
              Tab(text: 'بنرها'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AdminProductsTab(),
            _AdminCategoriesTab(),
            _AdminWarehouseTab(),
            _AdminInvoicesTab(),
            _AdminBannersTab(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// تب دسته‌بندی‌ها
// ═══════════════════════════════════════════════════════════════
class _AdminCategoriesTab extends StatelessWidget {
  const _AdminCategoriesTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    return context.centerMaxWidth(
      Column(
        children: [
          Padding(
            padding: EdgeInsets.all(context.rs.md),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('افزودن دسته‌بندی جدید'),
              onPressed: () => _showCategoryDialog(context),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: store.categories.length,
              itemBuilder: (context, index) {
                final cat = store.categories[index];
                return ListTile(
                  title: Text(cat.name, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.deepTeal),
                        onPressed: () => _showCategoryDialog(context, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _deleteCategory(context, store, cat),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      maxWidth: 800 * context.uiScale.clamp(0.95, 1.15),
    );
  }

  void _deleteCategory(
    BuildContext context,
    StoreProvider store,
    ProductCategory cat,
  ) {
    final hadProducts = store.getProductsByCategory(cat.id).isNotEmpty;
    final success = store.deleteCategory(cat.id);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'این تنها دسته‌بندی موجود است و محصول دارد. ابتدا یک دسته‌بندی دیگر اضافه کنید.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (hadProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'دسته‌بندی حذف شد؛ محصولات آن به دسته‌ی دیگری منتقل شدند.',
          ),
        ),
      );
    }
  }

  void _showCategoryDialog(BuildContext context, [ProductCategory? category]) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
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

  void _submit() {
    final text = _nameCtrl.text.trim();
    if (text.isEmpty) return;
    final store = context.read<StoreProvider>();
    if (widget.category == null) {
      store.addCategory(text, imageUrl: _imageBase64);
    } else {
      store.updateCategory(
        widget.category!.id,
        text,
        imageUrl: _imageBase64,
        clearImage: _imageBase64 == null,
      );
    }
    context.pop();
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
        TextButton(onPressed: () => context.pop(), child: const Text('انصراف')),
        ElevatedButton(onPressed: _submit, child: const Text('ذخیره')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// تب محصولات
// ═══════════════════════════════════════════════════════════════
class _AdminProductsTab extends StatelessWidget {
  const _AdminProductsTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final ui = context.uiScale;
    final rr = context.rr;

    final thumbSize = (50.0 * ui).clamp(44.0, 60.0);
    final thumbRadius = (6.0 * ui).clamp(5.0, 9.0);
    final placeholderIcon = (22.0 * ui).clamp(18.0, 28.0);

    return context.centerMaxWidth(
      Column(
        children: [
          Padding(
            padding: EdgeInsets.all(context.rs.md),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('افزودن محصول جدید'),
              onPressed: () => _showProductDialog(context),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: store.products.length,
              itemBuilder: (context, index) {
                final prod = store.products[index];
                final cat = store.getCategoryById(prod.categoryId);
                return ListTile(
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
                    'قیمت: ${prod.price} | دسته: ${cat?.name ?? '-'}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.deepTeal),
                        onPressed: () => _showProductDialog(context, prod),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => store.deleteProduct(prod.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      maxWidth: 900 * ui.clamp(0.95, 1.15),
    );
  }

  void _showProductDialog(BuildContext context, [Product? product]) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// دیالوگ فرم محصول
// ═══════════════════════════════════════════════════════════════
class _ProductFormDialog extends StatefulWidget {
  final Product? product;
  const _ProductFormDialog({this.product});

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
      _stockCtrl,
      _colorCtrl,
      _sizeCtrl,
      _brandCtrl,
      _skuCtrl,
      _specCtrl;
  String? _categoryId;
  String? _selectedImageBase64;
  Uint8List? _imageBytes;
  ImageAspectRatio _selectedAspectRatio = ImageAspectRatio.square;
  String? _selectedPackagingType;
  final TextEditingController _packagingTypeInputController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();

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
    _stockCtrl = TextEditingController(text: (p?.stock ?? 0).toString());
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
    _stockCtrl.dispose();
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
                  controller: _stockCtrl,
                  decoration: const InputDecoration(
                    labelText: 'موجودی اولیه (الزامی)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'الزامی';
                    final n = int.tryParse(v);
                    if (n == null || n < 0) return 'عدد معتبر وارد کنید';
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
                          final isSelected = type == _selectedPackagingType;
                          return ChoiceChip(
                            label: Text(type),
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
        TextButton(onPressed: () => context.pop(), child: const Text('انصراف')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _categoryId != null) {
              String finalImageUrl;
              if (_selectedImageBase64 != null) {
                finalImageUrl = _selectedImageBase64!;
              } else if (_imgCtrl.text.trim().isNotEmpty) {
                finalImageUrl = _imgCtrl.text.trim();
              } else {
                finalImageUrl = 'assets/images/pipe_null_1785319134530.jpg';
              }

              final imageSource = detectImageSource(finalImageUrl);
              final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
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
                stock: stock,
                imageAspectRatio: _selectedAspectRatio,
                createdAt: widget.product?.createdAt,
              );
              if (widget.product == null) {
                store.addProduct(newProduct);
              } else {
                store.updateProduct(widget.product!.id, newProduct);
              }
              context.pop();
            }
          },
          child: const Text('ذخیره'),
        ),
      ],
    );
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
    if (trimmed.isEmpty) return;
    context.read<StoreProvider>().addPackagingType(trimmed);
    setState(() {
      _selectedPackagingType = trimmed;
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
class _AdminInvoicesTab extends StatelessWidget {
  const _AdminInvoicesTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final orders = store.orders.reversed.toList();
    final rs = context.rs;

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

    return context.centerMaxWidth(
      ListView.separated(
        padding: EdgeInsets.all(rs.md),
        itemCount: orders.length,
        separatorBuilder: (_, _) => SizedBox(height: rs.md),
        itemBuilder: (context, index) {
          final order = orders[index];
          final statusColor = _statusColor(order.status);
          final isPending = order.status == OrderStatus.pending;

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
                          style: context.textStyles.titleMedium?.bold.withColor(
                            AppColors.deepTeal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: rs.md),
                  _InvoiceActions(
                    isPending: isPending,
                    onReject: () =>
                        store.updateOrderStatus(order.id, OrderStatus.rejected),
                    onApprove: () =>
                        store.updateOrderStatus(order.id, OrderStatus.approved),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      maxWidth: 800 * context.uiScale.clamp(0.95, 1.15),
    );
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'در انتظار تایید';
      case OrderStatus.approved:
        return 'تایید شده';
      case OrderStatus.rejected:
        return 'رد شده';
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.approved:
        return AppColors.success;
      case OrderStatus.rejected:
        return AppColors.error;
    }
  }
}

class _InvoiceHeader extends StatelessWidget {
  final Order order;
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
            'فاکتور #${order.id.substring(0, 8)}',
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
      case OrderStatus.pending:
        return 'در انتظار تایید';
      case OrderStatus.approved:
        return 'تایید شده';
      case OrderStatus.rejected:
        return 'رد شده';
    }
  }
}

class _InvoiceItemRow extends StatelessWidget {
  final CartItem item;
  const _InvoiceItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final ui = context.uiScale;

    final dotSize = (14.0 * ui).clamp(12.0, 18.0);

    final name =
        '${item.product.name} (x${item.quantity})'
        '${item.selectedColor != null ? ' - ${item.selectedColor}' : ''}';

    return Padding(
      padding: EdgeInsets.only(bottom: rs.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 300 * ui;

          final colorDot = item.selectedColor != null
              ? Container(
                  width: dotSize,
                  height: dotSize,
                  margin: EdgeInsets.only(right: rs.xs),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _getColorFromName(item.selectedColor!) ?? Colors.grey,
                    border: Border.all(color: AppColors.outlineGray, width: 1),
                  ),
                )
              : const SizedBox.shrink();

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
                Row(
                  children: [
                    colorDot,
                    Expanded(child: nameText),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: rs.xs * 0.5),
                  child: priceText,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    colorDot,
                    Expanded(child: nameText),
                  ],
                ),
              ),
              SizedBox(width: rs.sm),
              priceText,
            ],
          );
        },
      ),
    );
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
class _AdminWarehouseTab extends StatelessWidget {
  const _AdminWarehouseTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final rs = context.rs;
    final ui = context.uiScale;

    return context.centerMaxWidth(
      ListView.builder(
        itemCount: store.products.length,
        itemBuilder: (context, index) {
          final prod = store.products[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: rs.md, vertical: rs.sm),
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
                    onPressed: () => _showAdjustStockDialog(context, prod),
                    child: const FittedBox(
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

  void _submit() {
    final change = int.tryParse(_qtyCtrl.text) ?? 0;
    if (change != 0) {
      context.read<StoreProvider>().adjustStock(
        widget.product.id,
        change,
        _reasonCtrl.text,
      );
      context.pop();
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
        TextButton(onPressed: () => context.pop(), child: const Text('انصراف')),
        ElevatedButton(onPressed: _submit, child: const Text('ثبت')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// تب بنرها
// ═══════════════════════════════════════════════════════════════
class _AdminBannersTab extends StatelessWidget {
  const _AdminBannersTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final banners = [...store.banners]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final rs = context.rs;
    final ui = context.uiScale;

    return context.centerMaxWidth(
      Column(
        children: [
          Padding(
            padding: EdgeInsets.all(rs.md),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('افزودن بنر جدید'),
              onPressed: () => _showBannerDialog(context),
            ),
          ),
          Expanded(
            child: banners.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(rs.xl),
                      child: Text(
                        'هنوز بنری ثبت نشده است.',
                        style: context.textStyles.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: rs.md),
                    itemCount: banners.length,
                    separatorBuilder: (_, __) => SizedBox(height: rs.sm),
                    itemBuilder: (context, index) {
                      final banner = banners[index];
                      return _BannerAdminCard(
                        banner: banner,
                        isFirst: index == 0,
                        isLast: index == banners.length - 1,
                        onEdit: () => _showBannerDialog(context, banner),
                        onDelete: () =>
                            _confirmDeleteBanner(context, store, banner),
                        onToggleActive: () =>
                            store.toggleBannerActive(banner.id),
                        onMoveUp: () => store.moveBannerUp(banner.id),
                        onMoveDown: () => store.moveBannerDown(banner.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      maxWidth: 800 * ui.clamp(0.95, 1.15),
    );
  }

  void _showBannerDialog(BuildContext context, [PromoBanner? banner]) {
    showDialog(
      context: context,
      builder: (context) => _BannerFormDialog(banner: banner),
    );
  }

  void _confirmDeleteBanner(
    BuildContext context,
    StoreProvider store,
    PromoBanner banner,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف بنر'),
        content: Text('آیا از حذف بنر «${banner.title}» مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              store.deleteBanner(banner.id);
              context.pop();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _BannerAdminCard extends StatelessWidget {
  final PromoBanner banner;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _BannerAdminCard({
    required this.banner,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final rr = context.rr;
    final ui = context.uiScale;
    final thumbSize = (56.0 * ui).clamp(48.0, 68.0);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(rs.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: thumbSize,
              height: thumbSize,
              child: ProductImage(
                imageUrl: banner.imageUrl,
                imageSource: banner.imageSource,
                borderRadius: BorderRadius.circular(rr.sm),
              ),
            ),
            SizedBox(width: rs.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    style: context.textStyles.bodyMedium?.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (banner.subtitle.trim().isNotEmpty)
                    Text(
                      banner.subtitle,
                      style: context.textStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: rs.xs),
                  Text(
                    _targetLabel(banner),
                    style: context.textStyles.bodySmall?.withColor(
                      AppColors.outlineGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: banner.isActive,
                  onChanged: (_) => onToggleActive(),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      onPressed: isFirst ? null : onMoveUp,
                      tooltip: 'بالا',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      onPressed: isLast ? null : onMoveDown,
                      tooltip: 'پایین',
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: AppColors.deepTeal,
                        size: 20,
                      ),
                      onPressed: onEdit,
                      tooltip: 'ویرایش',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: onDelete,
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(PromoBanner b) {
    switch (b.targetType) {
      case BannerTargetType.none:
        return 'بدون مقصد';
      case BannerTargetType.product:
        return 'مقصد: محصول (${b.targetId ?? '-'})';
      case BannerTargetType.category:
        return 'مقصد: دسته‌بندی (${b.targetId ?? '-'})';
      case BannerTargetType.page:
        return 'مقصد: صفحه (${b.targetId ?? '-'})';
    }
  }
}

class _BannerFormDialog extends StatefulWidget {
  final PromoBanner? banner;
  const _BannerFormDialog({this.banner});

  @override
  State<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<_BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl, _descCtrl, _pageTargetCtrl;
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  BannerTargetType _targetType = BannerTargetType.none;
  String? _targetId;
  Uint8List? _imageBytes;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _descCtrl = TextEditingController(text: b?.subtitle ?? '');
    _isActive = b?.isActive ?? true;
    _startDate = b?.startDate;
    _endDate = b?.endDate;
    _targetType = b?.targetType ?? BannerTargetType.none;
    _targetId = b?.targetId;
    _pageTargetCtrl = TextEditingController(
      text: _targetType == BannerTargetType.page ? (b?.targetId ?? '') : '',
    );

    if (b != null && b.imageSource == ProductImageSource.base64) {
      try {
        _imageBase64 = b.imageUrl;
        _imageBytes = base64Decode(b.imageUrl);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pageTargetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 82,
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

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _startDate : _endDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    final finalImageUrl = _imageBase64;
    if (finalImageUrl == null || finalImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً یک تصویر برای بنر انتخاب کنید.')),
      );
      return;
    }

    String? resolvedTargetId;
    switch (_targetType) {
      case BannerTargetType.none:
        resolvedTargetId = null;
        break;
      case BannerTargetType.product:
      case BannerTargetType.category:
        resolvedTargetId = _targetId;
        break;
      case BannerTargetType.page:
        resolvedTargetId = _pageTargetCtrl.text.trim();
        break;
    }

    final store = context.read<StoreProvider>();
    final imageSource = detectImageSource(finalImageUrl);

    if (widget.banner == null) {
      final newBanner = PromoBanner(
        title: title,
        subtitle: desc,
        imageUrl: finalImageUrl,
        imageSource: imageSource,
        isActive: _isActive,
        sortOrder: store.banners.length,
        startDate: _startDate,
        endDate: _endDate,
        targetType: _targetType,
        targetId: resolvedTargetId,
        description: '',
      );
      store.addBanner(newBanner);
    } else {
      final updated = widget.banner!.copyWith(
        title: title,
        subtitle: desc,
        imageUrl: finalImageUrl,
        imageSource: imageSource,
        isActive: _isActive,
        startDate: _startDate,
        clearStartDate: _startDate == null,
        endDate: _endDate,
        clearEndDate: _endDate == null,
        targetType: _targetType,
        targetId: resolvedTargetId,
        clearTargetId: resolvedTargetId == null,
      );
      store.updateBanner(widget.banner!.id, updated);
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final rs = context.rs;
    final rr = context.rr;
    final formatter = intl.DateFormat('yyyy/MM/dd');

    return AlertDialog(
      title: Text(
        widget.banner == null ? 'افزودن بنر' : 'ویرایش بنر',
        style: context.textStyles.titleMedium?.bold,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth(context),
          maxHeight: context.screenHeight * 0.8,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineGray),
                          borderRadius: BorderRadius.circular(rr.sm),
                          color: AppColors.surfaceWhite,
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(rr.sm - 1),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 40,
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
                    label: const Text('انتخاب تصویر بنر'),
                  ),
                ),
                SizedBox(height: rs.md),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان (الزامی)',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الزامی' : null,
                ),
                SizedBox(height: rs.sm),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'توضیح کوتاه'),
                  maxLines: 2,
                ),
                SizedBox(height: rs.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('فعال'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                Divider(height: rs.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'بازه نمایش (اختیاری)',
                    style: context.textStyles.bodyMedium?.bold,
                  ),
                ),
                SizedBox(height: rs.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isStart: true),
                        child: Text(
                          _startDate == null
                              ? 'تاریخ شروع'
                              : formatter.format(_startDate!),
                        ),
                      ),
                    ),
                    SizedBox(width: rs.sm),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _startDate = null),
                      ),
                  ],
                ),
                SizedBox(height: rs.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isStart: false),
                        child: Text(
                          _endDate == null
                              ? 'تاریخ پایان'
                              : formatter.format(_endDate!),
                        ),
                      ),
                    ),
                    SizedBox(width: rs.sm),
                    if (_endDate != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _endDate = null),
                      ),
                  ],
                ),
                Divider(height: rs.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'مقصد بنر',
                    style: context.textStyles.bodyMedium?.bold,
                  ),
                ),
                SizedBox(height: rs.sm),
                DropdownButtonFormField<BannerTargetType>(
                  initialValue: _targetType,
                  items: const [
                    DropdownMenuItem(
                      value: BannerTargetType.none,
                      child: Text('بدون مقصد'),
                    ),
                    DropdownMenuItem(
                      value: BannerTargetType.product,
                      child: Text('محصول'),
                    ),
                    DropdownMenuItem(
                      value: BannerTargetType.category,
                      child: Text('دسته‌بندی'),
                    ),
                    DropdownMenuItem(
                      value: BannerTargetType.page,
                      child: Text('صفحه داخل اپ'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _targetType = v;
                      _targetId = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'نوع مقصد'),
                ),
                SizedBox(height: rs.sm),
                if (_targetType == BannerTargetType.product)
                  DropdownButtonFormField<String>(
                    initialValue: _targetId,
                    isExpanded: true,
                    items: store.products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _targetId = v),
                    decoration: const InputDecoration(
                      labelText: 'انتخاب محصول',
                    ),
                  ),
                if (_targetType == BannerTargetType.category)
                  DropdownButtonFormField<String>(
                    initialValue: _targetId,
                    isExpanded: true,
                    items: store.categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _targetId = v),
                    decoration: const InputDecoration(
                      labelText: 'انتخاب دسته‌بندی',
                    ),
                  ),
                if (_targetType == BannerTargetType.page)
                  TextFormField(
                    controller: _pageTargetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'مسیر صفحه (مثلاً /proforma)',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('انصراف')),
        ElevatedButton(onPressed: _submit, child: const Text('ذخیره')),
      ],
    );
  }
}
