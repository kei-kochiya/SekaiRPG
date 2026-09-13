<div align="center">
  <h1>🌟 SekaiRPG 🌟</h1>
  <p><i>Trải nghiệm nhập vai chiến thuật theo lượt (Turn-based RPG), lấy cảm hứng từ vũ trụ Project Sekai!</i></p>

  [![CI/CD Pipeline](https://github.com/kei-kochiya/SekaiRPG/actions/workflows/ci.yml/badge.svg)](https://github.com/kei-kochiya/SekaiRPG/actions/workflows/ci.yml)
  [![Unit Tests](https://img.shields.io/badge/Unit%20Tests-216%20Passed-brightgreen)](Tests/)
  [![Godot Engine](https://img.shields.io/badge/Godot-4.2+%20|%204.6-blue?logo=godotengine&logoColor=white)](https://godotengine.org)
  [![Platform](https://img.shields.io/badge/Platform-Windows%20|%20Linux%20|%20Android-green)](#-xuat-ban-va-cai-dat)
  [![License](https://img.shields.io/badge/License-MIT%20%2F%20CC0-orange)](asset_manifest.json)
</div>

---

**SekaiRPG** là một tựa game nhập vai chiến thuật (2D Turn-based RPG) phát triển trên **Godot Engine 4.x**, được xây dựng theo kiến trúc **Domain-Driven Design** và **Scenario Pattern**. Trò chơi kết hợp phong cách di chuyển khám phá thế giới Overworld với hệ thống chiến đấu chuyên sâu tính theo **Action Value (AV)**, tương khắc 5 hệ nguyên tố, phá vỡ điểm yếu (**Weakness Break**) và chế độ leo tháp mô phỏng **Holo-Simulation Roguelite**.

---

## ✨ Tính Năng Nổi Bật

### ⚔️ 1. Hệ Thống Chiến Đấu 2.0 (Deep Combat Engine)
* **Action Value (AV) Timeline**: Tốc độ (SPD) quyết định chính xác khoảng cách đến lượt đánh tiếp theo.
* **Ngũ Hành Tương Khắc (5-Element Chart)**: `Cool` $\rightarrow$ `Happy` $\rightarrow$ `Cute` $\rightarrow$ `Cool`, cùng cặp đối trọng `Pure` $\leftrightarrow$ `Mysterious`.
* **Cơ Chế Phá Vỡ Điểm Yếu (Weakness Break)**: Đòn đánh đúng hệ bào mòn thanh Break Gauge. Khi vỡ điểm yếu, kẻ địch bị **Choáng 1 lượt** và bị **đẩy lùi 3000 AV**.
* **Hiệu Ứng Chiến Đấu & Chí Mạng**: Hiệu ứng rung màn hình (**Screen Shake**), dừng hình (**Hitstop**), số nhảy sát thương nổi (**Floating Combat Text**) với tỷ lệ/sát thương Chí Mạng riêng biệt.
* **12 Chủng Loại Kẻ Địch & Boss**: Bao gồm Drone Trinh Sát, Xạ Thủ Bắn Tỉa, Vệ Binh Cơ Giới, Chuyên Viên Nhiễu Sóng, Boss Đội Trưởng và Trùm Cuối Thủ Tướng.

### 🗺️ 2. Khám Phá Cốt Truyện & Kinh Tế (Story & Economy)
* **10 Nhiệm Vụ Cốt Truyện**: Quản lý bằng siêu dữ liệu `QuestDefinition` từ Mở màn (Prologue) đến Xa lộ đêm (Finale).
* **Kinh Tế & Vật Phẩm**: Tiền tệ Credits, rương kho báu SVG tương tác Overworld, máy bán hàng tự động Safehouse Vending Machine, sử dụng vật phẩm hỗ trợ trong trận.
* **Hội Thoại Phân Nhánh (MVC Dialogue)**: Hộp thoại phân tách Model-View-Controller với phông chữ phân lớp và ảnh chân dung nhân vật.

### 🗼 3. Chế Độ Leo Tháp Roguelite (Holo-Simulation)
* **10 Tầng Thử Thách Vô Tận**: Chọn 1 trong 3 Phước Lành (Blessing) ngẫu nhiên sau mỗi tầng thắng (Huyết Nguyệt, Tốc Hành, Giáp Gai, Chấn Lực...).
* **Trạm Nghỉ Ngơi & Boss Cuối**: Hồi phục tại Tầng 4 & 9, quyết đấu Super Captain tại Tầng 10.

---

## 📁 Cấu Trúc Dự Án Tinh Gọn (9 Root Folders)

```text
SekaiRPG/
├── .devcontainer/  # Dockerfile & devcontainer.json cho VS Code / Codespaces
├── .github/        # GitHub Actions CI/CD Pipeline (ci.yml)
├── Assets/         # Toàn bộ Audio, Fonts, Icons, Portraits, Sprites, Kenney Packs
├── Data/           # Cấu hình JSON kịch bản hội thoại và đội hình
├── Entities/       # Characters/ (6 nhân vật), Enemies/ (12 loại quái), Entity.gd
├── Export/         # Tệp xuất bản Android APK và Desktop builds
├── Maps/           # Bản đồ Overworld (Base, Prologue, Warehouse, Harbor, Street, Highway...)
├── Quests/         # 10 Quest Definitions (.tres) & QuestRegistry.gd
├── Scripts/        # Battle/ (Main.gd, Scenarios/, HoloSim/), Core/, Overworld/, Systems/
├── Tests/          # Unit Test Suites (TestCore, TestCombat, TestEntities...), TestRunner
└── UI/             # Giao diện Battle, Effects, Menus, Systems (DialogueUI, MobileControls)
```

*(Chi tiết đầy đủ về sơ đồ quan hệ và luồng dữ liệu xem tại [ARCHITECTURE.md](ARCHITECTURE.md))*

---

## 🧪 Kiểm Thử Tự Động (Automated Testing)

Dự án trang bị hệ thống Unit Test toàn diện với **216 Assertions (100% Pass)** kiểm tra từ chỉ số nhân vật, công thức sát thương, AI quái, cơ chế Break đến lưu/tải game:

### Chạy Test Cục Bộ (Local):
- **Linux / macOS / DevContainer**:
  ```bash
  make test
  # hoặc
  ./scripts/run_tests.sh
  ```
- **Windows (PowerShell)**:
  ```powershell
  .\scripts\run_tests.ps1
  # hoặc
  godot --headless Tests/TestRunnerScene.tscn
  ```

---

## 🚀 Khởi Động & Cài Đặt

### Cách 1: Chạy Trong VS Code DevContainer / GitHub Codespaces
Mở repository trên GitHub và chọn **Code $\rightarrow$ Codespaces $\rightarrow$ Create codespace**. Toàn bộ môi trường Godot 4 Headless, Java, Python và Linter sẽ được cài đặt tự động.

### Cách 2: Chạy Trên Máy Cá Nhân
1. Cài đặt **[Godot Engine 4.2+](https://godotengine.org/download/)** (khuyên dùng Godot 4.3 hoặc 4.6).
2. Clone repository:
   ```bash
   git clone https://github.com/kei-kochiya/SekaiRPG.git
   cd SekaiRPG
   ```
3. Mở Godot Engine, chọn **Import**, duyệt đến thư mục dự án và chọn file `project.godot`.
4. Nhấn **F5** để trải nghiệm game!

---

## 📱 Đóng Gói Xuất Bản Android (Build APK)

Dự án đã được cấu hình sẵn sàng cho Android (đồ họa `gl_compatibility`, cố định Landscape, phím ảo cảm ứng):
```bash
make export-android
# hoặc
godot --headless --export-debug "Android" Export/Android/SekaiRPG_debug.apk
```

---

## 🤝 Hướng Dẫn Đóng Góp

Vui lòng đọc kỹ tài liệu **[CONTRIBUTING.md](CONTRIBUTING.md)** và **[ARCHITECTURE.md](ARCHITECTURE.md)** trước khi tạo Pull Request.

---

## 📄 Bản Quyền & Tài Nguyên

- **Game Logic & Source Code**: Phát hành theo chuẩn mã nguồn mở phục vụ học tập và cộng đồng.
- **Tài Nguyên Đồ Họa & UI**: Sử dụng gói miễn phí của tác giả **Kenney** ([kenney.nl](https://kenney.nl), giấy phép CC0 Public Domain).
- Chi tiết nguồn gốc và giấy phép từng tài nguyên xem tại **[asset_manifest.json](asset_manifest.json)**.
