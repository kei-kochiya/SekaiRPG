# SekaiRPG: Project Architecture & Dependency Map

Tài liệu này cung cấp cái nhìn tổng quan về kiến trúc của **SekaiRPG**, được thiết kế theo mô hình **Domain-Driven** và **Scenario-based**, giúp các lập trình viên dễ dàng mở rộng và bảo trì hệ thống.

---

## 1. Core Engine (Bộ não trung tâm)

Chịu trách nhiệm quản lý trạng thái toàn cục của trò chơi, bao gồm tiến trình cốt truyện, đội hình và dữ liệu lưu trữ.

| File | Chức năng chính | Phụ thuộc vào |
| :--- | :--- | :--- |
| **`GameManager.gd`** (Autoload) | Quản lý trạng thái toàn cục (Party, Save/Load, Scene Transition). Điều phối các `Scripted Battle`. | `StoryState`, `LevelManager` |
| **`StoryState.gd`** | Lưu trữ các cờ (flags) kịch bản và tiến độ nhiệm vụ (wave, quest). | Không có |
| **`LevelManager.gd`** | Xử lý nhận EXP, tính toán chỉ số theo cấp độ (Soft/Hard Cap), và tự động phân bổ chỉ số (Auto-upgrade) cho quái vật. | `Entity` |

---

## 2. Battle System (Hệ thống chiến đấu)

Hệ thống chiến đấu theo lượt (Turn-based) phức tạp sử dụng cơ chế **Action Value (AV)** (tương tự Honkai: Star Rail).

### 2.1. Battle Engine (Lõi chiến đấu)
| File | Chức năng chính | Phụ thuộc vào |
| :--- | :--- | :--- |
| **`Main.gd`** | Battle Engine cốt lõi. Quản lý Vòng lặp lượt đánh, AI, Timeline (AV), và UI trận đấu. | Nhiều hệ thống |
| **`BattleInitializer.gd`** | Tự động đọc Map/Kịch bản để khởi tạo đội hình Phe ta - Phe địch và chọn Scenario phù hợp trước trận. | `GameManager`, `Scenarios` |
| **`AIManager.gd`** | Trí tuệ nhân tạo của kẻ địch. Tính toán mục tiêu (Tanker, Low HP) và ra quyết định dùng kỹ năng. | `Entity` |

### 2.2. Battle Mechanics (Cơ chế tính toán)
| File | Chức năng chính | Phụ thuộc vào |
| :--- | :--- | :--- |
| **`DamageCalculator.gd`** | Tính toán sát thương, bao gồm Buff, Debuff, và Tương khắc hệ (Cool, Pure, v.v.). | `Entity` |
| **`TurnCalculator.gd`** | Tính toán Action Value (AV) dựa trên Tốc độ (Speed) và hành động để xác định thứ tự lượt đánh. | `Entity` |
| **`ProcessStatus.gd`** | Xử lý logic tại đầu/cuối lượt (Trừ máu do Bleed/Poison, giảm Cooldown, Stun). | `Entity` |

### 2.3. Scenarios (Kịch bản chiến đấu)
Hệ thống sử dụng **Scenario Pattern** để can thiệp vào các "Hooks" của trận đấu (on_start, on_turn_start, on_entity_died).
| File | Chức năng chính |
| :--- | :--- |
| **`BattleScenario.gd`** | Lớp cơ sở (Abstract) định nghĩa các hooks chiến đấu. |
| **`DefaultScenario.gd`** | Logic chiến đấu mặc định (Đánh đến khi một bên hết máu). |
| **`HarborBossScenario.gd`**| Kịch bản phức tạp 3 Phase của trận Đội Trưởng (Cảng), hồi sinh, đổi team. |
| **`PrologueScenario.gd`** | Kịch bản trận mở màn (Ichika bị bao vây). |
| **`StreetSurvivalScenario.gd`** | Kịch bản sinh tồn đặc biệt: Khóa kỹ năng nhân vật, quái spawn vô hạn và tăng cấp dần theo lượt. Khi phe ta gục ngã, kích hoạt pha Cứu viện của Mafuyu (buff 50% chỉ số) và quản lý điều kiện diệt 10 tên Khủng Bố để chiến thắng. |

---

## 3. Dialogue System (Hệ thống hội thoại)

Tuân thủ chặt chẽ mô hình **MVC (Model-View-Controller)**, tách biệt hoàn toàn giữa dữ liệu, hiển thị và logic. Hỗ trợ hiển thị và tương tác rẽ nhánh cốt truyện (Branching Choices).

| File | Vai trò | Chức năng chính |
| :--- | :--- | :--- |
| **`DialogueManager.gd`** | **Controller** | Điều phối luồng thoại, block input, hiển thị lựa chọn (`show_choice`) và chờ trả kết quả (`choice_made`). |
| **`DialogueUI.gd`** | **View** | Vẽ giao diện khung thoại, chân dung NPC, tự động build UI nút lựa chọn (Choices). |
| **`DialogueLoader.gd`** | **Model** | Nạp và phân tích dữ liệu hội thoại từ bộ nhớ hoặc thư mục JSON. |

---

## 4. World & Maps (Hệ thống bản đồ)

Quản lý không gian Overworld và luồng di chuyển của người chơi. Safehouse sử dụng **Stage Pattern** để thay đổi không gian theo thời gian thực mà không cần đổi Scene.

| File/Thư mục | Chức năng chính | Trạng thái (Story) |
| :--- | :--- | :--- |
| **`PrologueMap.gd`** | Bản đồ mở đầu. Quản lý kịch bản Ichika bị bao vây và Mafuyu cứu viện. | Tutorial |
| **`BaseMap.gd`** (Shell)| Vỏ bọc Safehouse. Chứa BaseMapStage để thay đổi không gian (sáng/tối/buổi sáng). | Hub/Safehouse |
| **`WarehouseMap.gd`** | Bản đồ Nhà kho. Đánh theo dạng Wave liên tục. | Nhiệm vụ phụ |
| **`TrainingWarehouseMap.gd`** | Bản đồ Luyện tập/Sandbox. Tự động spawn địch theo thành viên tham gia, có cờ giới hạn (limit). | Luyện tập |
| **`CafeMap.gd`** | Bản đồ trang trí Quán Cafe. Cảnh hội thoại và phân nhánh kết cục sự kiện Ena say xỉn. | Nhiệm vụ phụ |
| **`HarborMap.gd`** | Bản đồ Bến cảng. Quản lý đường đi (Đánh lính gác hoặc vào thẳng Boss). | Nhiệm vụ chính |
| **`AlleywayMap.gd`** | Bản đồ Hẻm nhỏ. Trạm dừng chân và hội thoại sau khi đánh Boss. | Transition |
| **`StreetMap.gd`** | Bản đồ Đường phố ngã tư đô thị. Quản lý kịch bản thám thính, trận phục kích Skirmish, trận chiến sinh tồn đặc biệt của Ichika & Mizuki và pha cứu viện của Mafuyu. Dàn dựng bối cảnh xe đỏ/xanh, vỉa hè, vạch qua đường cực kỳ chuyên nghiệp. | Nhiệm vụ chính |

---

## 5. Entities (Thực thể & Chỉ số)

Thiết kế theo mô hình Hướng đối tượng (OOP). Mỗi nhân vật hoặc kẻ địch kế thừa từ một Base Class thống nhất.

### 5.1. Base Class
| File | Chức năng chính |
| :--- | :--- |
| **`Entity.gd`** | Nền tảng của vạn vật. Quản lý Stats (HP, ATK, SPD, DEF), Mảng Kỹ năng (Skills), Buffs/Debuffs (Status), và Hệ (Elements). |

### 5.2. Characters (Phe ta)
Các script nằm trong `Entities/Characters/`. Mỗi nhân vật (Ichika, Mafuyu, Ena, v.v.) có kỹ năng, chỉ số Hard Cap và cơ chế tương tác (Synergy) riêng biệt (VD: Ichika & Mafuyu tương tác với Bleed).

### 5.3. Enemies (Kẻ địch)
Các script nằm trong `Entities/Enemies/`.
*   **`Kidnapper.gd`**: Kẻ thù cơ bản ở Prologue.
*   **`Guard.gd` / `Captain.gd`**: Lính gác và Boss Đội trưởng tại Bến cảng.
*   **`WarehouseWorker.gd`**: Quái vật ở Nhà kho.
*   **`TrainingBot.gd`**: Dùng cho chế độ Sandbox/Training.
*   **`Thug.gd`**: Kẻ địch giang hồ xuất hiện tại Quán Cafe (CafeMap).
*   **`Terrorist.gd`**: Kẻ địch khủng bố xuất hiện tại khu vực Ngã tư đường phố (StreetMap) trong pha phục kích và sinh tồn, có kỹ năng xả súng liên thanh gây Bleed.

---

## 6. UI & Common Systems (Hệ thống UI & Hỗ trợ)

Quản lý các giao diện hỗ trợ tương tác người chơi, cài đặt hệ thống và tối ưu hóa trải nghiệm trên đa nền tảng di động.

| File | Vai trò | Chức năng chính |
| :--- | :--- | :--- |
| **`MobileControls.gd`** (Autoload) | **Mobile Controller** | Tạo joystick ảo, các nút bấm (Menu, Interact) có bao viền gỗ tinh tế. Tự động ẩn/hiện thông minh tùy thuộc vào scene (Ẩn ở Menus, ẩn Joystick ở Battle) và hỗ trợ chạm tua đối thoại cực nhạy. |
| **`PauseMenu.gd`** (Autoload) | **System Menu** | Menu tạm dừng tích hợp chỉnh âm lượng (Master Volume), bật/tắt Fast Battle (tăng tốc lượt AI), và tính năng **Skip Battle** (bảo mật bằng mật mã ẩn danh `27101108`). |
| **`UpgradeUI.gd`** | **Upgrade View** | Giao diện nâng cấp thuộc tính, chỉ số cho nhân vật bằng tài nguyên thu thập được. |

---

## 7. Font & Theme System (Hệ thống Font & Theme)

SekaiRPG sử dụng hệ thống Font chữ phân lớp chuyên nghiệp để định hình phong cách đồ họa sang trọng và tăng khả năng tối ưu hóa trải nghiệm đọc của người chơi.

| Thành phần | Font chữ áp dụng | Mô tả & Cách hoạt động |
| :--- | :--- | :--- |
| **Global Theme** (`default_theme.tres`) | **`zhcn.ttf`** | Thiết lập làm Font mặc định cho toàn bộ dự án Godot. Mọi Node văn bản (`Label`, `RichTextLabel`...) nếu không ghi đè sẽ tự động sử dụng font này. |
| **Global Buttons** (`default_theme.tres`) | **`Lagu Sans Bold.otf`** | Thiết lập ghi đè lớp `Button` trong Global Theme để mọi nút bấm trong trò chơi tự động mang kiểu chữ đậm cá tính này. |
| **Title Banner** (`StartMenu.gd`) | **`zhcn.ttf`** | Dùng riêng cho tiêu đề trò chơi "SEKAI RPG" ở màn hình mở đầu. |
| **Dialogue Narration** (`DialogueUI.gd`) | **`Lagu Sans Light.otf`** | Gán cho thuộc tính `normal_font` của RichTextLabel trong hộp hội thoại người dẫn chuyện (Narrator) và thoại chính. |
| **Dialogue Action** (`DialogueUI.gd`) | **`Lagu Sans Light Italic.otf`** | Tự động kích hoạt khi dùng thẻ `[i]` (thể hiện thoại hành động cốt truyện). |
| **Character Name** (`DialogueUI.gd`) | **`Lagu Sans Bold.otf`** | Tự động kích hoạt khi dùng thẻ `[b]` (bọc quanh tên nhân vật phát ngôn cốt truyện). |

---

## Sơ đồ phụ thuộc (Dependency Flow)

```mermaid
graph TD
    subgraph Core
        GM[GameManager] --> SS[StoryState]
        GM --> LM[LevelManager]
    end

    subgraph Battle
        M[Main.gd] --> BI[BattleInitializer]
        M --> BS[BattleScenario]
        M --> DC[DamageCalculator]
        M --> TC[TurnCalculator]
        BI --> SC[Specific Scenarios]
    end

    subgraph Overworld & Flow
        MAP[Maps] --> GM
        MAP --> DM[DialogueManager]
        BM[BaseMap] --> BSt[BaseMapStages]
        MAP --> MC[MobileControls]
    end

    subgraph UI & Systems
        DM --> DUI[DialogueUI]
        DM --> DL[DialogueLoader]
        GM --> PM[PauseMenu]
    end
```

---

## Hướng dẫn mở rộng cho Developer

1.  **Thêm Nhân vật / Kẻ địch mới**:
    *   Tạo script mới kế thừa `Entity.gd` trong thư mục `Entities/`.
    *   Định nghĩa Base Stats, Element và danh sách Kỹ năng (Skills array).
    *   Đăng ký Class mới vào từ điển `character_classes` hoặc `enemy_classes` trong `BattleInitializer.gd`.

2.  **Thêm Trận đánh Boss (Scripted Battle)**:
    *   Tạo file Scenario mới trong `Scripts/Battle/Scenarios/` (kế thừa `BattleScenario.gd`).
    *   Cập nhật `BattleInitializer.gd` (hàm `_setup_scripted_battle`) để trả về Scenario này cùng với đội hình tương ứng.
    *   Gọi `GameManager.is_scripted_battle = true` trước khi trigger trận.

3.  **Thêm Kịch bản tại Safehouse**:
    *   Tạo file Stage mới trong `Maps/Base/Stages/` (kế thừa `BaseMapStage`).
    *   Ghi đè các hàm như `get_npc_positions()`, `on_stage_start()` để đặt logic.
    *   Đăng ký Stage vào `BaseMap.gd`.

