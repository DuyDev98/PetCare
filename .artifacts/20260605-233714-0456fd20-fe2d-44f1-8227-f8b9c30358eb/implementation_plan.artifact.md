# Cập nhật tính năng xem lại ảnh (Locket style) cho PetCare

Dưới đây là kế hoạch chi tiết để cập nhật và hoàn thiện tính năng xem lại ảnh, bao gồm màn hình lưới, màn hình chi tiết và logic xóa ảnh dứt điểm.

## Proposed Changes

### 1. Data Layer (Models & Services)

#### [pet_photo_model.dart](file:///C:/Users/Owner/PetCare/lib/data/models/pet_photo_model.dart)
- Cập nhật model để bao gồm trường `createdAt` giúp sắp xếp ảnh chính xác.

#### [pet_photo_service.dart](file:///C:/Users/Owner/PetCare/lib/data/services/pet_photo_service.dart)
- Thêm hàm `getUserPhotosStream()` để lắng nghe realtime danh sách ảnh của user hiện tại.
- Thêm hàm `deletePetPhoto(String docId)` để xóa document trên Firestore.

#### [cloudinary_service.dart](file:///C:/Users/Owner/PetCare/lib/data/services/cloudinary_service.dart)
- Thêm hàm `deleteImage(String imageUrl)` để xóa ảnh trên Cloudinary.
- Hàm này sẽ bao gồm logic trích xuất `public_id` từ URL và gọi API xóa của Cloudinary (cần API Key/Secret).

---

### 2. UI Layer (Screens)

#### [NEW] [photo_history_screen.dart](file:///C:/Users/Owner/PetCare/lib/features/photo_history/screens/photo_history_screen.dart)
- Màn hình lưới ảnh (3 cột) sử dụng `StreamBuilder`.
- Sử dụng `CachedNetworkImage` để hiển thị ảnh.
- Hiệu ứng `Hero` khi nhấn vào ảnh.

#### [NEW] [photo_detail_screen.dart](file:///C:/Users/Owner/PetCare/lib/features/photo_history/screens/photo_detail_screen.dart)
- Màn hình xem chi tiết ảnh với nền đen.
- Nút xóa ở góc trên bên phải.
- Dialog xác nhận xóa và logic gọi Service để xóa dữ liệu.

## Verification Plan

### Automated Tests
- Vì đây là thay đổi UI và Firebase, tôi sẽ tập trung vào kiểm tra thủ công.

### Manual Verification
1. **Kiểm tra hiển thị**: Mở màn hình Lịch sử ảnh, xác nhận ảnh hiển thị đúng lưới 3 cột, sắp xếp mới nhất lên đầu.
2. **Kiểm tra Realtime**: Thêm một ảnh mới (từ phần khác của app nếu có) và xác nhận nó tự động xuất hiện trong lưới.
3. **Kiểm tra Xem chi tiết**: Nhấn vào ảnh, xác nhận hiệu ứng Hero mượt mà và ảnh hiển thị chính giữa.
4. **Kiểm tra Xóa**:
   - Nhấn nút xóa, xác nhận Dialog xuất hiện.
   - Chọn "Hủy", xác nhận ảnh không bị xóa.
   - Chọn "Xóa", xác nhận SnackBar thông báo thành công, quay về màn hình lưới và ảnh đã biến mất.
   - Kiểm tra trên Firestore Console xem document đã bị xóa chưa.
   - Kiểm tra trên Cloudinary Console xem file đã bị xóa chưa (sau khi đã điền đủ credentials).
