#!/bin/bash

SRC=${1:-~/neomutt}

[ -d "$SRC" ] || exit 1

for i in "$SRC/doc/"*.man "$SRC/doc/"*.[15]; do
	MAN="${i##*/}"
	MAN="${MAN%.*}.man"
	cp "$i" "$MAN"
done

for i in *.man; do
	doclifter "$i"
done

cp "$SRC/doc/chunk.xsl" .
cp "$SRC/doc/neomutt.xsl" .
cp "$SRC/doc/neomutt.css" .

for i in *.man.xml; do
	xsltproc --param root.filename "$i.html" --nonet chunk.xsl "$i"
	mv "${i%.man.xml}man.html" "${i%.man.xml}.html"
done

for i in *.html; do
	tidy -q -xml "$i"
done

for i in *.html; do
	sed -i '1,3d' "$i"
	sed -i 's/.*<html [^>]\+>/<html>/' "$i"
	xmlstarlet sel -t -c "//div[@class='refentry']" "$i" \
		| tidy -q -xml \
		| sed 's/<a id=\([^ ]\+\) \/>/<a id=\1><\/a>/g' \
		| sponge "$i"
done

echo "Wrapping:" 
for FILE in *.html; do
	TEXT=$(sed -n '/<h2>Name<\/h2>/{n;s/.*<p>//;s/<\/p>.*//;p}' "$FILE")
	COMMAND=${TEXT%% *}
	DESC=${TEXT#* }
	DESC=${DESC#* }

	echo -e "\\t$FILE"
	(
		echo "---"
		echo "layout: concertina"
		echo "command: $COMMAND"
		echo "description: $DESC"
		echo "---"
		echo "{% raw %}"
		cat "$FILE"
		echo "{% endraw %}"
	) | sponge "$FILE"
done

rm -f ./*.man
rm -f ./*.xml
rm -f ./*.xsl
rm -f ./*.css

