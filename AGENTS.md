# AGENTS.md — SekaiRPG

Ngữ cảnh chuẩn cho AI coding agent khi làm việc trong repo này (Claude Code, Cursor, Codex, v.v.).
Đọc file này TRƯỚC mọi task, và đọc `ARCHITECTURE.md` ở gốc repo trước khi sửa hoặc thêm code.

## Tổng quan

- Game: SekaiRPG — RPG 2D turn-based, lấy cảm hứng Project Sekai.
- Engine: Godot 4.x, ngôn ngữ GDScript.
- Kiến trúc: Domain-Driven + Scenario Pattern (chi tiết đầy đủ trong `ARCHITECTURE.md`, bao gồm sơ đồ phụ thuộc dạng Mermaid).

## Chạy & kiểm thử

- Chạy trong editor: mở `project.godot` bằng Godot 4.2+, F5 để play.
- Chạy headless (không cần UI, phù hợp cho agent tự kiểm tra lỗi runtime/log):
  `godot --headless --path . 2>&1 | tee godot_output.log`
- Nếu repo có addon GUT (`addons/gut`), ưu tiên viết/chạy test ở đó thay vì chỉ đọc code tĩnh — đặc biệt cho: setup đội hình qua `BattleInitializer`, các hook của `Scenario`, nhánh lựa chọn trong `DialogueManager`, và các bước chuyển `StoryState` flag. Nếu chưa có GUT, có thể đề xuất thêm nhưng đừng tự ý cài khi chưa được yêu cầu.
- Nếu có Godot MCP server được cấu hình trong IDE, dùng tool run/observe/screenshot của nó để xác nhận thay đổi thay vì chỉ suy luận từ code.

## Sơ đồ phụ thuộc rút gọn (bản đầy đủ: ARCHITECTURE.md)

- **Core (autoload):** `GameManager` → `StoryState`, `LevelManager`, `SaveManager`
- **Battle:** `Main.gd` → `BattleInitializer` → `Scenarios/*` (kế thừa `BattleScenario.gd`); tính toán qua `DamageCalculator`, `TurnCalculator`, `ProcessStatus`, `AIManager`
- **Dialogue (MVC):** `DialogueManager` (controller) → `DialogueUI` (view), `DialogueLoader` (model)
- **Maps:** mỗi `Map*.gd` ứng với một giai đoạn cốt truyện cụ thể (xem cột "Trạng thái Story" trong ARCHITECTURE.md). `BaseMap.gd` là hub Safehouse dùng chung nhiều `BaseMapStage` ở nhiều thời điểm khác nhau — KHÔNG gắn 1:1 với một nhiệm vụ duy nhất.
- **Entities:** mọi Character/Enemy kế thừa `Entity.gd`, đăng ký trong `character_classes`/`enemy_classes` của `BattleInitializer.gd`.

## Quy tắc bắt buộc khi sửa code

1. **Không đổi ý nghĩa hoặc thứ tự `StoryState` flags** (wave, quest) mà không cập nhật đồng bộ mọi Map/Scenario đọc-ghi flag đó — đây là mạch giữ tính liên tục cốt truyện.
2. **Giữ nguyên chữ ký hook** của mọi `Scenario` con (on_start, on_turn_start, on_entity_died, v.v.) theo đúng contract của `BattleScenario.gd`.
3. **Grep toàn repo trước khi đổi** một hàm/biến/signal — đặc biệt các kết nối qua autoload (`GameManager`, `MobileControls`) và signal giữa Map ↔ DialogueManager ↔ GameManager.
4. Sửa `DamageCalculator` / `TurnCalculator` / `ProcessStatus` ảnh hưởng **toàn bộ** entity kế thừa `Entity.gd` — kiểm tra cả nhánh Characters lẫn Enemies, không chỉ case đang test.
5. **Không refactor phạm vi rộng nếu không được yêu cầu rõ.** Báo cáo lỗi nghi ngờ + đề xuất bản vá trước, chờ duyệt rồi mới sửa hàng loạt.
6. Nếu không chắc một thay đổi có ảnh hưởng tới nhánh cốt truyện/kịch bản nào không — hỏi lại thay vì đoán.

## Sau khi sửa

- Chạy lại project (headless hoặc qua MCP) hoặc test GUT liên quan để xác nhận không phá tính năng khác, đặc biệt các trận Boss/Scenario đặc biệt (`HarborBossScenario`, `StreetSurvivalScenario`, `PrologueScenario`).
- Tóm tắt: file nào đổi, vì sao, và ảnh hưởng tới file/luồng nào khác.
