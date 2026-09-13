# Rodent Control Customer App

Ứng dụng dành cho công ty khách hàng. Mỗi công ty có một tài khoản quản lý; đăng nhập bắt buộc qua mật khẩu + OTP email.

## Cấu hình API
Sửa `app/build.gradle`:
`buildConfigField 'String','API_BASE_URL','"https://foodkcn.com/api/"'`

## Luồng
Login → OTP email → Dashboard → Sites → Site detail / Reports / Incidents.

Token được lưu bằng Android EncryptedSharedPreferences. Không hard-code tài khoản, mật khẩu hoặc token.
