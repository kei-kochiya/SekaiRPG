# Contributing to SekaiRPG

Chào mừng bạn và cảm ơn bạn đã quan tâm đóng góp cho **SekaiRPG**! Tài liệu này hướng dẫn quy trình phát triển, quy chuẩn mã nguồn và cách thức gửi Pull Request (PR) chuẩn mực.

---

## 🛠️ 1. Thiết Lập Môi Trường Phát Triển

### Cách 1: Sử dụng VS Code DevContainer (Khuyên dùng)
Dự án được cấu hình sẵn `.devcontainer/` tương thích với **VS Code Remote - Containers** và **GitHub Codespaces**:
1. Mở repository trong VS Code.
2. Chọn **"Reopen in Container"** khi có thông báo.
3. Môi trường đã được cài sẵn Godot 4.x headless, Python 3, GDToolkit, OpenJDK.

### Cách 2: Thiết Lập Cục Bộ (Local)
1. Cài đặt **Godot Engine 4.2+** (khuyên dùng Godot 4.3 hoặc 4.6).
2. Clone repository:
   ```bash
   git clone https://github.com/kei-kochiya/SekaiRPG.git
   cd SekaiRPG
   ```
3. Mở `project.godot` bằng Godot Editor.

---

## 🧪 2. Chạy Kiểm Thử Tự Động (Automated Testing)

Mọi thay đổi mã nguồn trước khi tạo Pull Request **BẮT BUỘC** phải vượt qua bộ Unit Test toàn diện:

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

### Thêm Test Mới Khi Phát Triển Tính Năng:
- Khi viết tính năng mới hoặc sửa lỗi, hãy thêm phương thức `func test_*():` tương ứng vào thư mục `Tests/Unit/` (ví dụ `TestCombat.gd`, `TestEntities.gd`, `TestCore.gd`).
- Sử dụng các hàm assertion có sẵn: `assert_true`, `assert_false`, `assert_eq`, `assert_gt`, `assert_lt`.

---

## 📐 3. Quy Chuẩn Kiến Trúc & Mã Nguồn (Code Style)

Đọc kỹ tài liệu **[`ARCHITECTURE.md`](ARCHITECTURE.md)** trước khi thay đổi logic:

1. **Domain-Driven & Scenario Pattern**:
   - Mọi thực thể kế thừa từ `Entities/Entity.gd`.
   - Các trận đấu đặc biệt kế thừa từ `Scripts/Battle/Scenarios/BattleScenario.gd`.
2. **Bất biến StoryState**: Không tùy tiện thay đổi thứ tự hay xóa cờ cốt truyện trong `StoryState.gd` mà không cập nhật đồng bộ các Map liên quan.
3. **Structured Logging**: Sử dụng `GameLogger.info()`, `GameLogger.warn()`, `GameLogger.error()` thay vì gọi `print()` trần.
4. **Định dạng GDScript**:
   - Sử dụng Tab để thụt đầu dòng (Indentation).
   - Đặt tên hàm và biến theo chuẩn `snake_case`.
   - Đặt tên Class theo chuẩn `PascalCase`.

---

## 📦 4. Quy Ước Commit & Gửi Pull Request

Sử dụng chuẩn **Conventional Commits**:
- `feat:` Thêm tính năng mới (Gameplay, Map, Scenario, Entity).
- `fix:` Sửa lỗi logic, null pointer, crash.
- `refactor:` Tái cấu trúc mã nguồn mà không đổi hành vi.
- `test:` Bổ sung hoặc chỉnh sửa bộ kiểm thử.
- `docs:` Cập nhật tài liệu, README, ARCHITECTURE.
- `chore:` Cấu hình CI/CD, export, dependencies.

### Quy trình gửi PR:
1. Tạo nhánh mới từ `main`: `git checkout -b feature/ten-tinh-nang`.
2. Commit các thay đổi kèm unit test chứng minh tính đúng đắn.
3. Chạy `make test` để xác nhận 100% assertions đạt.
4. Đẩy nhánh lên GitHub và tạo Pull Request vào nhánh `main`.
