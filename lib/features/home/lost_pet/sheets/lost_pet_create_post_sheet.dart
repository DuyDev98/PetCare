part of '../../screens/lost_pet_screen.dart';

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();
  final _imageKey = GlobalKey();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _otherKindCtrl = TextEditingController(); // tên loại thú cưng khác

  String _kind = _dogKind;
  LostPetStatus _postStatus = LostPetStatus.lost; // loại tin đăng
  bool _isUrgent = false;
  bool _isSaving = false;
  bool _submitted = false;
  bool _showImageError = false;
  String? _formErrorText;
  XFile? _pickedImage; // ảnh đã chọn
  Uint8List? _pickedImageBytes;
  String? _pickedImageMimeType;

  static const _orange = Color(0xFFE07B2B);

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _descCtrl.dispose();
    _weightCtrl.dispose();
    _phoneCtrl.dispose();
    _locCtrl.dispose();
    _otherKindCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _formErrorText = null;
      _showImageError = false;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _formErrorText =
            'Vui lòng điền đầy đủ thông tin bắt buộc trước khi đăng bài.';
      });
      _scrollToTop();
      return;
    }

    final pickedImage = _pickedImage;
    final pickedImageBytes = _pickedImageBytes;
    if (pickedImage == null ||
        pickedImageBytes == null ||
        pickedImageBytes.isEmpty) {
      setState(() {
        _showImageError = true;
        _formErrorText =
            'Vui lòng thêm ảnh thú cưng để người khác dễ nhận diện.';
      });
      _scrollToImage();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Bạn cần đăng nhập trước khi đăng bài.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = user.uid;
      final weight = double.parse(_weightCtrl.text.trim().replaceAll(',', '.'));
      final imageUrl = await _uploadPickedImage(
        pickedImageBytes,
        uid,
        mimeType: _pickedImageMimeType,
      );

      // Xác định kind: nếu chọn "Khác" thì dùng tên nhập vào
      final kindValue = _kind == _otherKindFilter
          ? (_otherKindCtrl.text.trim().isNotEmpty
                ? _otherKindCtrl.text.trim()
                : _otherKindFilter)
          : _kind;

      final post = LostPetPost(
        id: '',
        userId: uid,
        name: _nameCtrl.text.trim(),
        kind: kindValue,
        breed: _breedCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        weight: weight,
        imageUrl: imageUrl,
        status: _postStatus,
        isUrgent: _isUrgent,
        isClosed: false,
        location: const GeoPoint(0, 0),
        locationName: _locCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await LostPetService.createPost(post);
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showSnack(_firebaseErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi khi đăng bài. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String> _uploadPickedImage(
    Uint8List bytes,
    String uid, {
    String? mimeType,
  }) async {
    if (bytes.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'local-file-not-found',
        message: 'Không đọc được ảnh đã chọn trên thiết bị.',
      );
    }

    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw FirebaseException(
        plugin: 'cloudinary',
        code: 'missing-config',
        message: 'Thiếu cấu hình Cloudinary trong file .env.',
      );
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final contentType = mimeType ?? 'image/jpeg';
    final extension = contentType == 'image/png' ? 'png' : 'jpg';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'lost_pets/$uid'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$timestamp.$extension',
        ),
      );

    final response = await request.send().timeout(const Duration(seconds: 30));
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw FirebaseException(
        plugin: 'cloudinary',
        code: 'upload-failed',
        message: responseBody,
      );
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = json['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw FirebaseException(
        plugin: 'cloudinary',
        code: 'missing-url',
        message: 'Cloudinary không trả về đường dẫn ảnh.',
      );
    }

    return secureUrl;
  }

  String _firebaseErrorMessage(FirebaseException e) {
    if (e.code == 'local-file-not-found') {
      return 'Không đọc được ảnh đã chọn. Vui lòng chọn ảnh khác hoặc chụp ảnh mới.';
    }
    if (e.plugin == 'cloudinary') {
      if (e.code == 'missing-config') {
        return 'Thiếu cấu hình Cloudinary trong file .env.';
      }
      return 'Không tải được ảnh lên Cloudinary. Vui lòng thử lại.';
    }
    if (e.plugin == 'firebase_storage' && e.code == 'object-not-found') {
      return 'Firebase Storage không tìm thấy ảnh sau khi tải lên. App hiện đã chuyển sang Cloudinary, hãy stop app rồi run lại.';
    }
    if (e.plugin == 'firebase_storage' && e.code == 'unauthorized') {
      return 'Bạn chưa có quyền tải ảnh lên. Vui lòng kiểm tra đăng nhập hoặc Storage rules.';
    }
    if (e.plugin == 'cloud_firestore' && e.code == 'permission-denied') {
      return 'Bạn chưa có quyền tạo bài đăng. Vui lòng kiểm tra đăng nhập hoặc Firestore rules.';
    }
    return 'Lỗi khi đăng bài. Vui lòng thử lại.';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _scrollToTop() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!_scrollCtrl.hasClients) return;
    await _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _scrollToImage() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final imageContext = _imageKey.currentContext;
    if (imageContext == null || !imageContext.mounted) return;
    await Scrollable.ensureVisible(
      imageContext,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0.25,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: source, imageQuality: 80);
    if (img != null) {
      final bytes = await _readPickedImageBytes(img);
      if (bytes.isEmpty) {
        setState(() {
          _pickedImage = null;
          _pickedImageBytes = null;
          _pickedImageMimeType = null;
          _showImageError = true;
          _formErrorText =
              'Không đọc được ảnh đã chọn. Vui lòng chọn ảnh khác hoặc chụp ảnh mới.';
        });
        _scrollToImage();
        return;
      }

      setState(() {
        _pickedImage = img;
        _pickedImageBytes = bytes;
        _pickedImageMimeType = img.mimeType;
        _showImageError = false;
        if (_formErrorText?.contains('ảnh') ?? false) _formErrorText = null;
      });
    }
  }

  Future<Uint8List> _readPickedImageBytes(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      if (bytes.isNotEmpty) return bytes;
    } catch (_) {
      // Fall through to File-based read for Android picker cache paths.
    }

    final path = image.path;
    if (path.isEmpty || path.startsWith('content://')) return Uint8List(0);

    try {
      final file = File(path);
      if (!file.existsSync()) return Uint8List(0);
      return file.readAsBytes();
    } catch (_) {
      return Uint8List(0);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFE07B2B)),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFFE07B2B),
              ),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5EFE6),

      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),

          child: Form(
            key: _formKey,

            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,

            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios),
                      ),

                      const Expanded(
                        child: Text(
                          'Đăng tin mới',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 40),
                    ],
                  ),

                  const SizedBox(height: 25),

                  if (_formErrorText != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE53935)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFE53935),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formErrorText!,
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // LOẠI TIN
                  const Text(
                    'Loại tin cứu trợ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  _dropdownBox(),

                  const SizedBox(height: 18),

                  // LOẠI THÚ
                  const Text(
                    'Loại thú cưng',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  _petTypeBox(),

                  const SizedBox(height: 18),

                  // TÊN THÚ CƯNG
                  const Text(
                    'Tên thú cưng',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  _field(
                    _nameCtrl,
                    'VD: Mochi, Cục Bông, Lucky...',
                    required: true,
                  ),

                  const SizedBox(height: 18),

                  // GIỐNG
                  const Text(
                    'Giống',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  _field(
                    _breedCtrl,
                    'VD: Corgi, Poodle, Mèo Anh lông ngắn...',
                    required: true,
                  ),

                  const SizedBox(height: 18),

                  // VỊ TRÍ
                  const Text(
                    'Vị trí',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  _field(_locCtrl, 'VD: 55 Giải Phóng, Hà Nội', required: true),

                  const SizedBox(height: 18),

                  // ẢNH
                  const Text(
                    'Ảnh thú cưng',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  GestureDetector(
                    key: _imageKey,
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _pickedImage != null
                              ? _orange
                              : _showImageError
                              ? const Color(0xFFE53935)
                              : Colors.grey.shade400,
                          width: _showImageError ? 1.5 : 1,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF7F3EF),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _pickedImageBytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                  _pickedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _pickedImage = null;
                                      _pickedImageBytes = null;
                                      _pickedImageMimeType = null;
                                    }),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.orange.shade100,
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Chụp/Tải ảnh thú cưng',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),

                  if (_showImageError) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Vui lòng thêm ảnh thú cưng',
                      style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // MÔ TẢ
                  const Text(
                    'Mô tả',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  _field(
                    _descCtrl,
                    'Mô tả đặc điểm nhận dạng thú cưng...',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 18),

                  // CAN NANG
                  const Text(
                    'Cân nặng (kg)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  _field(
                    _weightCtrl,
                    'VD: 4.5',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateWeight,
                  ),

                  const SizedBox(height: 18),

                  // PHONE
                  const Text(
                    'Số điện thoại liên hệ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  _field(
                    _phoneCtrl,
                    '09xx xxx xxx',
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),

                  const SizedBox(height: 18),

                  // KHẨN CẤP
                  GestureDetector(
                    onTap: () => setState(() => _isUrgent = !_isUrgent),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _isUrgent
                            ? const Color(0xFFFFEBEB)
                            : const Color(0xFFF7F3EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isUrgent
                              ? const Color(0xFFE53935)
                              : Colors.grey.shade300,
                          width: _isUrgent ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isUrgent
                                  ? const Color(0xFFE53935)
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: _isUrgent ? Colors.white : Colors.grey,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đánh dấu khẩn cấp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _isUrgent
                                        ? const Color(0xFFE53935)
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bài đăng sẽ được ưu tiên hiển thị lên đầu',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: _isUrgent
                                        ? const Color(
                                            0xFFE53935,
                                          ).withValues(alpha: 0.8)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isUrgent,
                            activeThumbColor: const Color(0xFFE53935),
                            onChanged: (v) => setState(() => _isUrgent = v),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      onPressed: _isSaving ? null : _submit,

                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),

                      label: Text(
                        _isSaving ? 'Đang đăng...' : 'Đăng bài',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownBox() {
    final options = [
      _PostTypeOption(
        status: LostPetStatus.lost,
        icon: Icons.location_searching_rounded,
        color: const Color(0xFFE07B2B),
        bgColor: const Color(0xFFFFF3E6),
        label: 'Thú cưng đang lạc',
        desc: 'Thú cưng của bạn bị mất tích',
      ),
      _PostTypeOption(
        status: LostPetStatus.found,
        icon: Icons.search_rounded,
        color: const Color(0xFF4CAF50),
        bgColor: const Color(0xFFE8F5E9),
        label: 'Tìm thấy thú lạc',
        desc: 'Bạn nhặt/thấy thú cưng thất lạc',
      ),
      _PostTypeOption(
        status: LostPetStatus.injured,
        icon: Icons.healing_rounded,
        color: const Color(0xFFF9A825),
        bgColor: const Color(0xFFFFF8E1),
        label: 'Thú cưng bị thương',
        desc: 'Thú cưng cần được cứu trợ, chữa trị',
      ),
    ];
    return Column(
      children: options.map((opt) {
        final selected = _postStatus == opt.status;
        return GestureDetector(
          onTap: () => setState(() => _postStatus = opt.status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? opt.bgColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? opt.color : Colors.grey.shade300,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? opt.color : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    opt.icon,
                    color: selected ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: selected ? opt.color : Colors.black87,
                        ),
                      ),
                      Text(
                        opt.desc,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: selected
                              ? opt.color.withValues(alpha: 0.75)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: opt.color, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _petTypeBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _kind,
              isExpanded: true,
              items: const [
                DropdownMenuItem<String>(
                  value: _dogKind,
                  child: Text(_dogKind),
                ),
                DropdownMenuItem<String>(
                  value: _catKind,
                  child: Text(_catKind),
                ),
                DropdownMenuItem<String>(
                  value: _otherKindFilter,
                  child: Text(_otherKindFilter),
                ),
              ],
              onChanged: (v) => setState(() => _kind = v!),
            ),
          ),
        ),
        if (_kind == _otherKindFilter) ...[
          const SizedBox(height: 10),
          _field(_otherKindCtrl, 'VD: Thỏ, Hamster, Chim...', required: true),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          filled: true,
          fillColor: const Color(0xFFF7F3EF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        validator:
            validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập $hint'
                      : null
                : null),
      ),
    );
  }

  String? _validateWeight(String? value) {
    final raw = value?.trim().replaceAll(',', '.') ?? '';
    if (raw.isEmpty) return 'Vui lòng nhập cân nặng';
    final weight = double.tryParse(raw);
    if (weight == null || weight <= 0 || weight > 100) {
      return 'Cân nặng phải là số từ 0 đến 100kg';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Vui lòng nhập số điện thoại';
    final compact = raw.replaceAll(RegExp(r'[\s.-]'), '');
    if (!RegExp(r'^(0|\+84)\d{9,10}$').hasMatch(compact)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }
}
