part of '../../screens/lost_pet_screen.dart';

class _LostPetDetailScreen extends StatefulWidget {
  final LostPetPost post;
  const _LostPetDetailScreen({required this.post});

  @override
  State<_LostPetDetailScreen> createState() => _LostPetDetailScreenState();
}

class _LostPetDetailScreenState extends State<_LostPetDetailScreen> {
  static const _orange = Color(0xFFE07B2B);
  static const _green = Color(0xFF4CAF50);

  bool _isUpdating = false;
  late LostPetStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.post.status;
  }

  bool get _isOwner =>
      FirebaseAuth.instance.currentUser?.uid == widget.post.userId;

  String get _viewerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  String _normalizedPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s.-]'), '');
  }

  Future<void> _launchPhone(String phone) async {
    final normalized = _normalizedPhone(phone);
    if (normalized.isEmpty) {
      _showSnack('Bài đăng chưa có số điện thoại liên hệ.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: normalized);
    if (!await launchUrl(uri)) {
      _showSnack('Không mở được trình gọi điện trên thiết bị này.');
    }
  }

  Future<void> _sendSms(String phone, LostPetPost post) async {
    final normalized = _normalizedPhone(phone);
    if (normalized.isEmpty) {
      _showSnack('Bài đăng chưa có số điện thoại liên hệ.');
      return;
    }
    final uri = Uri(
      scheme: 'sms',
      path: normalized,
      queryParameters: {
        'body':
            'Chào bạn, mình thấy tin "${post.name}" trên PetCare. Mình muốn trao đổi thêm thông tin.',
      },
    );
    if (!await launchUrl(uri)) {
      _showSnack('Không mở được ứng dụng nhắn tin trên thiết bị này.');
    }
  }

  Future<void> _copyShareText(LostPetPost post) async {
    final text = [
      'PetCare - ${_statusLabel(post.status)}: ${post.name}',
      if (post.breed.isNotEmpty) 'Giống: ${post.breed}',
      if (post.locationName.isNotEmpty) 'Vị trí: ${post.locationName}',
      if (post.phone.isNotEmpty) 'Liên hệ: ${post.phone}',
      if (post.description.isNotEmpty) 'Mô tả: ${post.description}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    _showSnack('Đã sao chép nội dung bài đăng để chia sẻ.');
  }

  Future<void> _reportPost(LostPetPost post) async {
    final reporterId = _viewerId;
    if (reporterId.isEmpty) {
      _showSnack('Bạn cần đăng nhập để báo cáo bài đăng.');
      return;
    }

    final reason = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Báo cáo bài đăng',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _reportTile('Thông tin sai hoặc gây hiểu nhầm'),
              _reportTile('Không liên hệ được chủ bài'),
              _reportTile('Nội dung spam / không phù hợp'),
            ],
          ),
        ),
      ),
    );
    if (reason == null) return;

    setState(() => _isUpdating = true);
    try {
      await LostPetService.reportPost(
        post: post,
        reason: reason,
        reporterId: reporterId,
      );
      _showSnack('Đã gửi báo cáo. PetCare sẽ kiểm tra bài đăng này.');
    } catch (e) {
      _showSnack('Lỗi khi gửi báo cáo: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _reportTile(String reason) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.flag_outlined, color: _orange),
      title: Text(reason),
      onTap: () => Navigator.pop(context, reason),
    );
  }

  Future<void> _toggleClosed(LostPetPost post) async {
    final willClose = !post.isClosed;
    final confirm = await _confirm(
      title: willClose ? 'Đóng bài đăng?' : 'Mở lại bài đăng?',
      content: willClose
          ? 'Bài đăng sẽ ẩn khỏi danh sách công khai nhưng bạn vẫn có thể mở lại.'
          : 'Bài đăng sẽ hiển thị lại trong danh sách tìm kiếm.',
      actionLabel: willClose ? 'Đóng bài' : 'Mở lại',
      actionColor: willClose ? Colors.black87 : _green,
    );
    if (!confirm) return;

    await _runOwnerAction(
      () => LostPetService.setClosed(post.id, willClose),
      willClose ? 'Đã đóng bài đăng.' : 'Đã mở lại bài đăng.',
    );
  }

  Future<void> _deletePost(LostPetPost post) async {
    final confirm = await _confirm(
      title: 'Xoá bài đăng?',
      content: 'Thao tác này không thể hoàn tác.',
      actionLabel: 'Xoá',
      actionColor: const Color(0xFFE53935),
    );
    if (!confirm) return;

    await _runOwnerAction(
      () => LostPetService.deletePost(post.id),
      'Đã xoá bài đăng.',
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _runOwnerAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isUpdating = true);
    try {
      await action();
      _showSnack(successMessage);
    } catch (e) {
      _showSnack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String content,
    required String actionLabel,
    required Color actionColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              actionLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(LostPetStatus status) {
    switch (status) {
      case LostPetStatus.found:
        return 'Tìm thấy';
      case LostPetStatus.injured:
        return 'Bị thương';
      case LostPetStatus.lost:
        return 'Đang lạc';
    }
  }

  Future<void> _markAsFound() async {
    await _changeStatus(
      LostPetStatus.found,
      dialogTitle: 'Xác nhận tìm thấy',
      dialogContent:
          'Bạn xác nhận đã tìm thấy "${widget.post.name}"?\nBài đăng sẽ chuyển sang "Đã tìm thấy".',
      snackMsg: '🎉 Đã cập nhật: Tìm thấy thú cưng!',
      snackColor: const Color(0xFF4CAF50),
    );
  }

  Future<void> _markAsRescued() async {
    await _changeStatus(
      LostPetStatus.found,
      dialogTitle: 'Xác nhận đã cứu trợ',
      dialogContent:
          'Bạn xác nhận thú cưng bị thương "${widget.post.name}" đã được cứu trợ / chữa trị xong?',
      snackMsg: '💚 Đã cập nhật: Thú cưng đã được cứu trợ!',
      snackColor: const Color(0xFF4CAF50),
    );
  }

  Future<void> _changeStatus(
    LostPetStatus newStatus, {
    required String dialogTitle,
    required String dialogContent,
    required String snackMsg,
    required Color snackColor,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await LostPetService.updateStatus(widget.post.id, newStatus);
      setState(() => _currentStatus = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snackMsg), backgroundColor: snackColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      body: StreamBuilder<LostPetPost?>(
        stream: LostPetService.postStream(widget.post.id),
        builder: (context, snapshot) {
          final post = snapshot.data ?? widget.post;
          if (!_isUpdating) _currentStatus = post.status;
          final isResolved = _currentStatus == LostPetStatus.found;
          final isInjured = _currentStatus == LostPetStatus.injured;

          if (snapshot.connectionState != ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: Text('Bài đăng không còn tồn tại.'));
          }

          return CustomScrollView(
            slivers: [
              // ── Hero image app bar ──
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: const Color(0xFFFAF7F4),
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      post.imageUrl.isNotEmpty
                          ? Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                      // gradient overlay bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (post.isUrgent)
                        Positioned(top: 16, right: 16, child: _UrgentBadge()),
                      Positioned(
                        bottom: 12,
                        left: 16,
                        child: _StatusChip(status: _currentStatus),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + date row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              post.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(post.createdAt),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Info grid
                      _infoGrid(post),

                      const SizedBox(height: 20),

                      // Location
                      _sectionTitle('Vị trí thất lạc'),
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.location_on_rounded,
                        post.locationName.isNotEmpty
                            ? post.locationName
                            : 'Chưa cung cấp',
                        color: _orange,
                      ),

                      const SizedBox(height: 20),

                      // Description
                      if (post.description.isNotEmpty) ...[
                        _sectionTitle('Mô tả đặc điểm'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Text(
                            post.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Contact
                      _sectionTitle('Thông tin liên hệ'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: _orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              post.phone.isNotEmpty
                                  ? post.phone
                                  : 'Chưa cung cấp',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: post.phone.isNotEmpty
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (!_isOwner) _buildViewerActions(post),

                      if (post.isClosed) ...[
                        const SizedBox(height: 16),
                        _closedBanner(),
                      ],

                      const SizedBox(height: 20),

                      // ── Action button (chỉ chủ bài) ──
                      if (_isOwner)
                        _buildOwnerPanel(post, isResolved, isInjured),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewerActions(LostPetPost post) {
    final hasPhone = post.phone.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _detailActionButton(
                icon: Icons.call_rounded,
                label: 'Gọi ngay',
                color: _green,
                enabled: hasPhone && !post.isClosed,
                onTap: () => _launchPhone(post.phone),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailActionButton(
                icon: Icons.sms_rounded,
                label: 'Nhắn tin',
                color: _orange,
                enabled: hasPhone && !post.isClosed,
                onTap: () => _sendSms(post.phone, post),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _secondaryActionButton(
                icon: Icons.ios_share_rounded,
                label: 'Sao chép tin',
                onTap: () => _copyShareText(post),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _secondaryActionButton(
                icon: Icons.flag_outlined,
                label: 'Báo cáo',
                onTap: _isUpdating ? null : () => _reportPost(post),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _closedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Colors.black54),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bài đăng đã đóng. Thông tin chỉ còn để đối chiếu.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerPanel(LostPetPost post, bool isResolved, bool isInjured) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý bài đăng',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildOwnerButton(isResolved, isInjured),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _secondaryActionButton(
                  icon: Icons.edit_location_alt_rounded,
                  label: 'Sửa tin',
                  onTap: _isUpdating ? null : () => _showEditSheet(post),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _secondaryActionButton(
                  icon: post.isClosed
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  label: post.isClosed ? 'Mở lại' : 'Đóng bài',
                  onTap: _isUpdating ? null : () => _toggleClosed(post),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _secondaryActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Xoá bài đăng',
            color: const Color(0xFFE53935),
            onTap: _isUpdating ? null : () => _deletePost(post),
          ),
        ],
      ),
    );
  }

  Widget _detailActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, color: Colors.white, size: 19),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _secondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.black87,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: color.withValues(alpha: 0.04),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  void _showEditSheet(LostPetPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditPostSheet(
        post: post,
        onSaved: () => _showSnack('Đã cập nhật bài đăng.'),
      ),
    );
  }

  Widget _buildOwnerButton(bool isResolved, bool isInjured) {
    // Đã xử lý xong (found) → banner xanh tĩnh
    if (isResolved) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _green),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: _green, size: 22),
            SizedBox(width: 8),
            Text(
              'Đã xử lý xong 🎉',
              style: TextStyle(
                color: _green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    // Thú bị thương → nút "Đã cứu trợ / chữa trị xong"
    if (isInjured) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF9A825),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isUpdating ? null : _markAsRescued,
          icon: _isUpdating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.healing_rounded, color: Colors.white),
          label: Text(
            _isUpdating ? 'Đang cập nhật...' : 'Đánh dấu đã cứu trợ xong',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    // Thú đang lạc → nút "Đã tìm thấy"
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _isUpdating ? null : _markAsFound,
        icon: _isUpdating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.pets_rounded, color: Colors.white),
        label: Text(
          _isUpdating ? 'Đang cập nhật...' : 'Đánh dấu đã tìm thấy',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    ),
  );

  Widget _infoRow(IconData icon, String text, {Color color = Colors.black87}) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: color)),
        ),
      ],
    );
  }

  Widget _infoGrid(LostPetPost post) {
    final items = [
      _InfoItem(icon: Icons.category_rounded, label: 'Loại', value: post.kind),
      _InfoItem(
        icon: Icons.pets_rounded,
        label: 'Giống',
        value: post.breed.isNotEmpty ? post.breed : '–',
      ),
      _InfoItem(
        icon: Icons.monitor_weight_rounded,
        label: 'Cân nặng',
        value: post.weight > 0 ? '${post.weight.toStringAsFixed(1)} kg' : '–',
      ),
      _InfoItem(
        icon: Icons.access_time_rounded,
        label: 'Đăng lúc',
        value: DateFormat('HH:mm – dd/MM/yyyy').format(post.createdAt),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: _orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFF5E6D3),
    child: const Center(
      child: Icon(Icons.pets_rounded, size: 72, color: Color(0xFFE07B2B)),
    ),
  );
}

class _EditPostSheet extends StatefulWidget {
  final LostPetPost post;
  final VoidCallback onSaved;

  const _EditPostSheet({required this.post, required this.onSaved});

  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _otherKindCtrl;
  late String _kind;
  late LostPetStatus _status;
  late bool _isUrgent;
  bool _isSaving = false;

  static const _orange = Color(0xFFE07B2B);

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _nameCtrl = TextEditingController(text: post.name);
    _breedCtrl = TextEditingController(text: post.breed);
    _descCtrl = TextEditingController(text: post.description);
    _weightCtrl = TextEditingController(
      text: post.weight > 0 ? post.weight.toStringAsFixed(1) : '',
    );
    _phoneCtrl = TextEditingController(text: post.phone);
    _locCtrl = TextEditingController(text: post.locationName);
    _kind = post.kind == _dogKind || post.kind == _catKind
        ? post.kind
        : _otherKindFilter;
    _otherKindCtrl = TextEditingController(
      text: _kind == _otherKindFilter ? post.kind : '',
    );
    _status = post.status;
    _isUrgent = post.isUrgent;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _descCtrl.dispose();
    _weightCtrl.dispose();
    _phoneCtrl.dispose();
    _locCtrl.dispose();
    _otherKindCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final kindValue = _kind == _otherKindFilter
          ? _otherKindCtrl.text.trim()
          : _kind;
      await LostPetService.updatePost(
        widget.post.id,
        name: _nameCtrl.text.trim(),
        kind: kindValue,
        breed: _breedCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        weight: double.parse(_weightCtrl.text.trim().replaceAll(',', '.')),
        locationName: _locCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        status: _status,
        isUrgent: _isUrgent,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Sửa bài đăng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _statusSelector(),
                const SizedBox(height: 14),
                _kindSelector(),
                const SizedBox(height: 12),
                _field(_nameCtrl, 'Tên thú cưng', required: true),
                _field(_breedCtrl, 'Giống', required: true),
                _field(_locCtrl, 'Vị trí', required: true),
                _field(_descCtrl, 'Mô tả', maxLines: 3),
                _field(
                  _weightCtrl,
                  'Cân nặng (kg)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateWeight,
                ),
                _field(
                  _phoneCtrl,
                  'Số điện thoại',
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isUrgent,
                  activeThumbColor: const Color(0xFFE53935),
                  title: const Text(
                    'Ưu tiên khẩn cấp',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onChanged: (value) => setState(() => _isUrgent = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                      style: const TextStyle(
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
    );
  }

  Widget _statusSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statusChip('Đang lạc', LostPetStatus.lost, _orange),
        _statusChip('Tìm thấy', LostPetStatus.found, const Color(0xFF4CAF50)),
        _statusChip(
          'Bị thương',
          LostPetStatus.injured,
          const Color(0xFFF9A825),
        ),
      ],
    );
  }

  Widget _statusChip(String label, LostPetStatus status, Color color) {
    final selected = _status == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.16),
      side: BorderSide(color: selected ? color : Colors.grey.shade300),
      labelStyle: TextStyle(
        color: selected ? color : Colors.black54,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (_) => setState(() => _status = status),
    );
  }

  Widget _kindSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _kind,
          decoration: _inputDecoration('Loài'),
          items: const [
            DropdownMenuItem(value: _dogKind, child: Text(_dogKind)),
            DropdownMenuItem(value: _catKind, child: Text(_catKind)),
            DropdownMenuItem(
              value: _otherKindFilter,
              child: Text(_otherKindFilter),
            ),
          ],
          onChanged: (value) => setState(() => _kind = value ?? _dogKind),
        ),
        if (_kind == _otherKindFilter) ...[
          const SizedBox(height: 10),
          _field(_otherKindCtrl, 'Tên loài khác', required: true),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
        validator:
            validator ??
            (required
                ? (value) => (value == null || value.trim().isEmpty)
                      ? 'Vui lòng nhập $label'
                      : null
                : null),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F3EF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
