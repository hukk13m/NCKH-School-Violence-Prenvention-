# Tổng Quan Dự Án & Kế Hoạch Demo: Hệ Thống Phát Hiện Bạo Lực Học Đường 
*(School Violation Detection System)*

---

## 1. Tổng Quan Dự Án
Hệ thống là một nền tảng công nghệ hỗ trợ ngăn chặn bạo lực học đường thông qua việc kết hợp các công cụ báo cáo an toàn và quy trình đánh giá rủi ro tự động. 

**Mục tiêu cốt lõi:**
*   **Tiếp nhận thông tin:** Cung cấp kênh báo cáo trực quan cho học sinh và giáo viên, cho phép đính kèm bằng chứng cụ thể.
*   **Đánh giá tự động (AI Pipeline):** Ứng dụng các mô hình học máy (như phân tích ngôn từ thù ghét/độc hại qua tập dữ liệu ViHSD) để tự động sàng lọc, phân tích tính chất nghiêm trọng của vụ việc và đưa ra điểm rủi ro (risk score).
*   **Quản lý quy trình (BPMN):** Chuẩn hóa luồng xử lý vụ việc từ lúc tiếp nhận, AI phân tích, kiểm duyệt, cho đến khi phân công giải quyết và đóng hồ sơ.

---

## 2. Cấu Trúc Dữ Liệu (Dựa trên ERD)
Hệ thống được thiết kế chặt chẽ trên cơ sở dữ liệu quan hệ (PostgreSQL) với các luồng thực thể chính:

*   **Quản lý Người dùng & Danh mục:** Bảng `USER` (mở rộng quyền hạn) liên kết với `ROLE` (Vai trò), `DEPARTMENT` (Phòng ban), và `CLASS` (Lớp học).
*   **Hồ sơ Vụ việc & Bằng chứng:** Bảng `CASE` (lưu trữ thông tin vụ việc, trạng thái, độ ưu tiên) là trung tâm, liên kết trực tiếp với bảng `EVIDENCE` (hình ảnh, tài liệu chứng minh).
*   **Phân tích & Kiểm duyệt:** Bảng `AI_RESULT` lưu kết quả từ AI (điểm rủi ro, đề xuất). Bảng `AUDIT` lưu lại nhận xét và quyết định của người quản trị đối với kết quả của AI.
*   **Giao tiếp & Theo dõi:** Tích hợp `CHAT_ROOM` / `MESSAGE` cho việc trao đổi trực tiếp và `CASE_HISTORY` để truy vết mọi thao tác trên hồ sơ.

---

## 3. Định Hướng Thực Hiện Demo (Django + PostgreSQL)
Trọng tâm của bản demo là **bỏ qua sự phức tạp của Frontend** để tập trung xây dựng logic Backend vững chắc. Hệ thống sẽ tận dụng tối đa sức mạnh của **Django ORM** và **Django Admin** để biến thành một Dashboard kiểm duyệt hoàn chỉnh.

### Lợi ích của phương pháp này:
*   **Django ORM:** Đóng vai trò phiên dịch tự động. Bạn chỉ cần định nghĩa các class Python theo ERD, ORM sẽ tự động tạo bảng, thiết lập khóa ngoại và truy vấn dữ liệu từ PostgreSQL mà không cần viết lệnh SQL thủ công.
*   **Django Admin:** Tự động sinh ra giao diện CRUD (Tạo, Đọc, Cập nhật, Xóa). Bằng cách tùy biến file `admin.py`, bạn có thể tạo ngay một trang làm việc cho đội ngũ kiểm duyệt với các tính năng lọc vụ việc ưu tiên cao, tìm kiếm theo trạng thái và xem bằng chứng ngay trên một trang.

---

## 4. Lộ Trình Triển Khai

### Giai đoạn 1: Thiết lập Môi trường
*   Cài đặt Python, tạo Virtual Environment.
*   Cài đặt PostgreSQL & pgAdmin 4, tạo cơ sở dữ liệu `violation_db`.
*   Cài đặt thư viện: `pip install django psycopg2-binary Pillow`.
*   Khởi tạo Project và App, cấu hình `DATABASES` trong `settings.py`.

### Giai đoạn 2: Ánh xạ ERD thành Code (`models.py`)
*   Viết code định nghĩa các lớp: `User`, `Department`, `Class`.
*   Viết code định nghĩa luồng sự kiện: `Case`, `Evidence`, `AI_Result`, `Audit`, `Assignment`.
*   Chạy `makemigrations` và `migrate` để PostgreSQL tạo bảng.

### Giai đoạn 3: Tùy biến Giao diện Kiểm duyệt (`admin.py`)
*   Đăng ký các Model vào trang quản trị.
*   Cấu hình `list_display` (hiển thị cột ID, Trạng thái, Độ ưu tiên).
*   Cấu hình `list_filter` (bộ lọc tìm kiếm các vụ việc có rủi ro cao).
*   Sử dụng `admin.TabularInline` để gắn trực tiếp ảnh bằng chứng (`Evidence`) vào trang chi tiết vụ việc (`Case`).

### Giai đoạn 4: Vận hành Thử nghiệm
*   Tạo tài khoản quản trị: `python manage.py createsuperuser`.
*   Chạy server: `python manage.py runserver`.
*   Thêm dữ liệu giả lập (mock data) để kiểm tra luồng phân tích rủi ro và quản lý trạng thái vụ việc.