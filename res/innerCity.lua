return
{
	id = 1003,               --关卡ID
	name = inner_city2_temp,  --关卡名称
	grid_size = { x = 1, y = 1 }, --格子尺寸(米)
	grids = { x = 150, y = 260 }, --格子数量(格)
	tiles = { x = 1, y = 1 }, --平铺数量(倍),总格子数 = 格子数量 x 平铺数量
	builds =                 --功能建筑列表
	{
		[1001] = { build_type = 1, x = 74, y = 161, offset = { x = -0.4000015, y = 0.1999969 }, x_flip = 1 },
		[2001] = { build_type = 2, x = 52, y = 88, offset = { x = 0, y = 0.2000046 }, x_flip = 1 },
		[18001] = { build_type = 18, x = 137, y = 175, offset = { x = 0, y = 0 }, x_flip = 1 },
		[19001] = { build_type = 19, x = 114, y = 185, offset = { x = -0.4000015, y = -0.1999969 }, x_flip = 1 },
		[102001] = { build_type = 102, x = 38, y = 215, offset = { x = 0, y = 0 }, x_flip = 1 },
		[102002] = { build_type = 102, x = 105, y = 215, offset = { x = 0, y = 0 }, x_flip = 1 },
		[103001] = { build_type = 103, x = 30, y = 203, offset = { x = 0, y = 0.1999969 }, x_flip = 1 },
		[103002] = { build_type = 103, x = 46, y = 203, offset = { x = 0, y = 0.1999969 }, x_flip = 1 },
		[103003] = { build_type = 103, x = 30, y = 210, offset = { x = 0, y = 0 }, x_flip = 1 },
		[103004] = { build_type = 103, x = 46, y = 210, offset = { x = 0, y = 0 }, x_flip = 1 },
		[103005] = { build_type = 103, x = 30, y = 217, offset = { x = 0, y = -0.1999969 }, x_flip = 1 },
		[103006] = { build_type = 103, x = 46, y = 217, offset = { x = 0, y = -0.1999969 }, x_flip = 1 },
		[103007] = { build_type = 103, x = 30, y = 224, offset = { x = 0, y = -0.3999939 }, x_flip = 1 },
		[103008] = { build_type = 103, x = 46, y = 224, offset = { x = 0, y = -0.3999939 }, x_flip = 1 },
		[103009] = { build_type = 103, x = 30, y = 230, offset = { x = 0, y = 0.4000092 }, x_flip = 1 },
		[103010] = { build_type = 103, x = 46, y = 230, offset = { x = 0, y = 0.4000092 }, x_flip = 1 },
		[103011] = { build_type = 103, x = 97, y = 203, offset = { x = -0.1999969, y = 0.1999969 }, x_flip = 1 },
		[103012] = { build_type = 103, x = 113, y = 203, offset = { x = 0, y = 0.1999969 }, x_flip = 1 },
		[103013] = { build_type = 103, x = 97, y = 210, offset = { x = -0.1999969, y = 0 }, x_flip = 1 },
		[103014] = { build_type = 103, x = 113, y = 210, offset = { x = 0, y = 0 }, x_flip = 1 },
		[103015] = { build_type = 103, x = 97, y = 217, offset = { x = -0.1999969, y = -0.1999969 }, x_flip = 1 },
		[103016] = { build_type = 103, x = 113, y = 217, offset = { x = 0, y = -0.1999969 }, x_flip = 1 },
		[103017] = { build_type = 103, x = 97, y = 224, offset = { x = -0.1999969, y = -0.3999939 }, x_flip = 1 },
		[103018] = { build_type = 103, x = 113, y = 224, offset = { x = 0, y = -0.3999939 }, x_flip = 1 },
		[103019] = { build_type = 103, x = 97, y = 230, offset = { x = -0.1999969, y = 0.4000092 }, x_flip = 1 },
		[103020] = { build_type = 103, x = 113, y = 230, offset = { x = 0, y = 0.4000092 }, x_flip = 1 },
		[104001] = { build_type = 104, x = 38, y = 240, offset = { x = 0, y = -0.1999969 }, x_flip = 1 },
		[104002] = { build_type = 104, x = 105, y = 240, offset = { x = 0, y = 0 }, x_flip = 1 },
		[105001] = { build_type = 105, x = 50, y = 196, offset = { x = 0, y = 0 }, x_flip = 1 },
		[105002] = { build_type = 105, x = 54, y = 196, offset = { x = 0, y = 0 }, x_flip = 1 },
		[106001] = { build_type = 106, x = 104, y = 158, offset = { x = -0.1999969, y = 0.4000092 }, x_flip = 1 },
		[107001] = { build_type = 107, x = 96, y = 136, offset = { x = 0.4000015, y = 0 }, x_flip = 1 },
		[108001] = { build_type = 108, x = 35, y = 136, offset = { x = 0, y = 0.1999969 }, x_flip = 1 },
		[109001] = { build_type = 109, x = 41, y = 156, offset = { x = 0.4000015, y = 0 }, x_flip = 1 },
		[110001] = { build_type = 110, x = 76, y = 183, offset = { x = 0, y = 0 }, x_flip = 1 },
		[111001] = { build_type = 111, x = 113, y = 142, offset = { x = 0.2000046, y = 0 }, x_flip = 1 },
		[112001] = { build_type = 112, x = 62, y = 232, offset = { x = 0.4000015, y = 0 }, x_flip = 1 },
		[112002] = { build_type = 112, x = 80, y = 232, offset = { x = 0, y = 0 }, x_flip = 1 },
		[113001] = { build_type = 113, x = 57, y = 203, offset = { x = 0.4000015, y = -0.3999939 }, x_flip = 1 },
		[114001] = { build_type = 114, x = 52, y = 136, offset = { x = -0.2000008, y = 0.1999969 }, x_flip = 1 },
		[115001] = { build_type = 115, x = 32, y = 180, offset = { x = -0.2000008, y = 0.4000092 }, x_flip = 1 },
		[116001] = { build_type = 116, x = 85, y = 203, offset = { x = -0.4000015, y = -0.3999939 }, x_flip = 1 },
	},
	collisions = {
	},
}
