#!/bin/bash

WDIR=$(pwd)

PO_LANG=cs
RT_LANG=Czech

PO_FILE=cs.po

export TRANSLATOR_NAME=mkyral

cd lang

for BRANCH in $(find . -mindepth 1 -type d -printf "%P\n" |egrep -v "branch_3\.0|xmp")
do
  echo "==== Procesing branch $BRANCH ===="

  cd "$BRANCH"
  $WDIR/po2rtkeys.sh $PO_FILE $RT_LANG
  [ -f "${RT_LANG}.rtkeys" ] && mv "${RT_LANG}.rtkeys" "${RT_LANG}"
  cd - >/dev/null
  echo
done
