#!/bin/sh

if [ $# -lt 3 ]; then
  echo "usage: $0 <RGB>"
  echo "     : $0 -r <HEX>"
  exit 1
fi

getopts "r" opts
if [ $opts = "r" ]; then
  printf "%d %d %d\n" "0x$2" "0x$3" "0x$4"
  exit 1
else
  printf "#%x%x%x\n" $1 $2 $3
  exit 1
fi

