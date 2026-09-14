# KSC App — App Nhân viên (Flutter)

App di động cho nhân viên KSC/GFC: nhận việc, bắt đầu (ghi GPS), ghi kết quả từng điểm kiểm
soát, chụp & tải ảnh bằng chứng, khách hàng xác nhận, hoàn thành công việc. Gọi thẳng vào
`api/` đã có sẵn trên `ksc.foodkcn.com` (không cần sửa gì ở backend).

**Kiểm soát QR trên hộp bẫy:** mỗi hộp bẫy/trạm bả ngoài hiện trường được Web Admin cấp 1
mã QR riêng (in tem tại `admin/zone-form.php` → mục điểm kiểm soát). Trong app, nhân viên có
thể quét QR để mở thẳng đúng điểm kiểm soát (nút "Quét QR" ở màn hình chi tiết công việc), và
với các điểm đã có QR thì **bắt buộc quét đúng mã** trước khi được lưu kết quả lần đầu — nhằm
đảm bảo nhân viên thực sự có mặt tại đúng vị trí (xem `lib/screens/qr_scan_screen.dart`,
`lib/screens/checkpoint_screen.dart`). Nếu tem QR bị mờ/hỏng, có thể bấm "Nhập mã tay" và gõ
đúng mã in bên dưới tem.

**Hoạt động offline:** mọi thao tác ghi (nhận việc/bắt đầu/ghi kết quả/tải ảnh/xác nhận/hoàn
thành) đều lưu trước vào máy; nếu đang mất mạng, thao tác được xếp vào hàng đợi và **tự động
gửi lại theo đúng thứ tự** khi điện thoại có mạng trở lại (xem `lib/services/sync_service.dart`).
Riêng thao tác "Quét QR để mở điểm" (tra cứu theo mã) cần có mạng vì phải xác thực với server;
việc ghi kết quả sau đó vẫn hoạt động offline như bình thường.

## Trước khi build: đổi đúng domain của bạn

Mở `lib/core/api_config.dart`, kiểm tra đúng domain:

```dart
const String kApiBaseUrl = 'https://ksc.foodkcn.com/api';
const String kMediaBaseUrl = 'https://ksc.foodkcn.com';
```

## Build APK bằng GitHub (không cần cài Flutter ở máy)

1. Tạo 1 repo GitHub mới (public hoặc private đều được), rồi đẩy toàn bộ thư mục này lên:
   ```bash
   git init
   git add .
   git commit -m "KSC app nhân viên"
   git branch -M main
   git remote add origin https://github.com/<tài-khoản-github-của-bạn>/ksc_app.git
   git push -u origin main
   ```
2. Vào tab **Actions** trên GitHub repo → workflow **"Build APK"** sẽ tự chạy sau khi push.
   Nếu muốn chạy lại thủ công, bấm **Run workflow**.
3. Chờ khoảng 5–8 phút, workflow sẽ:
   - Tự sinh phần code Android (`flutter create --platforms=android`) vì repo chỉ chứa code
     Dart dùng chung, không commit sẵn thư mục `android/` để tránh xung đột.
   - Tự thêm các quyền cần thiết vào `AndroidManifest.xml` (Internet, Camera, GPS).
   - Build APK bản release.
4. Vào job vừa chạy xong → mục **Artifacts** ở cuối trang → tải file `ksc-app-apk.zip` →
   giải nén ra được `app-release.apk`.
5. Copy file `.apk` vào điện thoại Android, mở lên cài (cần bật **"Cài đặt ứng dụng không rõ
   nguồn gốc"** trong Cài đặt Android cho trình quản lý file/Zalo bạn dùng để mở file đó).

## Lưu ý quan trọng

- APK build ra ở bước trên được ký bằng **debug key mặc định của Flutter** — dùng để cài thử
  nội bộ cho nhân viên là ổn, nhưng **không dùng để đăng lên Google Play** (Play Store yêu cầu
  key ký riêng của bạn). Khi nào cần đăng Play Store, báo mình để hướng dẫn tạo keystore riêng
  và cập nhật `android/app/build.gradle`.
- App hiện chỉ build cho Android. Nếu sau này cần bản iOS, sẽ cần máy Mac + tài khoản Apple
  Developer (GitHub Actions có thể build iOS trên máy ảo macOS nhưng cần cấu hình ký (signing)
  phức tạp hơn nhiều so với Android).
- Tài khoản đăng nhập App dùng đúng **mã nhân viên hoặc số điện thoại** + mật khẩu đã tạo trong
  Web Admin (`admin/employee-form.php`), không phải tài khoản admin.

## Cấu trúc code

```
lib/
├── main.dart
├── core/            # cấu hình API, quản lý phiên đăng nhập, DB offline
├── models/          # Employee, Job, JobPoint
├── services/        # AuthService, JobService (gọi API + cache/queue), SyncService
├── screens/         # LoginScreen, JobListScreen, JobDetailScreen, CheckpointScreen, QrScanScreen
└── widgets/         # StatusBadge
```

## Chạy thử trên máy có cài Flutter (không bắt buộc)

```bash
flutter pub get
flutter run
```
