# SekaiRPG

SekaiRPG là một trò chơi nhập vai (RPG) được xây dựng trên nền tảng Godot Engine 4.x, lấy cảm hứng từ các nhân vật trong series *Project Sekai*. Trò chơi kết hợp giữa lối chơi Overworld truyền thống và hệ thống chiến đấu theo lượt (Turn-based) chiều sâu.

## Tính năng nổi bật

- **Hệ thống chiến đấu theo lượt**: Sử dụng cơ chế **Action Value (AV)** để tính toán lượt đánh linh hoạt (tương tự Honkai: Star Rail).
- **Tương khắc thuộc tính**: Hệ thống 5 hệ (**Cool, Happy, Cute, Mysterious, Pure**) tạo tính chiến thuật cao.
- **Đội hình đa dạng**: Điều khiển các nhân vật quen thuộc như Ichika, Kanade, Mafuyu, Ena, Mizuki, và Honami.
- **Cốt truyện & Nhiệm vụ**: Khám phá các khu vực như Nhà kho (Warehouse), Bến cảng (Harbor) và Safehouse với kịch bản hội thoại phong phú.
- **Phát triển nhân vật**: Hệ thống thăng cấp và nâng cấp chỉ số thủ công bằng Skill Points (SP).
- **Sandbox Mode**: Chế độ thử nghiệm cho phép bạn tùy chỉnh đội hình phe ta và phe địch để test các chiến thuật.

## Cấu trúc dự án

- `Entities/`: Chứa các script định nghĩa nhân vật và kẻ địch.
- `Scenes/`: Chứa các màn chơi và giao diện chính.
- `Scripts/`: Logic cốt lõi (Battle, Core, Overworld, Systems).
- `UI/`: Các thành phần giao diện người dùng.
- `Data/`: Chứa dữ liệu hội thoại và cấu hình trận đấu dưới dạng JSON.

## Hướng dẫn khởi chạy

1. Tải và cài đặt **Godot Engine 4.x**.
2. Clone repository này về máy.
3. Mở Godot và chọn **Import**, sau đó tìm đến file `project.godot` trong thư mục dự án.
4. Nhấn **F5** để bắt đầu trò chơi.

## Công nghệ sử dụng

- **Engine**: Godot Engine 4.2+
- **Ngôn ngữ**: GDScript
- **Assets**: Kenney Assets (Micro Roguelike, RPG Urban Pack, v.v.)

---
