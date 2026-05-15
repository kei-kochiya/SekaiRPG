<div align="center">
  <h1>🌟 SekaiRPG 🌟</h1>
  <p><i>Trải nghiệm nhập vai chiến thuật theo lượt, lấy cảm hứng từ vũ trụ Project Sekai!</i></p>
  <img src="https://img.shields.io/badge/Godot-4.2+-blue?logo=godotengine&logoColor=white" alt="Godot 4.2+"/>
  <img src="https://img.shields.io/badge/Language-GDScript-green" alt="GDScript"/>
  <img src="https://img.shields.io/badge/Status-In%20Development-orange" alt="Status"/>
</div>

---

**SekaiRPG** là một tựa game nhập vai (RPG) 2D phát triển trên **Godot Engine 4.x**. Trò chơi kết hợp phong cách di chuyển thám hiểm Overworld truyền thống với hệ thống chiến đấu theo lượt (Turn-based) mang nặng tính chiến thuật, nơi bạn sẽ đồng hành cùng các nhân vật quen thuộc như Ichika, Kanade, Mafuyu, Ena, Mizuki và Honami.

## ✨ Tính năng nổi bật

⚔️ **Hệ thống Combat chuyên sâu**
*   **Action Value (AV)**: Tốc độ quyết định thứ tự lượt đánh (Speed-based Timeline), cho phép các nhân vật có tốc độ cao tấn công nhiều lần trước khi kẻ thù kịp phản ứng.
*   **Tương khắc nguyên tố**: Khai thác điểm yếu của kẻ địch thông qua 5 hệ thuộc tính (**Cool, Happy, Cute, Mysterious, Pure**).
*   **Hiệu ứng đa dạng**: Các nhân vật có khả năng tương tác chéo (Synergy). Ví dụ: Ichika và Mafuyu cộng dồn sát thương hiệu ứng Chảy máu (Bleed) cực mạnh.

🗺️ **Khám phá Thế giới & Cốt truyện**
*   **Nhiều bản đồ**: Bắt đầu từ sự cố tại Màn mở đầu (Prologue), nhận nhiệm vụ dọn dẹp tại Nhà kho (Warehouse), và đối đầu với Boss Đội Trưởng tại Bến cảng (Harbor).
*   **Kịch bản phân nhánh (Scenario-based)**: Hệ thống chiến đấu hỗ trợ các kịch bản đặc biệt như Boss nhiều Phase, NPC cứu viện giữa trận, hoặc thay đổi đội hình tức thời.
*   **Safehouse (Căn cứ)**: Nơi các nhân vật nghỉ ngơi, tương tác và trò chuyện. Bầu không khí và các đoạn hội thoại sẽ thay đổi linh hoạt theo tiến độ nhiệm vụ.

⚙️ **Cơ chế Tiện ích**
*   **Auto-Leveling Quái vật**: Trò chơi tự động tính toán cấp độ kẻ địch dựa trên tiến trình cốt truyện để luôn duy trì độ khó vừa phải.
*   **Skip Battle**: Chức năng bỏ qua trận đấu rảnh tay dành cho các trận đánh cày cuốc (Chỉ vô hiệu hóa ở các trận Boss cốt truyện).
*   **Sandbox & Training**: Chế độ tự do cho phép người chơi thiết lập đội hình hai bên, chọn quái vật và cấp độ để luyện tập.

## 📁 Cấu trúc Dự án

Dự án được thiết kế theo kiến trúc **Domain-Driven**, dễ dàng bảo trì và mở rộng.
*(Xem chi tiết tại [ARCHITECTURE.md](ARCHITECTURE.md))*

*   `Entities/`: Định nghĩa chỉ số, kỹ năng của Nhân vật (Phe ta) và Kẻ địch.
*   `Maps/`: Chứa các màn chơi (Overworld), sự kiện Trigger và các Stage quản lý theo cốt truyện.
*   `Scripts/`: Chứa Lõi trò chơi (GameManager), Hệ thống tính toán (Damage, Turn, Level) và Battle Engine.
*   `UI/`: Giao diện người dùng (Hội thoại, Menu, HUD trong trận đấu).
*   `Assets/`: Tài nguyên hình ảnh và âm thanh (Kenney Assets).

## 🚀 Hướng dẫn cài đặt

1. Tải và cài đặt **[Godot Engine 4.2+](https://godotengine.org/download/)**.
2. Clone repository này về máy của bạn:
   ```bash
   git clone https://github.com/kei-kochiya/SekaiRPG.git
   ```
3. Mở Godot Engine, chọn **Import** (Nhập), tìm đến thư mục bạn vừa clone và chọn file `project.godot`.
4. Nhấn phím **F5** (hoặc biểu tượng Play góc trên bên phải) để bắt đầu trò chơi!

## 🤝 Tham gia Phát triển

Nếu bạn muốn đóng góp mã nguồn hoặc thiết kế thêm nhân vật/boss mới, vui lòng đọc kỹ tài liệu **[ARCHITECTURE.md](ARCHITECTURE.md)** để hiểu rõ luồng hoạt động của hệ thống `Entity`, `BattleInitializer` và `Scenarios` trước khi tạo Pull Request.

---
*Dự án phi lợi nhuận (Fan-made game). Mọi tài nguyên đồ họa (UI, Tileset) đều thuộc bản quyền của tác giả Kenney (kenney.nl).*
