#!/bin/bash

rm -fr today
mkdir today
i=1
for FILE in $(ls teams/*.txt | sort -R)
do
    for name in $(cat $FILE | sort -R)
    do
	i=$(((i + 1) % 3))
	echo "$name" >> "today/team_$i.txt"
    done
done
