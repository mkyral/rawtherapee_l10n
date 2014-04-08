#!/bin/bash

if [ $# -ne 2 ]
then
  echo "Usage: $0 <po_file> <rt_language_file>"
  echo "  E.g: $0 cs.po Czech"
  exit 1
fi

po_file="$1"
orig_rt_file="$2"
tmp_rt_file=$(basename "$orig_rt_file").tmp
new_rt_file=$(basename "$orig_rt_file").rtkeys

po_file=${po_file%.po}.po

if [ ! -f "$po_file" ]
then
  echo "Error: File $po_file does not exists."
  exit 2
fi

if [ ! -f "$orig_rt_file" ]
then
  echo "Warning: File $orig_rt_file does not exists."
  echo "         The translation history could be not copied."
  echo "         You have to do it manually."
  [ -f "$new_rt_file" ] && rm $new_rt_file
else
  new_date=$(date '+%Y-%m-%d')
  new_name=${TRANSLATOR_NAME}

  # Copy translation history
  grep '^#' $orig_rt_file |grep -v "${new_date}" > $new_rt_file
  old_ver=$(tail -n 1 $new_rt_file | sed -e 's/#\([0-9]*\) .*$/\1/' -e 's/^0//')
  ((new_ver = old_ver + 1))
  printf "#%02d %s updated by %s\n" $new_ver "$new_date" "$new_name" >>$new_rt_file
fi

# initialization
in_msgid=0
in_msgstr=0
rt_key=
trans_text=

write_key()
{
  key="$1"
  text="$2"
  echo "$key" |sed 's/,/\n/g' |while read KEY
  do
    echo "${KEY};${text}" |sed 's/\\"/"/g' >> $tmp_rt_file
  done
}

while read -r LINE
do
  if [ $(echo "$LINE" | grep -c '^msgctxt') -gt 0 ]
  then
    continue
  fi

  if [ $(echo "$LINE" | grep -c '^#:') -gt 0 ]
  then
    if [ $in_msgid -gt 0 ]; then in_msgid=0; fi
    if [ $in_msgstr -gt 0 ]; then in_msgstr=0; fi

    if [ "$trans_text" -a "$rt_key" ]
    then
      write_key "$rt_key" "$trans_text"
    fi

    rt_key=$(echo "$LINE" |sed 's/\(#: *\)\(.*\)/\2/')
    trans_text=
    continue
  fi

  if [ $(echo "$LINE" | grep -c '^msgid') -gt 0 ]
  then
    if [ $(echo "$LINE" | grep -c '^msgid ""$') -gt 0 ]
    then
      in_msgid=1
    fi
    continue
  fi

  if [ $(echo "$LINE" | grep -c '^msgstr') -gt 0 ]
  then
    if [ $in_msgid -gt 0 ]; then in_msgid=0; fi

    if [ $(echo "$LINE" | grep -c '^msgstr ""$') -gt 0 ]
    then
      in_msgstr=1
    else
      trans_text=$(echo "$LINE" |sed 's/\(^msgstr "\)\(.*\)\("$\)/\2/')
      if [ "$trans_text" -a "$rt_key" ]
      then
        write_key "$rt_key" "$trans_text"
      fi
      in_msgstr=0
      rt_key=
      trans_text=
    fi
    continue
  fi

  if [ $(echo "$LINE" | grep -c '^".*"$') -gt 0 ]
  then
    if [ $in_msgid -gt 0 ]; then continue; fi

    if [ $in_msgstr -gt 0 ]
    then
      trans_text+=$(echo "$LINE" |sed 's/\(^"\)\(.*\)\("$\)/\2/')
    fi
    continue
  fi

  if [ $(echo "$LINE" | grep -c '^$') -gt 0 ]
  then
    if [ $in_msgid -gt 0 ]; then in_msgid=0; fi
    if [ $in_msgstr -gt 0 ]; then in_msgstr=0; fi

    if [ "$trans_text" -a "$rt_key" ]
    then
      write_key "$rt_key" "$trans_text"
    fi
    trans_text=
    rt_key=
    continue
  fi

done < $po_file

# Final line
if [ "$trans_text" -a "$rt_key" ]
then
  write_key "$rt_key" "$trans_text"
fi

# sort the output
LANG=C sort -Vu $tmp_rt_file >>$new_rt_file

# Cleanup
rm $tmp_rt_file
