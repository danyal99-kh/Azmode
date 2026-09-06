import 'dart:convert';
import 'dart:typed_data';

import 'package:azmode/model.dart';
import 'package:azmode/pages/product_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('شما دسترسی لازم برای مشاهده این صفحه را ندارید.'),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('بازگشت'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'داشبورد مدیریت',
            style: context.textStyles.titleLarge?.withColor(
              AppColors.primaryWhite,
            ),
          ),
          bottom: TabBar(
            isScrollable: context.isMobile && context.screenWidth < 380,
            labelColor: AppColors.primaryWhite,
            unselectedLabelColor: AppColors.outlineGray,
            indicatorColor: AppColors.deepTeal,
            tabs: const [
              Tab(text: 'محصولات'),
              Tab(text: 'دسته‌بندی‌ها'),
              Tab(text: 'انبار'),
              Tab(text: 'فاکتورها'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AdminProductsTab(),
            _AdminCategoriesTab(),
            _AdminWarehouseTab(),
            _AdminInvoicesTab(),
          ],
        ),
      ),
    );
  }
}

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
                  title: Text(cat.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.deepTeal),
                        onPressed: () => _showCategoryDialog(context, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => store.deleteCategory(cat.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      maxWidth: 800,
    );
  }

  void _showCategoryDialog(BuildContext context, [ProductCategory? category]) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            category == null ? 'افزودن دسته‌بندی' : 'ویرایش دسته‌بندی',
          ),
          content: SizedBox(
            width: dialogWidth(context),
            child: TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'نام دسته‌بندی'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = nameCtrl.text.trim();
                if (text.isNotEmpty) {
                  if (category == null) {
                    context.read<StoreProvider>().addCategory(text);
                  } else {
                    context.read<StoreProvider>().updateCategory(
                      category.id,
                      text,
                    );
                  }
                  context.pop();
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
        );
      },
    );
  }
}

class _AdminProductsTab extends StatelessWidget {
  const _AdminProductsTab();

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
                    width: 50,
                    height: 50,
                    child: ProductImage(
                      imageUrl: prod.imageUrl,
                      imageSource: prod.imageSource,
                      borderRadius: BorderRadius.circular(6),
                      placeholderIconSize: 22,
                    ),
                  ),
                  title: Text(prod.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    'قیمت: ${prod.price} | دسته: ${cat?.name ?? '-'}',
                    overflow: TextOverflow.ellipsis,
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
      maxWidth: 900,
    );
  }

  void _showProductDialog(BuildContext context, [Product? product]) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
    );
  }
}

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

  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _colors = p?.colors ?? [];
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
    _selectedAspectRatio = p?.imageAspectRatio ?? ImageAspectRatio.square;

    // برای پیش‌نمایش در دیالوگ ویرایش، فقط وقتی عکس محصول از نوع Base64
    // است بایت‌ها را دیکود می‌کنیم؛ این تشخیص حالا از روی فیلد صریح
    // imageSource انجام می‌شود، نه حدس زدن با startsWith.
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
    // ارتفاع دیالوگ را به صفحه محدود می‌کنیم تا روی گوشی‌های کوتاه هم
    // اسکرول‌شدنی و قابل استفاده بماند.
    final maxDialogHeight = context.screenHeight * 0.82;

    return AlertDialog(
      title: Text(widget.product == null ? 'افزودن محصول' : 'ویرایش محصول'),
      content: SizedBox(
        width: dialogWidth(context),
        height: maxDialogHeight,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // پیش‌نمایش عکس - دقیقاً با همان قالبی که پایین انتخاب می‌شود،
                // تا ادمین از قبل ببیند عکس در اپ چطور برش می‌خورد.
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: AspectRatio(
                      aspectRatio: _selectedAspectRatio.ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineGray),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.surfaceWhite,
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 44,
                                  color: AppColors.outlineGray,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.rs.sm),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('انتخاب تصویر'),
                  ),
                ),
                SizedBox(height: context.rs.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'قالب نمایش عکس:',
                    style: context.textStyles.bodyMedium?.bold,
                  ),
                ),
                SizedBox(height: context.rs.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'این قالب در صفحه اصلی و صفحه جزئیات محصول یکسان اعمال می‌شود.',
                    style: context.textStyles.bodySmall?.withColor(
                      AppColors.outlineGray,
                    ),
                  ),
                ),
                SizedBox(height: context.rs.sm),
                Wrap(
                  spacing: context.rs.sm,
                  runSpacing: context.rs.sm,
                  children: ImageAspectRatio.values.map((r) {
                    final isSelected = r == _selectedAspectRatio;
                    return ChoiceChip(
                      avatar: Icon(
                        r.icon,
                        size: 18,
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
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.deepTeal
                              : AppColors.outlineGray,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: context.rs.sm),
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
                SizedBox(height: context.rs.sm),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'نام محصول (الزامی)',
                  ),
                  validator: (v) => v!.isEmpty ? 'الزامی' : null,
                ),
                SizedBox(height: context.rs.sm),
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
                SizedBox(height: context.rs.sm),
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
                SizedBox(height: context.rs.sm),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات (الزامی)',
                  ),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'الزامی' : null,
                ),
                Divider(height: context.rs.xl),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'فیلدهای اختیاری',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: context.rs.sm),
                // انتخاب رنگ‌ها
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رنگ‌ها (اختیاری)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: context.rs.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _colorInputController,
                            decoration: const InputDecoration(
                              hintText: 'مثلاً قرمز',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: _addColor,
                          ),
                        ),
                        SizedBox(width: context.rs.sm),
                        ElevatedButton(
                          onPressed: () =>
                              _addColor(_colorInputController.text),
                          child: const Text('افزودن'),
                        ),
                      ],
                    ),
                    SizedBox(height: context.rs.sm),
                    Wrap(
                      spacing: context.rs.sm,
                      runSpacing: context.rs.sm,
                      children: _colors.map((color) {
                        return Chip(
                          label: Text(color),
                          onDeleted: () => _removeColor(color),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          backgroundColor: _getColorFromName(
                            color,
                          )?.withValues(alpha: 0.2),
                          side: BorderSide(
                            color:
                                _getColorFromName(color) ??
                                AppColors.outlineGray,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                SizedBox(height: context.rs.sm),
                TextFormField(
                  controller: _sizeCtrl,
                  decoration: const InputDecoration(labelText: 'اندازه'),
                ),
                SizedBox(height: context.rs.sm),
                TextFormField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(labelText: 'برند'),
                ),
                SizedBox(height: context.rs.sm),
                TextFormField(
                  controller: _skuCtrl,
                  decoration: const InputDecoration(labelText: 'کد کالا (SKU)'),
                ),
                SizedBox(height: context.rs.sm),
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

              // نوع منبع فقط همین یک‌بار (هنگام ذخیره) از روی مقدار نهایی
              // تشخیص داده می‌شود و روی خود محصول ذخیره می‌شود؛ از این به
              // بعد هیچ صفحه‌ای دیگر لازم نیست این تشخیص را تکرار کند.
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
                size: _sizeCtrl.text.isEmpty ? null : _sizeCtrl.text,
                brand: _brandCtrl.text.isEmpty ? null : _brandCtrl.text,
                sku: _skuCtrl.text.isEmpty ? null : _skuCtrl.text,
                specifications: _specCtrl.text.isEmpty ? null : _specCtrl.text,
                stock: stock,
                imageAspectRatio: _selectedAspectRatio,
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

class _AdminInvoicesTab extends StatelessWidget {
  const _AdminInvoicesTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final orders = store.orders.reversed.toList();

    if (orders.isEmpty) {
      return const Center(child: Text('هیچ فاکتوری برای نمایش وجود ندارد.'));
    }

    return context.centerMaxWidth(
      ListView.separated(
        padding: EdgeInsets.all(context.rs.md),
        itemCount: orders.length,
        separatorBuilder: (_, _) => SizedBox(height: context.rs.md),
        itemBuilder: (context, index) {
          final order = orders[index];
          final statusColor = _statusColor(order.status);
          final isPending = order.status == OrderStatus.pending;

          return Card(
            child: Padding(
              padding: EdgeInsets.all(context.rs.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: order ID and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'فاکتور #${order.id.substring(0, 8)}',
                          style: context.textStyles.titleMedium?.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rs.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: statusColor.withOpacity(0.25),
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
                  SizedBox(height: context.rs.sm),
                  // Order items with color
                  ...order.items.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: context.rs.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // نمایش دایره‌ی رنگ (اختیاری)
                                if (item.selectedColor != null)
                                  Container(
                                    width: 14,
                                    height: 14,
                                    margin: EdgeInsets.only(
                                      right: context.rs.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _getColorFromName(
                                            item.selectedColor!,
                                          ) ??
                                          Colors.grey,
                                      border: Border.all(
                                        color: AppColors.outlineGray,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    '${item.product.name} (x${item.quantity})'
                                    '${item.selectedColor != null ? ' - ${item.selectedColor}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.totalPrice} تومان',
                            style: context.textStyles.bodyMedium?.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: context.rs.lg),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('جمع کل:', style: context.textStyles.titleMedium),
                      Text(
                        '${order.totalAmount} تومان',
                        style: context.textStyles.titleMedium?.bold.withColor(
                          AppColors.deepTeal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rs.md),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isPending
                              ? () => store.updateOrderStatus(
                                  order.id,
                                  OrderStatus.rejected,
                                )
                              : null,
                          icon: const Icon(Icons.close, color: AppColors.error),
                          label: const Text('رد کردن'),
                        ),
                      ),
                      SizedBox(width: context.rs.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isPending
                              ? () => store.updateOrderStatus(
                                  order.id,
                                  OrderStatus.approved,
                                )
                              : null,
                          icon: const Icon(
                            Icons.check,
                            color: AppColors.primaryWhite,
                          ),
                          label: const Text('تایید فاکتور'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      maxWidth: 800,
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

  // تابع کمکی برای تشخیص رنگ از نام (برای نمایش دایره‌ی رنگ)
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

class _AdminWarehouseTab extends StatelessWidget {
  const _AdminWarehouseTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    return context.centerMaxWidth(
      ListView.builder(
        itemCount: store.products.length,
        itemBuilder: (context, index) {
          final prod = store.products[index];
          return Card(
            margin: EdgeInsets.symmetric(
              horizontal: context.rs.md,
              vertical: context.rs.sm,
            ),
            child: Padding(
              padding: EdgeInsets.all(context.rs.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prod.name,
                          style: context.textStyles.titleMedium?.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'موجودی فعلی: ${prod.stock}',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: prod.stock > 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showAdjustStockDialog(context, prod),
                    child: const Text('تغییر موجودی'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      maxWidth: 800,
    );
  }

  void _showAdjustStockDialog(BuildContext context, Product product) {
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'ورود به انبار');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تغییر موجودی ${product.name}'),
        content: SizedBox(
          width: dialogWidth(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('موجودی فعلی: ${product.stock}'),
              SizedBox(height: context.rs.sm),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مقدار تغییر (مثبت یا منفی)',
                ),
              ),
              SizedBox(height: context.rs.sm),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'دلیل تغییر'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              final change = int.tryParse(qtyCtrl.text) ?? 0;
              if (change != 0) {
                context.read<StoreProvider>().adjustStock(
                  product.id,
                  change,
                  reasonCtrl.text,
                );
                context.pop();
              }
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }
}
