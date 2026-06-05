part of '../../screens/lost_pet_screen.dart';

class _GridCard extends StatelessWidget {
  final LostPetPost post;
  const _GridCard({required this.post});

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _LostPetDetailScreen(post: post)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + badge ──
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.05,
                  child: post.imageUrl.isNotEmpty
                      ? Image.network(
                          post.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
                if (post.isUrgent)
                  Positioned(top: 6, left: 6, child: _UrgentBadge()),
                // Status label bottom-right of image
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: _StatusChip(status: post.status),
                ),
              ],
            ),
            // ── Info ──
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tên: ${post.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Giống: ${post.breed}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Cân nặng: ${post.weight.toStringAsFixed(1)}kg',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    DateFormat('dd/MM/yyyy').format(post.createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 11,
                        color: Color(0xFFE07B2B),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          post.locationName,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFE07B2B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _relativeTime(post.createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFF5E6D3),
      child: const Center(
        child: Icon(Icons.pets_rounded, size: 48, color: Color(0xFFE07B2B)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final LostPetPost post;
  const _ListCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _LostPetDetailScreen(post: post)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    post.imageUrl.isNotEmpty
                        ? Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                    if (post.isUrgent)
                      Positioned(top: 6, left: 6, child: _UrgentBadge()),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusChip(status: post.status),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy').format(post.createdAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Tên: ${post.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Giống: ${post.breed}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      post.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Color(0xFFE07B2B),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            post.locationName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFE07B2B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Cân nặng: ${post.weight.toStringAsFixed(1)}kg',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFF5E6D3),
    child: const Center(
      child: Icon(Icons.pets_rounded, size: 36, color: Color(0xFFE07B2B)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
