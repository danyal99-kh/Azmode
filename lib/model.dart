import 'package:azmode/pages/product_image.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class ProductCategory {
  final String id;
  final String name;

  ProductCategory({String? id, required this.name}) : id = id ?? uuid.v4();
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

  // قالب (نسبت ابعاد) عکس که ادمین هنگام آپلود انتخاب کرده؛ همین قالب در
  // همه‌جای اپ (صفحه اصلی، جزئیات محصول، سبد خرید و ...) استفاده می‌شود
  // تا عکس همیشه یک‌شکل و بدون کراپ‌شدن متفاوت نمایش داده شود.
  final ImageAspectRatio imageAspectRatio;

  // نوع منبع عکس (asset / base64 / url). این مقدار یک‌بار در سازنده
  // مشخص می‌شود (یا صریحاً داده می‌شود، یا از روی imageUrl حدس زده
  // می‌شود) تا ProductImage مجبور نباشد هر بار که رندر می‌شود دوباره
  // این تشخیص را با startsWith انجام دهد.
  final ProductImageSource imageSource;

  // Inventory
  int stock;

  Product({
    String? id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.colors = const [],
    this.color,
    this.size,
    this.brand,
    this.sku,
    this.specifications,
    this.stock = 0,
    this.imageAspectRatio = ImageAspectRatio.square,
    ProductImageSource? imageSource,
  }) : id = id ?? uuid.v4(),
       imageSource = imageSource ?? detectImageSource(imageUrl);

  bool get isAvailable => stock > 0;
}

/// امکان ساختن یک نسخه‌ی مستقل (Clone) از یک محصول، با امکان override
/// کردن چند فیلد خاص. دو مصرف اصلی دارد:
///
/// 1) وقتی سفارشی ثبت می‌شود، باید یک «عکس‌فوری» (Snapshot) منجمد از
///    محصول در همان لحظه در سفارش ذخیره شود — نه رفرنس زنده به همان
///    Object داخل لیست محصولات فروشگاه. در غیر این صورت، تغییرات بعدی
///    (مثلاً کم/زیاد شدن موجودی) به‌صورت خزنده روی سفارش‌های قدیمی هم
///    اثر می‌گذارد، چون همه به یک Object مشترک اشاره می‌کنند.
/// 2) وقتی یک دسته‌بندی حذف می‌شود، محصولات همان دسته باید به دسته‌ی
///    دیگری منتقل شوند (نه اینکه با categoryId نامعتبر یتیم بمانند)؛
///    چون [categoryId] فیلدی final است، این فقط با ساختن یک نسخه‌ی
///    جدید از محصول ممکن است.
extension ProductCopy on Product {
  Product copyWith({String? categoryId, int? stock}) {
    return Product(
      id: id,
      name: name,
      categoryId: categoryId ?? this.categoryId,
      price: price,
      description: description,
      imageUrl: imageUrl,
      imageSource: imageSource,
      colors: colors,
      color: color,
      size: size,
      brand: brand,
      sku: sku,
      specifications: specifications,
      stock: stock ?? this.stock,
      imageAspectRatio: imageAspectRatio,
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

  // شناسه‌ی کاربری که این سفارش را ثبت کرده؛ برای فیلتر کردن سفارش‌ها در
  // صفحه‌ی «پیش‌فاکتور» استفاده می‌شود تا هر مشتری فقط سفارش‌های خودش را
  // ببیند، نه سفارش‌های همه‌ی کاربران سیستم را.
  final String userId;

  final List<CartItem> items;
  final DateTime date;
  OrderStatus status;

  Order({
    String? id,
    required this.userId,
    required this.items,
    required this.date,
    this.status = OrderStatus.pending,
  }) : id = id ?? uuid.v4();

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
}

class StockMovement {
  final String id;
  final String productId;
  final int quantityChange; // positive for addition, negative for deduction
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

  User({
    required this.id,
    required this.username,
    required this.password,
    this.isAdmin = false,
  });
}

/// نوع اعلان داخل اپ. هر نوع می‌تواند به یک آیکون/رنگ اختصاصی و یک مقصد
/// مشخص (هنگام لمس اعلان) نگاشت شود.
enum NotificationType { newProduct, orderApproved, orderRejected, general }

/// اعلان داخل اپ.
///
/// بعضی اعلان‌ها عمومی‌اند و برای همه‌ی کاربران نمایش داده می‌شوند (مثلاً
/// «محصول جدید اضافه شد») که با [targetUserId] برابر null مشخص می‌شوند؛
/// بعضی دیگر مخصوص یک کاربر خاص‌اند (مثلاً تایید/رد سفارش) که با پر
/// بودن [targetUserId] مشخص می‌شوند و فقط همان کاربر آن‌ها را می‌بیند.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime date;
  bool isRead;

  /// اگر null باشد، اعلان عمومی است (برای همه). در غیر این صورت فقط
  /// برای کاربری با همین id نمایش داده می‌شود.
  final String? targetUserId;

  /// شناسه‌ی محصول یا سفارش مرتبط، برای هدایت کاربر هنگام لمس اعلان.
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
