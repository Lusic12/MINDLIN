```markdown
# Phân Tích Tấm Mindlin bằng Phương Pháp Phần Tử Hữu Hạn (FEM) – MATLAB  

Phần mềm **Mindlin-Plate-Analysis** cung cấp một bộ công cụ hoàn chỉnh để phân tích tấm dày (Mindlin/Reissner) bằng MATLAB. Thư viện hỗ trợ ba loại bài toán cổ điển—tĩnh, ổn định (buckling) và dao động tự do—kèm giao diện đồ họa thân thiện giúp bạn nhanh chóng thiết lập mô hình, xác định điều kiện biên và trực quan hóa kết quả.  

---

## 🌟 Tính năng chính
- **Phân tích tĩnh**: tính độ võng, phân bố ứng suất dưới tải phân bố đều hoặc không đều.  
- **Phân tích ổn định (buckling)**: xác định tải tới hạn và dạng mất ổn định cho nén một trục hoặc hai trục.  
- **Phân tích dao động tự do**: tính tần số riêng, dạng mode dao động có xét đến quán tính quay.  
- **GUI tích hợp**: `MindlinPlateAnalysisHub` cho phép thao tác trực quan toàn bộ quy trình.  
- **Điều kiện biên linh hoạt**: mỗi mép tùy chọn Tự do (F), Đỡ đơn (S) hoặc Kẹp cứng (C).  
- **Sinh lưới tứ giác có cấu trúc**: kiểm soát mật độ lưới theo hai phương, đánh số nút & phần tử tự động.  
- **Trực quan hóa**: đồ thị biến dạng, contour ứng suất, mode shape, bảng tần số & hệ số tải tới hạn.  

---

## 🗂️ Cấu trúc thư mục
```text
mindlin-plate-analysis/
├── startup.m                   # Thiết lập đường dẫn & biến môi trường
├── examples/                   # Ví dụ sẵn có
│   ├── staticAnalysis.m
│   ├── bucklingAnalysis.m
│   └── vibrationAnalysis.m
└── src/
    ├── analysis/               # Mô-đun phân tích
    │   ├── static/
    │   ├── buckling/
    │   └── vibration/
    ├── element/                # Công thức phần tử Mindlin
    ├── mesh/                   # Hàm sinh lưới
    ├── gui/                    # Giao diện đồ họa
    └── utils/                  # Hàm hỗ trợ vẽ & xử lý
```

---

## ⚙️ Yêu cầu hệ thống
| Phần mềm          | Phiên bản tối thiểu |
|-------------------|---------------------|
| **MATLAB**        | R2020b (khuyến nghị R2022a+) |
| **Toolbox cần thiết** | Không yêu cầu bổ sung (sử dụng hàm MATLAB gốc) |

> **Lưu ý**: Hiệu năng tốt hơn khi chạy trên máy có CPU đa nhân và ≥ 8 GB RAM, đặc biệt với lưới dày.

---

## 🚀 Cài đặt & khởi chạy

```matlab
% 1. Mở MATLAB và cd vào thư mục dự án
cd path/to/mindlin-plate-analysis

% 2. Thiết lập đường dẫn
startup    % hoặc run('startup.m')

% 3. Khởi chạy giao diện
MindlinPlateAnalysisHub
```

### Chạy nhanh qua script
```matlab
% Ví dụ phân tích tĩnh
examples/staticAnalysis

% Ví dụ phân tích ổn định
examples/bucklingAnalysis

% Ví dụ dao động tự do
examples/vibrationAnalysis
```

---

## 📝 Thiết lập bài toán

1. **Khai báo hình học & lưới**  
   - Kích thước a × b, chiều dày `h`, số phần tử `nx × ny`.
2. **Khai báo vật liệu**  
   - Mô-đun Young `E`, hệ số Poisson `ν`, khối lượng riêng `ρ`, hệ số hiệu chỉnh cắt (mặc định 5/6).
3. **Định nghĩa điều kiện biên**  
   - Chuỗi 4 ký tự (theo thứ tự mép trái–phải–trước–sau) với F / S / C.  
   - Ví dụ `"CFSF"`: trái kẹp cứng, phải tự do, trước đỡ đơn, sau tự do.
4. **Khai báo tải**  
   - Áp suất mặt trên, lực nút, moment mép, … tuỳ bài toán.
5. **Chạy phân tích** và xem kết quả trực tiếp trên GUI hoặc xuất ra MATLAB workspace.

---

## 🔧 Khắc phục sự cố
| Vấn đề                          | Giải pháp                                                                 |
|---------------------------------|---------------------------------------------------------------------------|
| **Không tìm thấy hàm**          | Đảm bảo đã chạy `startup.m` để thêm đường dẫn.                            |
| **Kết quả không hội tụ**        | Tăng mật độ lưới, kiểm tra điều kiện biên hoặc giảm bước tải.             |
| **Giá trị vật liệu bất hợp lý** | Kiểm tra `E`, `ν`, `h` theo đúng đơn vị (SI).                             |
| **GUI không hiển thị tiếng Việt**| MATLAB cần bật Unicode / chọn font hỗ trợ UTF-8.                          |

---

## 🤝 Đóng góp
Mọi pull request đều được chào đón!  
1. Fork repo, tạo branch mới với tên tính năng/bugfix.  
2. Đảm bảo code tuân thủ **MATLAB Code Analyzer** (không cảnh báo màu đỏ).  
3. Tạo PR kèm mô tả chi tiết thay đổi.  

---
