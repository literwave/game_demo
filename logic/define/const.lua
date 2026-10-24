-- 全局变量文件

RES_TYPE_MONEY = 1
USER_HEART_BEAT_INTERVAL = 5
USER_HEART_BEAT_TIMEOUT = 15
USER_HEART_BEAT_CHECK_INTERVAL = 5

TEST_SERVER_GROUP_TBL = {
	[99] = true,
}

REWARD_TYPE_ITEM = 1
REWARD_TYPE_RES = 2
REWARD_TYPE_HERO = 3
REWARD_TYPE_SOLDIER = 4

LOCK_TIME = 1000

BUILD_TYPE = {
	MAIN_HALL = 1,
}

WORK_QUEUE_TYPE = {
	BUILD = 1,
}

SEX_NONE = 0
SEX_MAN = 1
SEX_WOMAN = 2

RES_TYPE_FOOD = 1
RES_TYPE_WARER = 2
RES_TYPE_WOOD = 3

COST_TYPE = {
	DIAMOND = 1,
	RES = 2,
	ITEM = 3,
}

ITEM_KIND = {
	RES = 1,
	HERO_CHIP = 2,
	GIFT = 3,
	HERO_EQUIP = 4,
	RANDOM_REWARD = 5,
	SOLDIER = 6,
	VIP = 7,
}

NO_NAME = ""
USER_NAME_MAX_LEN = 12

FIRST_QUEUE_IDX = 1
QUEUE_PRIORITY = {1, 2, 3}


-- 资源流水原因，reason_list[1]
FLOW_REASON = {
	RECHARGE = 1,
	WIZ = 2,
	MAIL = 3,
	LOTTERY = 4,
	BUY_BUILD_QUEUE = 5,
	GM = 6,
	TASK = 7,
	ACTIVITY = 8,
	MARCH = 9,
}

ONE_HOUR_SEC = 3600
ONE_DAY_HOUR = 24
ONE_DAY_SEC = ONE_DAY_HOUR * ONE_HOUR_SEC

INT_SIZE = 32

-- 与 res/map/map_res.lua 格子 type 一致
MAP_CELL_TYPE = {
	OBSTRUCT = 0,
	SYS_FORTRESS = 50,
	SYS_CITY = 51,
	WOOD = 52,
	IRON = 53,
	STONE = 54,
	GRAIN = 55,
	FORTRESS = 56,
}

ENTITY_TYPE = {
	MAIN_HALL = 1,
	CITY = 1,
	TROOP = 2,
	MONSTER_GROUP = 3,
}

-- 和 EntityType / TargetType 配置一致
TARGET_TYPE = {
	RETURN_CITY = 1,
	ATTACK_MONSTER = 2,
}

MARCH_STATE = {
	MOVING = 1,
	ARRIVED = 2,
}

-- 格/秒。协议里没有速度配置，先用固定值
MARCH_SPEED = 5
AOI_RADIUS = 10

-- 实体 id 分段，避免主城、部队、怪物组互相撞
ENTITY_ID = {
	MONSTER = 1000000000000000,
	TROOP = 2000000000000000,
	CITY = 3000000000000000,
}

function city_entity_id(user_id)
	return ENTITY_ID.CITY + user_id
end

function troop_entity_id(user_id, troop_idx)
	return ENTITY_ID.TROOP + user_id * 100 + troop_idx
end

function monster_entity_id(group_id)
	return ENTITY_ID.MONSTER + group_id
end

TASK_TYPE = {
	MAIN = 1,
	DAILY = 2,
	WEEK = 3,
}

TASK_STATE = {
	DOING = 0,
	CAN_GET = 1,
	GOT = 2,
}

TASK_COND = {
	LOGIN = 1,
	BUILD_LV = 2,
	HERO_CNT = 3,
	LOTTERY = 4,
	HEAD_ICON = 5,
	OWN_ITEM = 6,
	MARCH = 7,
	POWER = 8,
}

ACTIVITY_TYPE = {
	LOGIN = 1,
	RANK = 2,
	LOTTERY = 3,
	RES_RATE = 4,
	GIFT = 5,
	ONLINE = 6,
	EXCHANGE = 7,
}

ACTIVITY_STATE = {
	CLOSED = 0,
	OPEN = 1,
	END = 2,
}

ACTIVITY_TIME = {
	ALWAYS = 1,
	OPEN_DAY = 2,
	WEEKDAY = 3,
	DAILY = 4,
}

RANK_TYPE = {
	POWER = 1,
	CITY = 2,
}

EVENT = {
	ON_USER_LOGIN = "on_user_login",
	ON_USER_LOGOUT = "on_user_logout",
	KICK_USER = "kick_user",
	ON_SYSTEM_OPEN = "on_system_open",
	-- 以下是 agent 内的玩法触发，用 EVENT.dispatch 同步分发，监听方在玩家队列里执行
	-- 跨天/跨周/跨月 (user_id)：在线时由心跳检测，离线跨过的在登录时补发一次。跨周、跨月前一定先发跨天
	ON_NEW_DAY = "on_new_day",
	ON_NEW_WEEK = "on_new_week",
	ON_NEW_MONTH = "on_new_month",
	ON_ONLINE_MINUTE = "on_online_minute",
	ON_LOTTERY = "on_lottery",
	ON_HEAD_ICON = "on_head_icon",
	ON_HERO_ADD = "on_hero_add",
	ON_BUILD_LEVEL = "on_build_level",
	ON_ITEM_CHANGE = "on_item_change",
	ON_MARCH = "on_march",
	ON_RECHARGE = "on_recharge",
	-- 计算类：传一个 ctx 表，监听方同步改里面的倍率，发起方 dispatch 完再用
	ON_CALC_ITEM_REWARD = "on_calc_item_reward",	-- (user_id, ctx{item_id, rate=1})，取最大倍率
	ON_CALC_LOTTERY_COST = "on_calc_lottery_cost",	-- (user_id, ctx{lottery_id, rate=100})，百分比，取最低
}
