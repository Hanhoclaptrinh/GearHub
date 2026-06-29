# Hướng Dẫn Cài Đặt Và Chạy Dự Án GearHub

Tài liệu này hướng dẫn chi tiết cách cài đặt và khởi chạy các thành phần của hệ thống GearHub gồm: Backend, Admin Frontend và Mobile Client.

---

## Yêu Cầu Trước Khi Cài Đặt

Máy tính cần được cài đặt sẵn các công cụ sau:
- Node.js (phiên bản 18 trở lên)
- Docker và Docker Compose (để chạy database và cache)
- Flutter SDK (phiên bản mới nhất để chạy ứng dụng di động)

---

## 1. Hướng Dẫn Cho Backend

Thư mục hiện tại: `backend`

### Bước 1: Chuyển vào thư mục backend
Mở terminal và chạy lệnh:
```bash
cd backend
```

### Bước 2: Tạo file cấu hình môi trường và dịch vụ bên ngoài
Sao chép file `.env.example` thành file `.env`:
```bash
cp .env.example .env
```
Mở file `.env` lên và cấu hình các thông số sau:

- Cơ sở dữ liệu (Database): Cấu hình DATABASE_URL trỏ đến MySQL (Ví dụ: `mysql://root:password@localhost:3306/gearhub`).
- Dịch vụ gửi Email (SMTP): Điền SMTP_HOST, SMTP_PORT, SMTP_USER và SMTP_PASS (Mật khẩu ứng dụng) để gửi email xác thực.
- Lưu trữ hình ảnh (Cloudinary): Điền CLD_NAME, CLD_API_KEY và CLD_API_SECRET để hỗ trợ tải ảnh sản phẩm lên đám mây.
- Cổng thanh toán (VNPAY): Điền các tham số Sandbox của VNPAY như VNP_TMN_CODE, VNP_HASH_SECRET để thực hiện chức năng thanh toán trực tuyến.
- Google Gemini AI (Tìm kiếm thông minh & RAG): Điền GEMINI_API_KEY, cấu hình GEMINI_CHAT_MODEL và GEMINI_EMBEDDING_MODEL để chạy các kịch bản AI gợi ý sản phẩm.
- Thông báo đẩy (Firebase Admin SDK): Điền FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL và FIREBASE_PRIVATE_KEY để gửi thông báo FCM đến ứng dụng mobile.

### Bước 3: Khởi chạy database và Redis qua Docker
Khởi chạy MySQL và Redis chạy ngầm:
```bash
docker compose up -d
```

### Bước 4: Cài đặt các thư viện phụ thuộc
Chạy lệnh cài đặt các package Node.js:
```bash
npm install
```

### Bước 5: Khởi tạo Prisma Client và Database
Sinh mã nguồn Prisma Client và cập nhật cấu trúc database:
```bash
npx prisma generate
npx prisma db push
```

### Bước 6: Nạp dữ liệu mẫu (Seeding)
Nạp các dữ liệu mẫu ban đầu cho hệ thống:
```bash
npx prisma db seed
```

### Bước 7: Khởi chạy backend
- Chạy trong môi trường phát triển (có tự động cập nhật code):
  ```bash
  npm run dev
  ```
- Build và chạy trong môi trường sản phẩm (production):
  ```bash
  npm run build
  npm run start:prod
  ```

---

## 2. Hướng Dẫn Cho Admin (Giao Diện Web Quản Trị)

Thư mục hiện tại: `frontend/admin`

### Bước 1: Chuyển vào thư mục admin
Mở terminal mới và chạy lệnh:
```bash
cd frontend/admin
```

### Bước 2: Tạo file cấu hình môi trường (tùy chọn)
Tạo file `.env` ở thư mục `frontend/admin` và cấu hình đường dẫn API backend:
```env
VITE_API_URL=http://localhost:3000
```

### Bước 3: Cài đặt các thư viện phụ thuộc
Chạy lệnh:
```bash
npm install
```

### Bước 4: Khởi chạy giao diện admin
- Chạy trong môi trường phát triển:
  ```bash
  npm run dev
  ```
- Build ứng dụng trước khi đưa lên môi trường sản xuất:
  ```bash
  npm run build
  ```
- Xem thử bản build trước khi deploy:
  ```bash
  npm run preview
  ```

---

## 3. Hướng Dẫn Cho Mobile Client (Ứng Dụng Flutter)

Thư mục hiện tại: `frontend/client/mobile`

### Bước 1: Chuyển vào thư mục mobile
Mở terminal mới và chạy lệnh:
```bash
cd frontend/client/mobile
```

### Bước 2: Lấy tất cả các thư viện Flutter phụ thuộc
Chạy lệnh:
```bash
flutter pub get
```

### Bước 3: Sinh code tự động (build_runner)
Sinh các file mã nguồn được tự động tạo (dự án sử dụng các thư viện Freezed, Retrofit, Injectable):
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Bước 4: Khởi chạy ứng dụng Mobile
- Chạy trên thiết bị giả lập hoặc điện thoại thật đã kết nối:
  ```bash
  flutter run
  ```
- Trường hợp điện thoại thật cần kết nối với API backend qua địa chỉ IP cục bộ của máy tính:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://<IP_MAY_TINH_CUA_BAN>:3000
  ```
- Build bản cài đặt chạy trên Android (APK):
  ```bash
  flutter build apk
  ```
- Build bản cài đặt chạy trên iOS:
  ```bash
  flutter build ios
  ```
