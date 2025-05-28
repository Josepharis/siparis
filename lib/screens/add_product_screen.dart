import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:siparis/config/theme.dart';
import 'package:siparis/models/order.dart';
import 'package:siparis/services/product_service.dart';
import 'package:siparis/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Tatlılar';
  bool _isActive = true;
  bool _isLoading = false;
  bool _isImageUploading = false;

  XFile? _selectedImage;
  String? _imageUrl;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _categories = [
    'Tatlılar',
    'Hamur İşleri',
    'Pastalar',
    'Kurabiyeler',
    'Şerbetli Tatlılar',
    'Ekmek',
    'Kek',
    'İçecekler',
    'Diğer',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Tatlılar': Icons.cake_outlined,
    'Hamur İşleri': Icons.bakery_dining_outlined,
    'Pastalar': Icons.celebration_outlined,
    'Kurabiyeler': Icons.cookie_outlined,
    'Şerbetli Tatlılar': Icons.local_dining_outlined,
    'Ekmek': Icons.breakfast_dining_outlined,
    'Kek': Icons.cake_outlined,
    'İçecekler': Icons.local_cafe_outlined,
    'Diğer': Icons.more_horiz_outlined,
  };

  final Map<String, Color> _categoryColors = {
    'Tatlılar': const Color(0xFFE91E63),
    'Hamur İşleri': const Color(0xFFFF9800),
    'Pastalar': const Color(0xFF9C27B0),
    'Kurabiyeler': const Color(0xFF795548),
    'Şerbetli Tatlılar': const Color(0xFF00BCD4),
    'Ekmek': const Color(0xFFFF5722),
    'Kek': const Color(0xFFE91E63),
    'İçecekler': const Color(0xFF2196F3),
    'Diğer': const Color(0xFF607D8B),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      developer.log('AddProductScreen: Resim seçme işlemi başlatıldı',
          name: 'AddProductScreen');

      // Resim kaynağını seç
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      setState(() {
        _isImageUploading = true;
      });

      final XFile? image = await ImageService.pickImage(source: source);

      if (image != null) {
        // Resim formatını kontrol et
        if (!ImageService.validateImageFormat(image)) {
          throw Exception(
              'Desteklenmeyen resim formatı. JPG, PNG veya WebP kullanın.');
        }

        // Resim boyutunu kontrol et
        if (!await ImageService.validateImageSize(image, maxSizeInMB: 5)) {
          throw Exception('Resim boyutu 5MB\'dan büyük olamaz.');
        }

        setState(() {
          _selectedImage = image;
        });

        developer.log('AddProductScreen: Resim başarıyla seçildi',
            name: 'AddProductScreen');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Resim seçildi! Ürünü kaydettiğinizde yüklenecek.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log('AddProductScreen: Resim seçilirken hata oluştu',
          name: 'AddProductScreen',
          error: e,
          stackTrace: stackTrace,
          level: 1000);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim seçilirken hata: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isImageUploading = false;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Resim Seç'),
          content: const Text('Resmi nereden seçmek istiyorsunuz?'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kamera'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galeri'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageUrl = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Resim kaldırıldı'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    developer.log('AddProductScreen: Ürün kaydetme işlemi başlatıldı',
        name: 'AddProductScreen');

    if (!_formKey.currentState!.validate()) {
      developer.log('AddProductScreen: Form validasyonu başarısız',
          name: 'AddProductScreen', level: 1000);
      return;
    }

    developer.log('AddProductScreen: Form validasyonu başarılı',
        name: 'AddProductScreen');

    setState(() {
      _isLoading = true;
    });

    try {
      // Önce ürünü oluştur (resim olmadan)
      final product = Product(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: _isActive,
      );

      developer.log(
          'AddProductScreen: Ürün objesi oluşturuldu: ${product.toJson()}',
          name: 'AddProductScreen');

      // Ürünü Firebase'e kaydet
      final String productId = await ProductService.addProduct(product);
      developer.log(
          'AddProductScreen: Ürün başarıyla kaydedildi, ID: $productId',
          name: 'AddProductScreen');

      // Eğer resim seçildiyse yükle
      if (_selectedImage != null) {
        try {
          developer.log('AddProductScreen: Resim yükleme başlatıldı',
              name: 'AddProductScreen');

          final String imageUrl =
              await ImageService.uploadProductImage(_selectedImage!, productId);

          // Ürünü resim URL'i ile güncelle
          final updatedProduct = Product(
            id: productId,
            name: product.name,
            price: product.price,
            category: product.category,
            description: product.description,
            isActive: product.isActive,
            imageUrl: imageUrl,
          );

          await ProductService.updateProduct(productId, updatedProduct);
          developer.log('AddProductScreen: Ürün resim URL\'i ile güncellendi',
              name: 'AddProductScreen');
        } catch (imageError) {
          developer.log(
              'AddProductScreen: Resim yüklenirken hata, ürün resim olmadan kaydedildi: $imageError',
              name: 'AddProductScreen',
              level: 1000);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ürün kaydedildi ancak resim yüklenemedi'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }

      developer.log('AddProductScreen: Ürün başarıyla kaydedildi',
          name: 'AddProductScreen');

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedImage != null
                ? 'Ürün resimle birlikte başarıyla eklendi!'
                : 'Ürün başarıyla eklendi!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log('AddProductScreen: Ürün kaydedilirken hata oluştu',
          name: 'AddProductScreen',
          error: e,
          stackTrace: stackTrace,
          level: 1000);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Modern App Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Ürün Ekle',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              'Ürün bilgilerini doldurun',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ürün Adı
                          _buildSectionTitle('Ürün Adı'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Örn: Çikolatalı Kek',
                            icon: Icons.shopping_bag_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ürün adı gerekli';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Fiyat
                          _buildSectionTitle('Fiyat (₺)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _priceController,
                            hint: 'Örn: 25.50',
                            icon: Icons.attach_money_outlined,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Fiyat gerekli';
                              }
                              final price = double.tryParse(value.trim());
                              if (price == null || price <= 0) {
                                return 'Geçerli bir fiyat girin';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Kategori
                          _buildSectionTitle('Kategori'),
                          const SizedBox(height: 8),
                          _buildCategorySelector(),

                          const SizedBox(height: 24),

                          // Ürün Resmi
                          _buildSectionTitle('Ürün Resmi (İsteğe Bağlı)'),
                          const SizedBox(height: 8),
                          _buildImageSelector(),

                          const SizedBox(height: 24),

                          // Açıklama
                          _buildSectionTitle('Açıklama (İsteğe Bağlı)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _descriptionController,
                            hint: 'Ürün hakkında detaylı bilgi...',
                            icon: Icons.description_outlined,
                            maxLines: 4,
                          ),

                          const SizedBox(height: 24),

                          // Durum
                          _buildSectionTitle('Durum'),
                          const SizedBox(height: 8),
                          _buildStatusSwitch(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),

                // Kaydet Butonu
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Ürünü Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Seçili kategori göstergesi
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _categoryColors[_selectedCategory]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _categoryIcons[_selectedCategory],
                    color: _categoryColors[_selectedCategory],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCategory,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),

          // Kategori grid listesi
          Container(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                final color = _categoryColors[category]!;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _categoryIcons[category],
                          color: isSelected ? Colors.white : color,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isActive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isActive
                  ? Icons.check_circle_outline
                  : Icons.pause_circle_outline,
              color: _isActive ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isActive ? 'Aktif' : 'Pasif',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  _isActive
                      ? 'Ürün müşterilere görünür olacak'
                      : 'Ürün müşterilere görünmeyecek',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _selectedImage != null
          ? _buildImagePreview()
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: kIsWeb
                ? Image.network(
                    _selectedImage!.path,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      developer.log(
                          'AddProductScreen: Web resim yükleme hatası: $error',
                          name: 'AddProductScreen',
                          level: 1000);
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  )
                : Image.file(
                    File(_selectedImage!.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      developer.log(
                          'AddProductScreen: Mobil resim yükleme hatası: $error',
                          name: 'AddProductScreen',
                          level: 1000);
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Overlay butonları
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              // Resmi değiştir butonu
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _isImageUploading ? null : _pickImage,
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Resmi kaldır butonu
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _isImageUploading ? null : _removeImage,
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Loading overlay
        if (_isImageUploading)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isImageUploading ? null : _pickImage,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isImageUploading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Resim hazırlanıyor...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  'Ürün Resmi Ekle',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dokunarak resim seçin',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Kamera veya Galeri',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
