return
{
	id = 1003,               --关卡ID
	name = innerCity2_temp,  --关卡名称
	gridSize = { x = 1, y = 1 }, --格子尺寸(米)
	grids = { x = 150, y = 260 }, --格子数量(格)
	tiles = { x = 1, y = 1 }, --平铺数量(倍),总格子数 = 格子数量 x 平铺数量
	builds =                 --功能建筑列表
	{
		[1001] = { buildType = 1, x = 74, y = 161, offset = { x = -0.4000015, y = 0.1999969 }, xFlip = 1 },
		[2001] = { buildType = 2, x = 52, y = 88, offset = { x = 0, y = 0.2000046 }, xFlip = 1 },
		[18001] = { buildType = 18, x = 137, y = 175, offset = { x = 0, y = 0 }, xFlip = 1 },
		[19001] = { buildType = 19, x = 114, y = 185, offset = { x = -0.4000015, y = -0.1999969 }, xFlip = 1 },
		[102001] = { buildType = 102, x = 38, y = 215, offset = { x = 0, y = 0 }, xFlip = 1 },
		[102002] = { buildType = 102, x = 105, y = 215, offset = { x = 0, y = 0 }, xFlip = 1 },
		[103001] = { buildType = 103, x = 30, y = 203, offset = { x = 0, y = 0.1999969 }, xFlip = 1 },
		[103002] = { buildType = 103, x = 46, y = 203, offset = { x = 0, y = 0.1999969 }, xFlip = 1 },
		[103003] = { buildType = 103, x = 30, y = 210, offset = { x = 0, y = 0 }, xFlip = 1 },
		[103004] = { buildType = 103, x = 46, y = 210, offset = { x = 0, y = 0 }, xFlip = 1 },
		[103005] = { buildType = 103, x = 30, y = 217, offset = { x = 0, y = -0.1999969 }, xFlip = 1 },
		[103006] = { buildType = 103, x = 46, y = 217, offset = { x = 0, y = -0.1999969 }, xFlip = 1 },
		[103007] = { buildType = 103, x = 30, y = 224, offset = { x = 0, y = -0.3999939 }, xFlip = 1 },
		[103008] = { buildType = 103, x = 46, y = 224, offset = { x = 0, y = -0.3999939 }, xFlip = 1 },
		[103009] = { buildType = 103, x = 30, y = 230, offset = { x = 0, y = 0.4000092 }, xFlip = 1 },
		[103010] = { buildType = 103, x = 46, y = 230, offset = { x = 0, y = 0.4000092 }, xFlip = 1 },
		[103011] = { buildType = 103, x = 97, y = 203, offset = { x = -0.1999969, y = 0.1999969 }, xFlip = 1 },
		[103012] = { buildType = 103, x = 113, y = 203, offset = { x = 0, y = 0.1999969 }, xFlip = 1 },
		[103013] = { buildType = 103, x = 97, y = 210, offset = { x = -0.1999969, y = 0 }, xFlip = 1 },
		[103014] = { buildType = 103, x = 113, y = 210, offset = { x = 0, y = 0 }, xFlip = 1 },
		[103015] = { buildType = 103, x = 97, y = 217, offset = { x = -0.1999969, y = -0.1999969 }, xFlip = 1 },
		[103016] = { buildType = 103, x = 113, y = 217, offset = { x = 0, y = -0.1999969 }, xFlip = 1 },
		[103017] = { buildType = 103, x = 97, y = 224, offset = { x = -0.1999969, y = -0.3999939 }, xFlip = 1 },
		[103018] = { buildType = 103, x = 113, y = 224, offset = { x = 0, y = -0.3999939 }, xFlip = 1 },
		[103019] = { buildType = 103, x = 97, y = 230, offset = { x = -0.1999969, y = 0.4000092 }, xFlip = 1 },
		[103020] = { buildType = 103, x = 113, y = 230, offset = { x = 0, y = 0.4000092 }, xFlip = 1 },
		[104001] = { buildType = 104, x = 38, y = 240, offset = { x = 0, y = -0.1999969 }, xFlip = 1 },
		[104002] = { buildType = 104, x = 105, y = 240, offset = { x = 0, y = 0 }, xFlip = 1 },
		[105001] = { buildType = 105, x = 50, y = 196, offset = { x = 0, y = 0 }, xFlip = 1 },
		[105002] = { buildType = 105, x = 54, y = 196, offset = { x = 0, y = 0 }, xFlip = 1 },
		[106001] = { buildType = 106, x = 104, y = 158, offset = { x = -0.1999969, y = 0.4000092 }, xFlip = 1 },
		[107001] = { buildType = 107, x = 96, y = 136, offset = { x = 0.4000015, y = 0 }, xFlip = 1 },
		[108001] = { buildType = 108, x = 35, y = 136, offset = { x = 0, y = 0.1999969 }, xFlip = 1 },
		[109001] = { buildType = 109, x = 41, y = 156, offset = { x = 0.4000015, y = 0 }, xFlip = 1 },
		[110001] = { buildType = 110, x = 76, y = 183, offset = { x = 0, y = 0 }, xFlip = 1 },
		[111001] = { buildType = 111, x = 113, y = 142, offset = { x = 0.2000046, y = 0 }, xFlip = 1 },
		[112001] = { buildType = 112, x = 62, y = 232, offset = { x = 0.4000015, y = 0 }, xFlip = 1 },
		[112002] = { buildType = 112, x = 80, y = 232, offset = { x = 0, y = 0 }, xFlip = 1 },
		[113001] = { buildType = 113, x = 57, y = 203, offset = { x = 0.4000015, y = -0.3999939 }, xFlip = 1 },
		[114001] = { buildType = 114, x = 52, y = 136, offset = { x = -0.2000008, y = 0.1999969 }, xFlip = 1 },
		[115001] = { buildType = 115, x = 32, y = 180, offset = { x = -0.2000008, y = 0.4000092 }, xFlip = 1 },
		[116001] = { buildType = 116, x = 85, y = 203, offset = { x = -0.4000015, y = -0.3999939 }, xFlip = 1 },
	},
	collisions = {
	},
}
