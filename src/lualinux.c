#include "lualinux.h"

#define _GNU_SOURCE 1

#include "unistd.h"
#include "sched.h"
#include "sys/mount.h"

#include "lua.h"
#include "lauxlib.h"

typedef struct { const char *name; int value; } lualinux_constant_t;

#define lualinux_constant_direct(v) { .name = #v, .value = v }

int lualinux_chroot(lua_State *L) {
  const char *pathname = luaL_checkstring(L, 1);
  int ret = chroot(pathname);
  lua_pushinteger(L, ret);
  return 1;
}

int lualinux_mount(lua_State *L) {
  const char *source = luaL_optstring(L, 1, NULL);
  const char *dest = luaL_checkstring(L, 2);
  const char *type = luaL_optstring(L, 3, NULL);
  long flags = luaL_optinteger(L, 4, 0);
  const char *opts = luaL_optstring(L, 5, NULL);

  int ret = mount(source, dest, type, flags, opts);

  lua_pushinteger(L, ret);
  return 1;
}

int lualinux_umount(lua_State *L) {
  const char *dest = luaL_checkstring(L, 1);
  long flags = luaL_optinteger(L, 2, 0);

  int ret = umount2(dest, flags);

  lua_pushinteger(L, ret);
  return 1;
}

int lualinux_unshare(lua_State *L) {
  long flags = luaL_checkinteger(L, 1);

  int ret = unshare(flags);

  lua_pushinteger(L, ret);
  return 1;
}

const luaL_Reg lualinux_funcs[] = {
  { "chroot",  lualinux_chroot },
  { "mount",   lualinux_mount },
  { "umount",  lualinux_umount },
  { "unshare", lualinux_unshare },
  { NULL,      NULL }
};

const lualinux_constant_t lualinux_constants[] = {
  lualinux_constant_direct(CLONE_VM),
  lualinux_constant_direct(CLONE_FS),
  lualinux_constant_direct(CLONE_FILES),
  lualinux_constant_direct(CLONE_SIGHAND),
  lualinux_constant_direct(CLONE_PTRACE),
  lualinux_constant_direct(CLONE_VFORK),
  lualinux_constant_direct(CLONE_PARENT),
  lualinux_constant_direct(CLONE_THREAD),
  lualinux_constant_direct(CLONE_NEWNS),
  lualinux_constant_direct(CLONE_SYSVSEM),
  lualinux_constant_direct(CLONE_SETTLS),
  lualinux_constant_direct(CLONE_PARENT_SETTID),
  lualinux_constant_direct(CLONE_CHILD_CLEARTID),
  lualinux_constant_direct(CLONE_DETACHED),
  lualinux_constant_direct(CLONE_UNTRACED),
  lualinux_constant_direct(CLONE_CHILD_SETTID),
  lualinux_constant_direct(CLONE_NEWUTS),
  lualinux_constant_direct(CLONE_NEWIPC),
  lualinux_constant_direct(CLONE_NEWUSER),
  lualinux_constant_direct(CLONE_NEWPID),
  lualinux_constant_direct(CLONE_NEWNET),
  lualinux_constant_direct(CLONE_IO),

  lualinux_constant_direct(MS_RDONLY),
  lualinux_constant_direct(MS_NOSUID),
  lualinux_constant_direct(MS_NODEV),
  lualinux_constant_direct(MS_NOEXEC),
  lualinux_constant_direct(MS_SYNCHRONOUS),
  lualinux_constant_direct(MS_REMOUNT),
  lualinux_constant_direct(MS_MANDLOCK),
  lualinux_constant_direct(MS_DIRSYNC),
  lualinux_constant_direct(MS_NOATIME),
  lualinux_constant_direct(MS_NODIRATIME),
  lualinux_constant_direct(MS_BIND),
  lualinux_constant_direct(MS_MOVE),
  lualinux_constant_direct(MS_REC),
  lualinux_constant_direct(MS_SILENT),
  lualinux_constant_direct(MS_POSIXACL),
  lualinux_constant_direct(MS_UNBINDABLE),
  lualinux_constant_direct(MS_PRIVATE),
  lualinux_constant_direct(MS_SLAVE),
  lualinux_constant_direct(MS_SHARED),
  lualinux_constant_direct(MS_RELATIME),
  lualinux_constant_direct(MS_KERNMOUNT),
  lualinux_constant_direct(MS_I_VERSION),
  lualinux_constant_direct(MS_STRICTATIME),
  lualinux_constant_direct(MS_ACTIVE),
  lualinux_constant_direct(MS_NOUSER),

  lualinux_constant_direct(MNT_FORCE),
  lualinux_constant_direct(MNT_DETACH),
  lualinux_constant_direct(MNT_EXPIRE),
  lualinux_constant_direct(UMOUNT_NOFOLLOW),

  { NULL, 0 },
};

int luaopen_lualinux(lua_State *L) {
  lua_newtable(L);

  luaL_setfuncs(L, lualinux_funcs, 0);

  for (const lualinux_constant_t *c = lualinux_constants; c->name; ++c) {
    lua_pushinteger(L, c->value);
    lua_setfield(L, -2, c->name);
  }

  return 1;
}

