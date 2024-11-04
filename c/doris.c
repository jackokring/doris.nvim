#include <lua.h>
#include <lauxlib.h>

static int l_nop (lua_State *L) {
  return 0;
}

static const struct luaL_reg doris [] = {
  {"nop", l_nop},
  {NULL, NULL}  /* sentinel */
};

int luaopen_doris (lua_State *L) {
  luaL_openlib(L, "doris", doris, 0);// 0 upvalues
  return 1;
}

//in lua directory: lua/doris/?.lua
//doris = loadlib("../../doris.so", "luaopen_doris")
