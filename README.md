# Rodent Control Customer App

Ứng dụng dành cho công ty khách hàng. Mỗi công ty có một tài khoản quản lý; đăng nhập bằng tài khoản + mật khẩu; quên mật khẩu dùng mã 6 số gửi tới email đã đăng ký.

## Cấu hình API
Sửa `app/build.gradle`:
`buildConfigField 'String','API_BASE_URL','"https://foodkcn.com/api/"'`

## Luồng
Login → OTP email → Dashboard → Sites → Site detail / Reports / Incidents.

Token được lưu bằng Android EncryptedSharedPreferences. Không hard-code tài khoản, mật khẩu hoặc token.
