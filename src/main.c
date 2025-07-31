/* @indent space 2 */
/* @syntax c 99 */
/* @width 80 */

/* ------------------------------------------------------------------------ *\
|
| osbpb.lua wrapper which loads osbpb.init
|
\* ------------------------------------------------------------------------ */

#include "stdio.h"

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

/* -- incbin -------------------------------------------------------------- */
#include "osbpb-lua.h"

/* -- libraries ----------------------------------------------------------- */
#include "lualinux.h"

/* -- logger -------------------------------------------------------------- */
#define osbpb_logf_info(fmt, ...) fprintf(stderr, "[INNFO] " fmt, __VA_ARGS__)
#define osbpb_logf_error(fmt, ...) fprintf(stderr, "[ERROR] " fmt, __VA_ARGS__)

#define osbpb_logf(level, fmt, ...) osbpb_logf_##level(fmt, __VA_ARGS__)
#define osbpb_log(level, str) osbpb_logf(level, "%s\n", str)

/* -- functions ----------------------------------------------------------- */
int osbpb_lua_error_traceback(lua_State *L){
  osbpb_logf(error, "Caught error in lua runtime: %s\n", lua_tostring(L, -1));
  luaL_traceback(L, L, NULL, 1);
  osbpb_logf(error, "%s\n", lua_tostring(L, -1));
  lua_pop(L, 1);
  return 0;
}

int main(int argc, char *const argv[]) {
  int ret = 1;

  lua_State *L = luaL_newstate();
  if (!L) {
    osbpb_log(error, "Unable to create lua vm.");
    goto fail_main_newstate;
  }

  /* push args */
  lua_createtable(L, argc + 1, 1);
  for (int i = 0; i < argc; ++i) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i);
  }
  lua_setglobal(L, "arg");

  luaL_openlibs(L);
  luaL_requiref(L, "lualinux", luaopen_lualinux, 0);

  lua_gc(L, LUA_GCGEN, 0, 0);

  int osbpb_lua_stat = luaL_loadbuffer(
    L,
    osbpb_lua, osbpb_lua_len,
    "osbpb.lua"
  );

  if (osbpb_lua_stat != LUA_OK) {
    osbpb_log(error, "Unable to load osbpb.lua.");
    goto fail_main_load_lua;
  }

  lua_pushcfunction(L, osbpb_lua_error_traceback);
  osbpb_lua_stat = lua_pcall(L, 1, 0, -1);
  lua_pop(L, 1);

  if (osbpb_lua_stat != LUA_OK) {
    osbpb_log(error, "osbpb.lua reports a failure status.");
    goto fail_main_pcall;
  }

  ret = 0;

fail_main_pcall:
fail_main_load_lua:
  lua_close(L);
fail_main_newstate:
  return ret;
}

