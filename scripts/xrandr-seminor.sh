#!/bin/bash

intern="eDP1"
extern="DP1"
direction="left"

usage() {
  echo "$0"
  echo "$0 -i <input> -e <output> -d <direction>"
  echo "  input     :  Connection pin of the main display(default: $intern)."
  echo "  output    :  Connection pin of the external display(default: $extern)."
  echo "  direction :  External display position(default: $direction)."
  echo ""
  echo "Select Xrandr Menu."
  echo "  Quit      :  Quit the script."
  echo "  Extend    :  Extend the external display."
  echo "  Mirroring :  Duplicate the main display."
  echo "  Disconnect:  Disconnect the external display."

  exit 0
}

while getopts i:o:d:h OPT
do
  case $OPT in
    i)  intern=$OPTARG
      ;;
    o)  extern=$OPTARG
      ;;
    d)  direction=$OPTARG
      ;;
    h)  usage
      ;;
    \?) usage
      ;;
  esac
done

PS3="Select Xrandr Menu > "
ITEM_LIST="Quit Extend Mirroring Disconnect"

select selection in $ITEM_LIST
do
  if [ $selection ]; then
    if [ ${REPLY} -eq 1 ]; then
      break
    elif [ ${REPLY} -eq 2 ]; then
      `xrandr --output ${intern} --auto --output ${extern} --auto --${direction}-of ${intern}`
    elif [ ${REPLY} -eq 3 ]; then
      `xrandr --output ${extern} --auto --same-as ${intern}`
    elif [ ${REPLY} -eq 4 ]; then
      `xrandr --output ${intern} --auto --output ${extern} --off`
    fi
  else
    echo "invalid selection."
  fi
done

