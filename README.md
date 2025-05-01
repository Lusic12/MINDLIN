# Phân Tích Tấm Mindlin Bằng Phương Pháp Phần Tử Hữu Hạn (FEM) – MATLAB

**Mindlin-Plate-Analysis** là thư viện MATLAB mạnh mẽ để phân tích tấm dày (theo lý thuyết Mindlin/Reissner), hỗ trợ các bài toán tĩnh, ổn định (buckling) và dao động tự do. Với giao diện đồ họa trực quan và khả năng chạy trên **MATLAB Online**, công cụ này lý tưởng cho cả người mới bắt đầu và chuyên gia phân tích kết cấu.

---

## 🌟 Tính Năng Nổi Bật
- **Phân tích tĩnh**: Tính toán độ võng, ứng suất dưới tác dụng của tải trọng phân bố đều hoặc không đều
- **Phân tích ổn định**: Xác định tải tới hạn và dạng mất ổn định (nén theo một hoặc hai trục)
- **Phân tích dao động tự do**: Tính toán tần số riêng và dạng dao động, có xét đến quán tính quay
- **Giao diện đồ họa (GUI)**: Sử dụng `MindlinPlateAnalysisHub` để thiết lập và trực quan hóa kết quả
- **Điều kiện biên đa dạng**: Hỗ trợ biên tự do (F), đỡ đơn (S), ngàm (C) cho mỗi cạnh
- **Lưới tứ giác tự động**: Điều chỉnh mật độ lưới theo hai phương, tự động đánh số nút và phần tử
- **Trực quan hóa kết quả**: Biểu diễn biến dạng, đường đẳng trị ứng suất, dạng dao động, và các thông số đặc trưng
- **Tương thích MATLAB Online**: Sử dụng trực tiếp trên trình duyệt web mà không cần cài đặt

---

## 🗂️ Cấu Trúc Thư Mục
```text
mindlin-plate-analysis/
├── startup.m                   # Khởi tạo môi trường làm việc
├── examples/                   # Thư mục chứa các ví dụ
│   ├── staticAnalysis.m       # Ví dụ phân tích tĩnh
│   ├── bucklingAnalysis.m     # Ví dụ phân tích ổn định
│   └── vibrationAnalysis.m    # Ví dụ phân tích dao động
└── src/
    ├── analysis/              # Mô-đun phân tích
    │   ├── static/           # Phân tích tĩnh
    │   ├── buckling/         # Phân tích ổn định
    │   └── vibration/        # Phân tích dao động
    ├── element/              # Phần tử Mindlin
    ├── mesh/                 # Sinh lưới
    ├── gui/                  # Giao diện người dùng
    └── utils/                # Công cụ bổ trợ
```

---

## ⚙️ Yêu Cầu Hệ Thống
| Phần mềm          | Phiên bản tối thiểu |
|-------------------|---------------------|
| **MATLAB**        | R2020b (khuyến nghị R2022a trở lên) |
| **Toolbox**       | Không yêu cầu thêm |
| **Trình duyệt**   | Chrome, Firefox, Edge (cho MATLAB Online) |

> **Lưu ý**: Để có hiệu năng tốt trên MATLAB Online, nên sử dụng lưới có kích thước vừa phải (nx, ny ≤ 20) và đảm bảo đường truyền internet ổn định.

---

## 🚀 Hướng Dẫn Cài Đặt và Sử Dụng

### Sử Dụng Trên MATLAB Online
1. **Tải Lên Dự Án**:
   - Truy cập [MATLAB Online](https://matlab.mathworks.com)
   - Tải thư mục `mindlin-plate-analysis` lên MATLAB Drive
2. **Thiết Lập Môi Trường**:
   ```matlab
   % Chuyển đến thư mục dự án
   cd mindlin-plate-analysis
   % Chạy tập lệnh khởi tạo
   startup
   ```
3. **Khởi Động Giao Diện**:
   ```matlab
   MindlinPlateAnalysisHub
   ```

### Chạy Nhanh Bằng Script
```matlab
% Phân tích tĩnh
examples/staticAnalysis

% Phân tích ổn định
examples/bucklingAnalysis

% Phân tích dao động tự do
examples/vibrationAnalysis
```

---

## 📝 Hướng Dẫn Thiết Lập Bài Toán
1. **Thông Số Hình Học và Lưới**:
   - Nhập kích thước tấm (a × b), chiều dày (h)
   - Chọn số phần tử theo mỗi phương (nx × ny)
2. **Đặc Trưng Vật Liệu**:
   - Mô-đun đàn hồi (E)
   - Hệ số Poisson (ν)
   - Khối lượng riêng (ρ)
   - Hệ số hiệu chỉnh cắt (mặc định 5/6)
3. **Điều Kiện Biên**:
   - Sử dụng chuỗi 4 ký tự cho 4 cạnh (trái–phải–trước–sau)
   - F: Tự do, S: Đỡ đơn, C: Ngàm
   - Ví dụ: "SSSS" - tất cả các cạnh đỡ đơn
4. **Tải Trọng**:
   - Tùy chọn áp lực, lực tập trung hoặc moment
5. **Thực Hiện Phân Tích**:
   - Sử dụng giao diện để xem kết quả
   - Xuất dữ liệu ra không gian làm việc

---

## 🔧 Xử Lý Sự Cố
| Vấn đề                     | Giải pháp                                                  |
|---------------------------|-----------------------------------------------------------|
| **Lỗi đường dẫn**         | Chạy lại `startup.m`                                       |
| **Kết quả không chính xác**| Tăng mật độ lưới, kiểm tra đơn vị đầu vào                |
| **Lỗi hiển thị font**     | Kích hoạt hỗ trợ UTF-8 trong MATLAB                       |
| **Chậm trên MATLAB Online**| Giảm kích thước lưới, kiểm tra kết nối mạng              |

---

## 🤝 Đóng Góp
Chúng tôi luôn chào đón mọi đóng góp từ cộng đồng!
1. Fork dự án và tạo nhánh mới (`feature/tên-tính-năng` hoặc `bugfix/mô-tả`)
2. Tuân thủ quy tắc viết mã của MATLAB Code Analyzer
3. Tạo Pull Request với mô tả chi tiết về những thay đổi

---

## 📜 Giấy Phép
Giấy phép MIT – Cho phép sử dụng, sửa đổi và phân phối tự do với điều kiện ghi nhận tác giả gốc.