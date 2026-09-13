# Changelog

Tất cả các thay đổi đáng chú ý của dự án **SekaiRPG** được ghi lại chi tiết trong tài liệu này.

Định dạng dựa trên [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
và dự án tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-09-13

### Added
- **4 Chủng Loại Kẻ Địch Mới**:
  - `ReconDrone` (Cool - Tốc độ cao 140 SPD, Quét giảm DEF, Sốc EMP đẩy lùi 2500 AV).
  - `Sniper` (Mysterious - Sát thương chí mạng 35% Crit Rate, Headshot x2.0 + Bleed, Lựu đạn khói buff DEF).
  - `CyborgEnforcer` (Cute - Siêu chống chịu 500 HP / 180 Break Gauge, Nện khiên Choáng, Bật khiên hồi phục).
  - `CyberJammer` (Happy - Tác chiến điện tử, Hack khóa kỹ năng / Choáng 1 lượt, Xung trợ lực buff 25 ATK & 3000 AV cho đồng minh).
- **Structured GameLogger Framework (`Scripts/Core/Logger.gd`)**:
  - 4 Cấp độ ghi log: `DEBUG`, `INFO`, `WARN`, `ERROR`.
  - Tích hợp `push_warning()` và `push_error()` cùng bộ đệm lịch sử log 200 bản ghi.
- **Hệ Thống Kiểm Thử Tự Động Toàn Diện (GUT & Master Runner)**:
  - Tích hợp cấu hình `.gutconfig.json` và cấu trúc `tests/unit/` + `Tests/Unit/`.
  - Bổ sung `TestLogger.gd`, `test_damage_calculator.gd`, `test_turn_order.gd` nâng tổng số lên **216 assertions (100% Pass)**.
- **CI/CD Pipeline (`.github/workflows/ci.yml`)**:
  - Tự động chạy kiểm tra lint, xác thực JSON cốt truyện, import và chạy headless test suite trên GitHub Actions.
- **DevContainer & Developer Tooling**:
  - `.devcontainer/devcontainer.json` và `Dockerfile` hỗ trợ phát triển tức thì trên GitHub Codespaces / VS Code.
  - `Makefile`, `scripts/run_tests.sh`, `scripts/run_tests.ps1` hỗ trợ chạy test và build chỉ với 1 dòng lệnh.
- **Tài Liệu & Quản Lý Phụ Thuộc**:
  - `asset_manifest.json` ghi nhận bản quyền và danh mục tài nguyên Kenney, Fonts, Audio.
  - `CONTRIBUTING.md` và `SECURITY.md` thiết lập quy chuẩn cộng tác mã nguồn mở.

### Changed
- **Tinh Gọn Dự Án (9 Root Folders)**: Hợp nhất toàn bộ tài nguyên đồ họa vào `Assets/`, menu vào `UI/Menus/`, kịch bản vào `Scripts/Battle/Scenarios/`.
- **Hoàn Thiện Cơ Chế Phá Vỡ Điểm Yếu (Weakness Break)**:
  - Gán thuộc tính ngũ hành (`Cool, Happy, Cute, Mysterious, Pure`) cho 100% kẻ địch trong game.
  - Hỗ trợ cơ chế bào mòn điểm yếu trung tính (15% chip damage) và phá vỡ điểm yếu khắc hệ (40%+ damage).
- **Tối Ưu Mobile & Android Build**:
  - Khóa màn hình ngang Landscape (`window/handheld/orientation=0`).
  - Cấu hình chế độ đồ họa `gl_compatibility` tiết kiệm pin và tương thích 100% thiết bị Android.
  - Đóng gói file APK thử nghiệm thành công (`Export/Android/SekaiRPG_debug.apk`).

---

## [1.0.0] - 2026-09-03

### Added
- **Cốt Truyện Hoàn Chỉnh 10 Nhiệm Vụ (Quests)** từ Mở Màn (Prologue) đến Trận Chiến Xa Lộ (Finale Arc).
- **6 Nhân Vật Chơi Được**: Ichika, Kanade, Mafuyu, Ena, Mizuki, Honami với bộ kỹ năng và nội tại tương tác độc quyền.
- **Hệ Thống Chiến Đấu AV (Action Value Timeline)**: Tương tự Honkai Star Rail, tốc độ quyết định thứ tự hành động.
- **Hệ Thống Lưu Trữ Chuyên Nghiệp (SaveManager)**: Lưu không giới hạn tại `user://saves/` với xem trước tiến trình nhiệm vụ, thời gian lưu và hỗ trợ Auto-Save 5 phút an toàn.
- **Chế Độ Roguelite Mô Phỏng Holo-Sim (10 Tầng Thử Thách)**: 8 Phước Lành tùy chọn, trạm nghỉ ngơi tầng 4 & 9, trùm cuối tầng 10.
- **Kinh Tế & Khám Phá (Economy System)**: Tiền tệ Credits, rương kho báu SVG tương tác, cửa hàng Safehouse Vending Machine, sử dụng vật phẩm trong lượt đấu.
- **Giao Diện Hội Thoại MVC (Dialogue System)**: Hộp thoại phân nhánh cốt truyện, hỗ trợ chân dung cảm xúc và font chữ phân lớp phong cách RPG Maker.
