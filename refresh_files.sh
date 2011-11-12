#!/bin/bash

GET_FILE=default
WDIR=$(pwd)

PO_LANG=cs

cd lang

for BRANCH in $(find . -mindepth 1 -type d -printf "%P\n" |grep -v branch_3.0)
do
  echo "==== Refreshing branch $BRANCH ===="

  cd "$BRANCH"
  [ -f "$GET_FILE" ] && rm "$GET_FILE"
  [ -f "${GET_FILE}.dos" ] && rm "${GET_FILE}.dos"
  [ -f "${PO_LANG}.po.orig" ] && rm "${PO_LANG}.po.orig"
  mv "${PO_LANG}.po" "${PO_LANG}.po.orig"
  wget --no-verbose "http://rawtherapee.googlecode.com/hg/rtdata/languages/${GET_FILE}?r=${BRANCH}" -O "$GET_FILE"
  mv $GET_FILE ${GET_FILE}.dos
  cat ${GET_FILE}.dos |tr -d '\r' >${GET_FILE}
  $WDIR/rtkeys2pot.sh
  msgmerge "${PO_LANG}.po.orig" rawtherapee.pot >${PO_LANG}.po
  cd - >/dev/null
  echo
done
