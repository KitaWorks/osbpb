#!/bin/sh

TMPFILE="$(mktemp -t osbpb-make.XXXXXX)"

cleanup(){
  trap - EXIT
  rm -rf "${TMPFILE}"
}

panic(){
  echo '[BUILD FAILURE]'
  cleanup
  exit 1
}

set -e
trap 'panic' EXIT

cd "$(dirname $0)"

PROJDIR="${PWD}"
LUA="${LUA:-lua}"

TOOLDIR="${PROJDIR}/tool"
SRCDIR="${PROJDIR}/src"
SRCLUADIR="${SRCDIR}/lua"

"${LUA}" "${TOOLDIR}/onec.lua" -o "${TMPFILE}" -m osbpb.init -C "${SRCLUADIR}" .

cleanup
echo '[BUILD SUCCESS]'

