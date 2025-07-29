#!/bin/sh

SHDIR="$(cd $(dirname $0) && echo ${PWD})"
test -d "${SHDIR}" || exit 1
LUADIR="${SHDIR}/src/lua"

export LUA_PATH="${LUADIR}/?.lua;${LUA_PATH}"
# export LUA_CPATH="lua_modules/lib/lua/${LUA_VER}/?.so;${LUA_CPATH}"

exec lpx "${LUADIR}/osbpb/init.lua" "${@}"

