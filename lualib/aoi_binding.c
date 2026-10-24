#include "aoi.h"
#include "lauxlib.h"
#include "lua.h"

#include <stdint.h>

#define AOI_MT "aoi_space"

struct cb_ctx {
	lua_State *L;
	int index;
	int n;
};

static struct aoi_space *check_space(lua_State *L, int idx) {
	struct aoi_space **sp = luaL_checkudata(L, idx, AOI_MT);
	if (*sp == NULL) {
		luaL_error(L, "aoi space released");
	}
	return *sp;
}

static void on_message(void *ud, uint32_t watcher, uint32_t marker) {
	struct cb_ctx *ctx = ud;
	lua_State *L = ctx->L;
	lua_createtable(L, 2, 0);
	lua_pushinteger(L, (lua_Integer)watcher);
	lua_rawseti(L, -2, 1);
	lua_pushinteger(L, (lua_Integer)marker);
	lua_rawseti(L, -2, 2);
	lua_rawseti(L, ctx->index, ++ctx->n);
}

static int lnew(lua_State *L) {
	struct aoi_space **sp = lua_newuserdatauv(L, sizeof(*sp), 0);
	*sp = aoi_new();
	if (*sp == NULL) {
		return luaL_error(L, "aoi_new failed");
	}
	luaL_setmetatable(L, AOI_MT);
	return 1;
}

static int lupdate(lua_State *L) {
	struct aoi_space *space = check_space(L, 1);
	lua_Integer id = luaL_checkinteger(L, 2);
	const char *mode = luaL_checkstring(L, 3);
	float pos[3];
	if (id < 0 || (uint64_t)id > UINT32_MAX) {
		return luaL_error(L, "aoi id out of range");
	}
	pos[0] = (float)luaL_checknumber(L, 4);
	pos[1] = (float)luaL_checknumber(L, 5);
	pos[2] = (float)luaL_optnumber(L, 6, 0);
	aoi_update(space, (uint32_t)id, mode, pos);
	return 0;
}

static int lmessage(lua_State *L) {
	struct aoi_space *space = check_space(L, 1);
	struct cb_ctx ctx;
	ctx.L = L;
	ctx.n = 0;
	lua_newtable(L);
	ctx.index = lua_gettop(L);
	aoi_message(space, on_message, &ctx);
	return 1;
}

static int lrelease(lua_State *L) {
	struct aoi_space **sp = luaL_checkudata(L, 1, AOI_MT);
	if (*sp != NULL) {
		aoi_release(*sp);
		*sp = NULL;
	}
	return 0;
}

static const luaL_Reg space_mt[] = {
	{"update", lupdate},
	{"message", lmessage},
	{"release", lrelease},
	{"__gc", lrelease},
	{NULL, NULL},
};

LUAMOD_API int luaopen_aoi_c(lua_State *L) {
	luaL_checkversion(L);
	luaL_newmetatable(L, AOI_MT);
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");
	luaL_setfuncs(L, space_mt, 0);
	lua_pop(L, 1);

	luaL_Reg lib[] = {
		{"new", lnew},
		{NULL, NULL},
	};
	luaL_newlib(L, lib);
	return 1;
}
