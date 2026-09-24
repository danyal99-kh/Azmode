import 'package:azmode/pages/product_image.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class ProductCategory {
  final String id;
  final String name;

  /// تصویر/آیکون دسته‌بندی (اختیاری). فعلاً هیچ UI برای تنظیم آن وجود
  /// ندارد، اما فیلد از الان اضافه شده تا وقتی Backend وصل شد، بدون
  /// تغییر ساختار، تصویر واقعی هر دسته‌بندی نمایش داده شود.
  final String? imageUrl;

  ProductCategory({String? id, required this.name, this.imageUrl})
    : id = id ?? uuid.v4();
}

class PackagingType {
  final String id;
  final String name;

  PackagingType({String? id, required this.name}) : id = id ?? uuid.v4();
}

class Product {
  final String id;
  final String name;
  final String categoryId;
  final double price;
  final String description;
  final String imageUrl;

  // Optional fields
  final String? color;
  final String? size;
  final String? brand;
  final String? sku;
  final String? specifications;
  final List<String> colors;

  final PackagingType? packagingType;
  final ImageAspectRatio imageAspectRatio;
  final ProductImageSource imageSource;
  final String? thumbnailUrl;

  /// تاریخ ایجاد محصول — مبنای مرتب‌سازی «جدیدترین محصولات» در Home.
  /// چون فعلاً Backend وصل نیست، این مقدار در لحظه‌ی ساخت محصول (توسط
  /// ادمین) با `DateTime.now()` پر می‌شود؛ وقتی API واقعی وصل شود، کافی
  /// است این مقدار مستقیماً از فیلد معادل سرور (مثلاً created_at) پر
  /// شود — بدون نیاز به تغییر منطق مرتب‌سازی در StoreProvider یا UI.
  final DateTime createdAt;

  // Inventory
  bool isAvailable;
  int stock;

  Product({
    String? id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.thumbnailUrl,
    this.colors = const [],
    this.color,
    this.size,
    this.brand,
    this.sku,
    this.specifications,
    this.packagingType,
    this.stock = 0,
    this.isAvailable = true,
    this.imageAspectRatio = ImageAspectRatio.square,
    ProductImageSource? imageSource,
    DateTime? createdAt,
  }) : id = id ?? uuid.v4(),
       imageSource = imageSource ?? detectImageSource(imageUrl),
       createdAt = createdAt ?? DateTime.now();

  String get gridImageUrl {
    final t = thumbnailUrl?.trim();
    return (t != null && t.isNotEmpty) ? t : imageUrl;
  }
}

extension ProductCopy on Product {
  Product copyWith({String? categoryId, int? stock, bool? isAvailable}) {
    return Product(
      id: id,
      name: name,
      categoryId: categoryId ?? this.categoryId,
      price: price,
      description: description,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      imageSource: imageSource,
      colors: colors,
      color: color,
      size: size,
      brand: brand,
      sku: sku,
      specifications: specifications,
      packagingType: packagingType,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      imageAspectRatio: imageAspectRatio,
      createdAt: createdAt,
    );
  }
}

class CartItem {
  final Product product;
  final String? selectedColor;
  int quantity;

  CartItem({required this.product, this.selectedColor, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

enum OrderStatus { pending, approved, rejected }

class Order {
  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final List<CartItem> items;
  final DateTime date;
  OrderStatus status;

  Order({
    String? id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.date,
    this.status = OrderStatus.pending,
  }) : id = id ?? uuid.v4();

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
}

class StockMovement {
  final String id;
  final String productId;
  final int quantityChange;
  final DateTime date;
  final String reason;

  StockMovement({
    String? id,
    required this.productId,
    required this.quantityChange,
    required this.date,
    required this.reason,
  }) : id = id ?? uuid.v4();
}

class User {
  final String id;
  final String username;
  final String password;
  final bool isAdmin;
  final String fullName;
  final String phone;

  User({
    required this.id,
    required this.username,
    required this.password,
    this.isAdmin = false,
    required this.fullName,
    required this.phone,
  });
}

enum NotificationType { newProduct, orderApproved, orderRejected, general }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime date;
  bool isRead;
  final String? targetUserId;
  final String? relatedId;

  AppNotification({
    String? id,
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.targetUserId,
    this.relatedId,
  }) : id = id ?? uuid.v4();
}
// ═══════════════════════════════════════════════════════════════
// بنر تبلیغاتی صفحه اصلی
// ═══════════════════════════════════════════════════════════════

/// نوع مقصدی که با کلیک روی بنر اجرا می‌شود.
enum BannerTargetType { none, product, category, page }

/// استایل ظاهری بنر (گرادیان و آیکون). در کاروسل Home استفاده می‌شود.
enum PromoBannerStyle { teal, warm, dark }

String bannerTargetTypeToKey(BannerTargetType t) => t.name;

BannerTargetType bannerTargetTypeFromKey(String? key) {
  return BannerTargetType.values.firstWhere(
    (e) => e.name == key,
    orElse: () => BannerTargetType.none,
  );
}

/// مدل بنر تبلیغاتی. فیلدها عمداً با نام‌هایی انتخاب شده‌اند که مستقیماً
/// با یک پاسخ JSON از API قابل Map شدن باشند.
class PromoBanner {
  final String id;
  final String title;

  /// متنی که در کاروسل زیر عنوان نمایش داده می‌شود.
  /// (نام قبلی: description → تغییر یافت به subtitle تا با UI هماهنگ باشد)
  final String subtitle;

  final String imageUrl;
  final ProductImageSource imageSource;
  bool isActive;
  int sortOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final BannerTargetType targetType;
  final String? targetId;

  /// استایل ظاهری بنر. پیش‌فرض: teal
  final PromoBannerStyle style;

  PromoBanner({
    String? id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    ProductImageSource? imageSource,
    this.isActive = true,
    this.sortOrder = 0,
    this.startDate,
    this.endDate,
    this.targetType = BannerTargetType.none,
    this.targetId,
    this.style = PromoBannerStyle.teal,
    required String description,
  }) : id = id ?? uuid.v4(),
       imageSource = imageSource ?? detectImageSource(imageUrl);

  /// آیا الان (بر اساس ساعت سیستم) در بازه‌ی نمایش این بنر هستیم؟
  bool get isCurrentlyInDateRange {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
}

extension PromoBannerCopy on PromoBanner {
  PromoBanner copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    ProductImageSource? imageSource,
    bool? isActive,
    int? sortOrder,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    BannerTargetType? targetType,
    String? targetId,
    bool clearTargetId = false,
    PromoBannerStyle? style,
  }) {
    return PromoBanner(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      imageSource: imageSource ?? this.imageSource,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      targetType: targetType ?? this.targetType,
      targetId: clearTargetId ? null : (targetId ?? this.targetId),
      style: style ?? this.style,
      description: '',
    );
  }
}
