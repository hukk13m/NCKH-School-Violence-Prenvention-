# Goong Maps setup

Bản đồ trong `flutter_application_web` và `flutter_application_mobile` dùng
**MapLibre + Goong**. Khi chưa có key, app vẫn chạy với bản đồ nền
**Esri World Street Map** và geocoding Nominatim. Không dùng trực tiếp
`tile.openstreetmap.org` (trả **403 Access blocked**) hoặc CARTO keyless
(hiện watermark **API KEY REQUIRED**) làm tile nền.

Có **2 key khác nhau**, không dùng lẫn:

| Key | Dùng cho | Truyền vào |
| --- | --- | --- |
| Map key | Tải style/tile bản đồ Goong | `--dart-define=GOONG_MAP_KEY=...` khi build/run Flutter |
| REST API key | Autocomplete, Place Detail, Geocode, Direction | Biến môi trường `GOONG_API_KEY` của Django |

Không commit key vào source, `pubspec.yaml`, `index.html` hay file `.env` được
commit. Key chỉ nằm trong lệnh chạy hoặc biến môi trường của máy chủ.

## 1. Lấy key trên Goong

1. Tạo tài khoản/tổ chức tại <https://console.goong.io/>.
2. Bật các sản phẩm **Map** và **Places / Geocoding** nếu tài khoản yêu cầu.
3. Tạo **Map key** cho website (giới hạn domain) và/hoặc mobile app
   (giới hạn package/bundle ID).
4. Tạo **REST API key** cho server Django. Nếu Goong cho phép giới hạn IP,
   giới hạn theo IP máy chủ chạy Django.

Gợi ý giới hạn key:

- Web: chỉ domain thật của trường, ví dụ `https://maps.truong.edu.vn`.
- Mobile: chỉ package `com.example.flutter_application_mobile` (đổi thành
  applicationId thật trước khi phát hành).
- REST: chỉ IP server backend; không đưa REST key xuống Flutter.

## 2. Chạy Django với REST key

PowerShell:

```powershell
$env:GOONG_API_KEY = "rest-key-cua-ban"
.\Django_PostgreSQL\venv\Scripts\python.exe .\Django_PostgreSQL\manage.py runserver
```

Nếu dùng `runserver --noreload`, phải tắt và chạy lại sau khi đổi biến môi
trường. Trên server production, đặt `GOONG_API_KEY` trong systemd/Docker
secret/panel quản trị, **không** đặt trong code.

Kiểm tra nhanh:

```powershell
Invoke-RestMethod "http://127.0.0.1:8000/api/places/autocomplete?input=Dai%20hoc%20Kinh%20te&limit=3"
Invoke-RestMethod "http://127.0.0.1:8000/api/places/reverse?lat=10.7769&lng=106.7009"
```

Response có `"provider": "goong"` là đã dùng key. Nếu vẫn là `"nominatim"`,
kiểm tra lại biến môi trường/khởi động lại Django.

## 3. Chạy Flutter với Map key

Web (Chrome/Edge):

```powershell
cd flutter_application_web
flutter run -d chrome `
  --dart-define=GOONG_MAP_KEY=map-key-cua-ban `
  --dart-define=API_BASE=http://localhost:8000
```

Android emulator:

```powershell
cd flutter_application_mobile
flutter run -d emulator-5554 `
  --dart-define=GOONG_MAP_KEY=map-key-cua-ban `
  --dart-define=API_BASE=http://10.0.2.2:8000
```

Điện thoại thật qua USB (khuyến nghị):

```powershell
adb reverse tcp:8000 tcp:8000
cd flutter_application_mobile
flutter run -d <serial> --dart-define=GOONG_MAP_KEY=map-key-cua-ban
```

Mặc định Android dùng `http://127.0.0.1:8000`, nên không cần truyền
`API_BASE` nếu đã chạy `adb reverse`. Khi rút/cắm lại cáp phải chạy lại
`adb reverse`.

Nếu dùng Wi-Fi/LAN, thay `API_BASE` bằng IP LAN của máy đang chạy Django, ví dụ
`http://192.168.1.10:8000` (điện thoại và máy tính phải cùng mạng).

Build phát hành:

```powershell
flutter build web --dart-define=GOONG_MAP_KEY=... --dart-define=API_BASE=https://api.truong.edu.vn
flutter build apk --release --dart-define=GOONG_MAP_KEY=... --dart-define=API_BASE=https://api.truong.edu.vn
```

Khi có Map key:

- Bản đồ dùng style `goong_map_web.json`.
- Nút đổi **bản đồ thường / vệ tinh** xuất hiện ở góc phải header.
- Không có key: dùng Esri, nút vệ tinh tự ẩn.

## 4. Hành vi fallback

- **Không có `GOONG_MAP_KEY`**: MapLibre tải style Esri raster nội bộ
  (`MapLocationPickerConfig.fallbackStyle`). Chức năng chọn vị trí, kéo bản đồ,
  GPS, tìm kiếm vẫn hoạt động. Không quay lại dùng `tile.openstreetmap.org`
  (403) hoặc CARTO keyless (watermark API KEY REQUIRED).
- **Không có `GOONG_API_KEY`**: Django proxy gọi Nominatim (OSM), có cache
  autocomplete 60 giây, cache reverse/detail 24 giờ, giới hạn 1 request/giây
  và User-Agent nhận diện.
- **Có `GOONG_API_KEY`**: toàn bộ autocomplete/detail/reverse chuyển sang Goong,
  app không cần build lại (trừ khi đổi map key).
- Nếu Goong lỗi/timeout, proxy trả lỗi 502 và app hiển thị thông báo tiếng Việt.

## 5. Kiểm tra sau khi điền key

```powershell
# Backend
cd Django_PostgreSQL
.\venv\Scripts\python.exe manage.py check
.\venv\Scripts\python.exe manage.py migrate

# Flutter
cd ..\packages\map_location_picker
flutter analyze
flutter test

cd ..\..\flutter_application_web
flutter analyze
flutter build web --dart-define=GOONG_MAP_KEY=... --dart-define=API_BASE=http://localhost:8000

cd ..\flutter_application_mobile
flutter analyze
flutter build apk --debug --dart-define=GOONG_MAP_KEY=... --dart-define=API_BASE=http://10.0.2.2:8000
```

Mở app, bấm **chọn vị trí trên bản đồ**, thử:

1. Kéo bản đồ → địa chỉ tự cập nhật.
2. Gõ địa chỉ → chọn gợi ý → ghim nhảy đúng vị trí.
3. Bấm **Vị trí GPS** → cấp quyền vị trí.
4. (Có Map key) bấm nút vệ tinh → đổi style.
5. Bấm **Xác nhận** → toạ độ được gửi kèm báo cáo/SOS.

## 6. Lưu ý kỹ thuật

- MapLibre chỉ hỗ trợ Android/iOS/Web. **Không chạy app trên Windows desktop**;
  dùng Chrome/Edge.
- Web cần WebGL2 (Chrome/Edge hiện đại).
- iOS deployment target đã nâng lên 14.0 (yêu cầu của `file_picker` 13).
- Android đã thêm `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`; iOS đã có
  `NSLocationWhenInUseUsageDescription`.
- Báo cáo SOS được lưu vào bảng `cases_case` với `latitude`/`longitude`
  (kiểu `FloatField`), `location`, `report_type=SOS`, `priority=High`.
  Endpoint `POST /api/cases/create/` nhận cả JSON và multipart; danh sách
  `GET /api/cases/list/` trả lại tọa độ để hiển thị trên bản đồ.
- Backend endpoints mới:
  - `GET /api/places/autocomplete?input=...&limit=5`
  - `GET /api/places/detail?place_id=...`
  - `GET /api/places/reverse?lat=...&lng=...`
- Goong REST key hỗ trợ **Direction** (quãng đường/thời gian/polyline), nhưng
  proxy hiện chỉ mở 3 endpoint địa chỉ ở trên. Có thể gọi trực tiếp từ server
  bằng REST key; không đưa key xuống app.
- Goong chặn `User-Agent` mặc định của Python (`Python-urllib/...`) bằng 403.
  `cases/places.py` phải gửi User-Agent rõ ràng cho cả Goong và Nominatim.
- Mã nguồn proxy: `Django_PostgreSQL/cases/places.py`.
- Cấu hình style: `packages/map_location_picker/lib/src/config/map_config.dart`.
