#!/bin/sh

TMPDIR="$(mktemp -d -t osbpb-make.XXXXXX)"

CC="${CC:-cc}"
LUAVER="${LUAVER:-5.4}"
LUA="${LUA:-lua${LUAVER}}"

CFLAGS="${CFLAGS:- -std=c99}"
LDFLAGS="${LDFLAGS} -static"
IFLAGS="${IFLAGS}"

cleanup(){
  trap - EXIT
  rm -rf "${TMPDIR}"
}

panic(){
  test -n "${*}" && echo "${*}" >&2
  echo '[BUILD FAILURE]'
  cleanup
  exit 1
}

set -e
trap 'panic' EXIT

cd "$(dirname $0)"

PROJDIR="${PWD}"

TOOLDIR="${PROJDIR}/tool"
SRCDIR="${PROJDIR}/src"
SRCLUADIR="${SRCDIR}/lua"

SRCS="$(find ${SRCDIR} -maxdepth 1 -name '*.c')"

LIBDIR="${PROJDIR}/lib"

LIB_LUA_DIR="${LIBDIR}/lua"
SRCS="${SRCS} ${LIB_LUA_DIR}/onelua.c"
CFLAGS="${CFLAGS} -DMAKE_LIB=1"
IFLAGS="${IFLAGS} -I${LIB_LUA_DIR}"

# LIB_ARGPARSE_DIR="${LIBDIR}/argparse"

# LIB_LUAPOSIX_DIR="${LIBDIR}/luaposix"
# SRCS="${SRCS} $(find ${LIB_LUAPOSIX_DIR}/ext -name '*.c'))"
# IFLAGS="${IFLAGS} -I${LIB_LUAPOSIX_DIR}/ext/include"

  # -C "${LIB_LUAPOSIX_DIR}/lib" posix -i posix.version "return 'posix for lua, bundled in osbpb'" \
"${LUA}" "${TOOLDIR}/onec.lua" -o "${TMPDIR}/osbpb.lua" -m osbpb.init \
  -C "${SRCLUADIR}" .
mkdir "${TMPDIR}/include"
"${LUA}" "${TOOLDIR}/bin2c.lua" -o "${TMPDIR}/include/osbpb-lua.h" -n osbpb_lua "${TMPDIR}/osbpb.lua"
IFLAGS="${IFLAGS} -I${TMPDIR}/include"

"${CC}" "-I${TMPDIR}/include" ${IFLAGS} ${CFLAGS} -o "${TMPDIR}/osbpb" ${SRCS} ${LDFLAGS}
cp "${TMPDIR}/osbpb" "${PROJDIR}/"

cleanup
echo '[BUILD SUCCESS]'

