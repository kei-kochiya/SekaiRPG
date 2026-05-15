extends Node
class_name EnvironmentEffects

"""
EnvironmentEffects: Tạo các hiệu ứng môi trường tinh tế (Hạt bụi, Đom đóm, Vignette).
Dùng để tăng tính thẩm mỹ và không khí (Atmosphere) cho các bản đồ.
"""

static func create_dust_particles(parent: Node, color: Color = Color(1, 0.9, 0.7, 0.4)) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.amount = 40
	particles.lifetime = 6.0
	particles.preprocess = 3.0
	particles.speed_scale = 0.5
	
	# Hình dáng và vị trí
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(800, 500)
	particles.position = Vector2(400, 300)
	
	# Chuyển động: Bay lơ lửng chậm
	particles.direction = Vector2(1, 0.5)
	particles.spread = 45
	particles.gravity = Vector2(0, 2)
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 15.0
	
	# Vẻ ngoài: Hạt nhỏ mờ ảo
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	particles.color = color
	
	# Hiệu ứng mờ dần
	var curve = Gradient.new()
	curve.set_color(0, Color(color.r, color.g, color.b, 0))
	curve.add_point(0.2, color)
	curve.add_point(0.8, color)
	curve.set_color(3, Color(color.r, color.g, color.b, 0))
	particles.color_ramp = curve
	
	parent.add_child(particles)
	return particles

static func create_fireflies(parent: Node) -> CPUParticles2D:
	var p = create_dust_particles(parent, Color(0.8, 1.0, 0.5, 0.6))
	p.amount = 25
	p.speed_scale = 0.3
	p.gravity = Vector2(0, -5) # Bay lên nhẹ
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 20.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	return p

static func add_vignette(parent: Node, strength: float = 0.3):
	var canvas = CanvasLayer.new()
	canvas.layer = 5
	parent.add_child(canvas)
	
	var rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Dùng Gradient để làm tối 4 góc (Sử dụng một shader đơn giản hoặc Texture)
	# Ở đây ta dùng 1 Texture đen mờ đơn giản nếu có, 
	# nhưng để tiện nhất ta sẽ dùng 1 GradientTexture2D
	var grad = GradientTexture2D.new()
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = Vector2(1.0, 1.0)
	
	var g = Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, strength))
	grad.gradient = g
	
	rect.texture = grad
	canvas.add_child(rect)
	return canvas
