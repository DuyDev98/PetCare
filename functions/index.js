const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Hàm tính khoảng cách giữa 2 tọa độ (Haversine Formula)
 * Trả về khoảng cách tính bằng km
 */
function getDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Bán kính Trái đất
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

/**
 * Trigger khi có document mới trong collection 'lost_pets'
 * Quét các user trong bán kính 3km và gửi push notification
 */
exports.onLostPetCreated = functions.firestore
    .document('lost_pets/{petId}')
    .onCreate(async (snap, context) => {
        const newValue = snap.data();
        const petLocation = newValue.location; // Kì vọng là GeoPoint
        const petName = newValue.name || "thú cưng";

        if (!petLocation) {
            console.log("Không có thông tin tọa độ cho bài đăng lạc thú.");
            return null;
        }

        const lat1 = petLocation.latitude;
        const lon1 = petLocation.longitude;

        try {
            // Lấy tất cả user có FCM Token
            // Lưu ý: Với hệ thống lớn, nên dùng GeoFirestore để query tối ưu hơn
            const usersSnapshot = await admin.firestore().collection('users')
                .where('fcmToken', '!=', null)
                .get();

            const tokens = [];
            usersSnapshot.forEach(doc => {
                const userData = doc.data();
                const userLocation = userData.location;

                if (userLocation) {
                    const lat2 = userLocation.latitude;
                    const lon2 = userLocation.longitude;
                    const distance = getDistance(lat1, lon1, lat2, lon2);

                    // Nếu khoảng cách <= 3km
                    if (distance <= 3) {
                        tokens.push(userData.fcmToken);
                    }
                }
            });

            if (tokens.length > 0) {
                const message = {
                    notification: {
                        title: '⚠️ Có thú lạc gần bạn!',
                        body: `Bé ${petName} vừa được báo lạc trong vòng bán kính 3km từ vị trí của bạn. Hãy giúp đỡ nhé!`,
                    },
                    tokens: tokens,
                };

                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`Đã gửi thông báo thành công cho ${response.successCount} người dùng.`);
            } else {
                console.log("Không tìm thấy người dùng nào trong bán kính 3km.");
            }
        } catch (error) {
            console.error("Lỗi khi xử lý thông báo thú lạc:", error);
        }

        return null;
    });
