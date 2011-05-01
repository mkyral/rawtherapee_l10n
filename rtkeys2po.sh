#!/bin/bash

if [ $# -ne 2 ]
then
  echo "Usage: $0 <rt_language_file> <po_file>"
  echo "  E.g: $0 Czech cs"
  exit 1
fi

trans_file="$1"
po_file="$2"

if [ ! -f "$trans_file" ]
then
  echo "Error: File $trans_file does not exists."
  exit 2
fi

orig_file=default
orig_sorted=$(basename $orig_file).sorted
orig_uniq=$(basename $orig_file).uniq
trans_sorted=$(basename $trans_file).sorted
po_file=${po_file%.po}.po

# remove comments, sort keys
cat $orig_file |egrep -v '#|!!|! ' |grep -v '^$'| sed 's/^\([^;]*\);\(.*\)/\2@\1/' |sort -t "@" -k 1,1  >$orig_sorted
cat $trans_file |egrep -v '#|!' |grep -v '^$' |sort >$trans_sorted

## --------------------------------------------------------
## Merge Duplicated keys
old_text=
keys_list=

[ -f $orig_uniq ] && rm -f $orig_uniq

IFS='@'
while read -r KEY_TEXT KEY_ID
do
  if [ -z "$old_text" ]
  then
    keys_list="$KEY_ID"
    old_text="$KEY_TEXT"
    continue
  fi

  if [ "$old_text" = "$KEY_TEXT" ]
  then
    echo "Duplicated key found: $KEY_ID"
    keys_list+=",$KEY_ID"
    continue
  else
    # Messages are different - write result
    echo "$keys_list;$old_text" >> $orig_uniq

    keys_list="$KEY_ID"
    old_text="$KEY_TEXT"

  fi
done < $orig_sorted

if [ "$old_text" ]
then
  # write last line
  echo "$keys_list;$old_text" >> $orig_uniq
fi

# Sort by keys
cat $orig_uniq |sort > $orig_sorted

## --------------------------------------------------------
## Generate PO file

get_translated_key ()
{
  T_KEY="$1"
  grep "^${T_KEY};" $trans_sorted |sed "s/^\(${T_KEY}\);\(.*\)/\2/" |sed 's/"/\\"/g'
}

# Add a header - TODO: customize it
cat > $po_file << EOT
# Marian Kyral <mkyral@email.cz>, 2008, 2010, 2011.
msgid ""
msgstr ""
"Project-Id-Version: \n"
"Report-Msgid-Bugs-To: http://code.google.com/p/rawtherapee/issues/list\n"
"POT-Creation-Date: $(date '+%Y-%m-%d %H:%M%z')\n"
"PO-Revision-Date: 2010-10-16 15:11+0200\n"
"Last-Translator: Marian Kyral <mkyral@email.cz>\n"
"Language-Team: Czech <kde-i18n-doc@kde.org>\n"
"Language: cs\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: utf8\n"
"X-Generator: Lokalize 1.1\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

EOT

# generate .po file
IFS=';'
cat $orig_sorted |sed 's/"/\\"/g' |while read -r KEY_ID KEY_TEXT
do
  FIRST_KEY=$(echo $KEY_ID |cut -d ',' -f 1)
  KEY_TRANSLATED=$(get_translated_key $FIRST_KEY)

  echo "#: $KEY_ID" >> $po_file
  echo "msgid \"$KEY_TEXT\"" >> $po_file
  if [ -z "$KEY_TRANSLATED" ]
  then
    echo "msgstr \"\"" >> $po_file
  else
    echo "msgstr \"$KEY_TRANSLATED\"" >> $po_file
  fi
  echo >> $po_file
done

# Cleanup
rm -f $orig_sorted $trans_sorted $orig_uniq
