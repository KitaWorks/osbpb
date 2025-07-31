#!/bin/sh


# ----------------------------------------------------------------------------
#
# CONFIG
#
# ----------------------------------------------------------------------------

OUTDIR="${OUTDIR:-build}"
OUT="${OUT:-${OUTDIR}/osbpb}"

CC="${CC:-cc}"
# pure linking with ld without additional args would lose the `_start` symbol,
# so use CC for now
LD="${LD:-${CC}}"

LUAVER="${LUAVER:-5.4}"
LUA="${LUA:-lua${LUAVER}}"

IFLAGS="${IFLAGS}"
CFLAGS="${CFLAGS:- -std=c99}"
LDFLAGS="${LDFLAGS} -lm -lc"


# ----------------------------------------------------------------------------
#
# UTIL / TRAP / SAFETY BELT
#
# ----------------------------------------------------------------------------

print_raw() {
  printf '%s' "${*}"
}

log_error() {
  echo "[ERROR] ${*}" >&2
}

log_info() {
  echo "[INFO] ${*}" >&2
}

log_compile() {
  tag="${1}"
  shift 1
  echo "[${tag}] ${*}" >&2
}

try_mkdir() {
  test -d "${1}" || mkdir -p "${1}"
}


cleanup(){
  trap - EXIT
}

panic(){
  test -n "${*}" && echo "[FATAL] ${*}" >&2
  echo '[BUILD FAILURE]'
  cleanup
  exit 1
}

set -e
trap 'panic' EXIT


# ----------------------------------------------------------------------------
#
# MAIN PROGRAM
#
# ----------------------------------------------------------------------------

cd "$(dirname $0)"

PROJDIR="${PWD}"

TOOLDIR="${PROJDIR}/tool"
SRCDIR="${PROJDIR}/src"
SRCLUADIR="${SRCDIR}/lua"

SRCS="$(find ${SRCDIR} -maxdepth 1 -name '*.c')"
# filled by compile_*
OBJS=

LIBDIR="${PROJDIR}/lib"

LIB_LUA_DIR="${LIBDIR}/lua"
SRCS="${SRCS} ${LIB_LUA_DIR}/onelua.c"
CFLAGS="${CFLAGS} -DMAKE_LIB=1"
IFLAGS="${IFLAGS} -I${LIB_LUA_DIR}"

# weird behaviour: reading and writting has different result under test,
# cat and output redirection, so added {} to avoid it
CONFIG="{
  CC ${CC}
  LD ${LD}
  LUAVER ${LUAVER}
  LUA ${LUA}
  IFLAGS ${IFLAGS}
  CFLAGS ${CFLAGS}
  LDFLAGS ${LDFLAGS}
}"
CONFIG_CACHE_FILE="${OUTDIR}/.config"


# -- MAIN PROCEDURE ----------------------------------------------------------

try_mkdir "${OUTDIR}" ||
  panic "unable to create output directory '${OUTDIR}'"

IS_CONFIG_SAME=n
test -f "${CONFIG_CACHE_FILE}" &&
  test "$(cat ${CONFIG_CACHE_FILE})" = "${CONFIG}" &&
  IS_CONFIG_SAME=y

HAS_SOURCE_CHANGE=n

compile_c_obj() {
  srcfile="${1}"
  objfile="${2}"
  timestamp="$(stat -c %Y ${srcfile})"
  timestamp_cache_file="${OUTDIR}/.timestamp.$(basename ${srcfile})"

  test "${IS_CONFIG_SAME}" = y &&
    test -f "${timestamp_cache_file}" &&
    test "$(cat ${timestamp_cache_file})" = "${timestamp}" &&
    return 0

  log_compile CC "${objfile}"
  "${CC}" ${IFLAGS} ${CFLAGS} -c -o "${objfile}" "${srcfile}"
  HAS_SOURCE_CHANGE=y
  # update timestamp cache
  print_raw "${timestamp}" >"${timestamp_cache_file}"
}


# generate header for osbpb.lua binary for embedding
"${LUA}" "${TOOLDIR}/onec.lua" -o "${OUTDIR}/osbpb.lua" -m osbpb.init \
  -C "${SRCLUADIR}" .
try_mkdir "${OUTDIR}/include"
"${LUA}" "${TOOLDIR}/bin2c.lua" -o "${OUTDIR}/include/osbpb-lua.h" \
  -n osbpb_lua "${OUTDIR}/osbpb.lua"
IFLAGS="${IFLAGS} -I${OUTDIR}/include"

for srcfile in ${SRCS}; do
  source_name_nosuffix="$(basename ${srcfile%%.c})"
  objfile="${OUTDIR}/${source_name_nosuffix}.o"
  OBJS="${OBJS} ${objfile}"
  compile_c_obj "${srcfile}" "${objfile}"
done

# link
if test "${HAS_SOURCE_CHANGE}" = y; then
  log_compile LD "${OUT}"
  "${LD}" -o "${OUT}" ${OBJS} ${LDFLAGS}
fi

cleanup
echo '[BUILD SUCCESS]'

print_raw "${CONFIG}" >"${CONFIG_CACHE_FILE}"

