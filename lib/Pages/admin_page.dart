import 'package:azmode/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../store_provider.dart';
import 'package:go_router/go_router.dart';

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
          bottom: const TabBar(
            labelColor: AppColors.primaryWhite,
            unselectedLabelColor: AppColors.outlineGray,
            indicatorColor: AppColors.deepTeal,
            tabs: [
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'نام دسته‌بندی'),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                leading: Image.asset(
                  prod.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image),
                ),
                title: Text(prod.name),
                subtitle: Text(
                  'قیمت: ${prod.price} | دسته: ${cat?.name ?? '-'}',
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

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreProvider>();
    if (_categoryId == null && store.categories.isNotEmpty) {
      _categoryId = store.categories.first.id;
    }

    return AlertDialog(
      title: Text(widget.product == null ? 'افزودن محصول' : 'ویرایش محصول'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  items: store.categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c!.id,
                          child: Text(c.name),
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
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'نام محصول (الزامی)',
                  ),
                  validator: (v) => v!.isEmpty ? 'الزامی' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: 'قیمت (الزامی)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'الزامی' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
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
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات (الزامی)',
                  ),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'الزامی' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _imgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'آدرس تصویر (الزامی)',
                  ),
                ),
                const Divider(height: AppSpacing.xl),
                const Text(
                  'فیلدهای اختیاری',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _colorCtrl,
                  decoration: const InputDecoration(labelText: 'رنگ'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _sizeCtrl,
                  decoration: const InputDecoration(labelText: 'اندازه'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(labelText: 'برند'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _skuCtrl,
                  decoration: const InputDecoration(labelText: 'کد کالا (SKU)'),
                ),
                const SizedBox(height: AppSpacing.sm),
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
              final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
              final newProduct = Product(
                id: widget.product?.id,
                name: _nameCtrl.text,
                categoryId: _categoryId!,
                price: double.parse(_priceCtrl.text),
                description: _descCtrl.text,
                imageUrl: _imgCtrl.text,
                color: _colorCtrl.text.isEmpty ? null : _colorCtrl.text,
                size: _sizeCtrl.text.isEmpty ? null : _sizeCtrl.text,
                brand: _brandCtrl.text.isEmpty ? null : _brandCtrl.text,
                sku: _skuCtrl.text.isEmpty ? null : _skuCtrl.text,
                specifications: _specCtrl.text.isEmpty ? null : _specCtrl.text,
                stock: stock,
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

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final order = orders[index];
        final statusColor = _statusColor(order.status);
        final isPending = order.status == OrderStatus.pending;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'فاکتور #${order.id.substring(0, 8)}',
                        style: context.textStyles.titleMedium?.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
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
                const SizedBox(height: AppSpacing.sm),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.product.name} (x${item.quantity})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${item.totalPrice} تومان'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.md),
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
                    const SizedBox(width: AppSpacing.md),
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

class _AdminWarehouseTab extends StatelessWidget {
  const _AdminWarehouseTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    return ListView.builder(
      itemCount: store.products.length,
      itemBuilder: (context, index) {
        final prod = store.products[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.name,
                        style: context.textStyles.titleMedium?.bold,
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
    );
  }

  void _showAdjustStockDialog(BuildContext context, Product product) {
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'ورود به انبار');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تغییر موجودی ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('موجودی فعلی: ${product.stock}'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مقدار تغییر (مثبت یا منفی)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'دلیل تغییر'),
            ),
          ],
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
