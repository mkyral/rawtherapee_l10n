#!/bin/bash

BASE_DIR=$(dirname "$0")
echo $BASE_DIR

orig_file=default
sorted_file=${orig_file}.sorted
uniq_keys_file=${orig_file}.uniq
no_merge_file="${BASE_DIR}/.no_merge_keys"
pot_file=rawtherapee.pot

# Remove comments, exchange columns - allows to process correctly duplicated strings
cat default |egrep -v '^#|^!!|^! ' |grep -v '^$'|sed 's/^!//' |sed 's/^\([^;]*\);\(.*\)/\2@\1/' |sort -t "@" -k 1,1 >$sorted_file

old_text=
keys_list=
old_no_merge_flag=0

IFS='@'
while read -r KEY_TEXT KEY_ID
do
  if [ -z "$old_text" ]
  then
    keys_list="$KEY_ID"
    old_text="$KEY_TEXT"
    continue
  fi

  no_merge_flag=$(grep -c "$KEY_ID" $no_merge_file)
  if [ "$old_text" = "$KEY_TEXT" -a "$no_merge_flag" = "0" ]
  then
    echo "Duplicated key found: $KEY_ID"
    keys_list+=",$KEY_ID"
    old_no_merge_flag=$no_merge_flag
    continue
  else
    # Messages are different - write result
    echo "$keys_list;$old_no_merge_flag;$old_text" >> $uniq_keys_file

    export keys_list="$KEY_ID"
    export old_text="$KEY_TEXT"
    export old_no_merge_flag=$no_merge_flag

  fi
done < $sorted_file

# echo "KEYS_LIST: $keys_list"
if [ "$old_text" ]
then
  # write last line
  echo "$keys_list;$old_no_merge_flag;$old_text" >> $uniq_keys_file
fi

# Sort by keys
cat $uniq_keys_file |sort > $sorted_file

## Generate POT file
cat > $pot_file << EOT
# RawTherapee.
# Copyright (C) 2004-2011, Gábor Horváth
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\n"
"Report-Msgid-Bugs-To: http://code.google.com/p/rawtherapee/issues/list\n"
"POT-Creation-Date: $(date '+%Y-%m-%d %H:%M%z')\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: LANGUAGE <LL@li.org>\n"
"Language: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

EOT

IFS=';'
cat $sorted_file |sed 's/"/\\"/g' |while read -r KEY_ID NO_MERGE_FLAG KEY_TEXT
do
  echo "#: $KEY_ID" >> $pot_file
  if [ "$NO_MERGE_FLAG" != "0" ]; then echo "msgctxt \"$KEY_ID\"" >> $pot_file; fi
  echo "msgid \"$KEY_TEXT\"" >> $pot_file
  echo "msgstr \"\"" >> $pot_file
  echo >> $pot_file
done

rm -f $sorted_file $uniq_keys_file
