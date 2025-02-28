#!/bin/bash
if [ -z "$1" ]; then
    echo "Использование: $0 <имя_файла>"
    exit 1
fi

FILENAME="$1"

if [ -f "$FILENAME" ]; then
    wrench-fmt $FILENAME --isa acc32 >tmp.s
    mv tmp.s $FILENAME
else
    echo "Файл '$FILENAME' не найден."
fi
