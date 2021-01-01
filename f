#!/usr/bin/env bash

CMD_LIST="ls -a -1"
SELECTED_PATH=~/.f-selected

_clean() {
  if [ -f  $SELECTED_PATH ]; then
    rm $SELECTED_PATH
  fi
}

_clear() {
  printf "\033c"
}

trap _clean EXIT

_input() {
  read -e -p "$(pwd) (Type ? for help): " -i "$input" input
  case "$input" in
    ..)
      cd ..
      _output
      ;;
    "~")
      cd "$HOME"
      _output
      ;;
    /)
      cd /
      _output
      ;;
    \!)
      bash
      _output
      ;;
    \?)
      _clear
      echo ""
      echo "type something to find and change directory"
      echo "/ - change current directory to root"
      echo "~ - change current directory to home"
      echo "! - shell"
      echo "? - show shortcut"
      echo "/a - show all selected"
      echo "/c - change directory"
      echo "/d - delete selected"
      echo "/e - execute command, can use with %s and /index"
      echo "/h - toggle hide/unhide dotfiles"
      echo "/s - select items by index"
      echo ""
      input=""
      _input
      ;;
    /a)
      _clear
      echo ""
      if [ -f $SELECTED_PATH ]; then
        awk '{print NR,$0}' $SELECTED_PATH
      else
        echo "No items selected"
      fi
      echo ""
      input=""
      _input
      ;;
    /b)
      _clear
      echo ""
      _bm_list
      echo ""
      input=""
      _input
      ;;
    /c\ *)
      path=${input:3}
      cd "$path"
      _output
      ;;
    /g\ *)
      _bm_change_directory ${input:3}
      _output
      ;;
    .|/h)
      if [[ $CMD_LIST =~ \ \-a ]]; then
        CMD_LIST="ls -1"
      else
        CMD_LIST="ls -a -1"
      fi
      _output
      ;;
    /e\ *)
      raw_cmd=${input:3}
      if [[ $raw_cmd =~ \ %s ]]; then
        params=$(cat $SELECTED_PATH | tr '\n' ' ')
        cmd=$(echo $raw_cmd | sed "s;%s;$params;")
      elif [[ $raw_cmd =~ \ /[0-9] ]]; then
        cmd=$(echo $raw_cmd | sed 's/\/\([0-9]\+\)/${items[\1]}/g')
      else
        cmd=$raw_cmd
      fi
      eval $cmd
      rm $SELECTED_PATH
      _output
      ;;
    /q)
      _clear
      exit 0
      ;;
    /d\ *)
      _clear
      selected=$(echo ${input:3} | sed 's/\ /d;/g')
      sed -i "$selected"d $SELECTED_PATH
      awk '{print NR,$0}' $SELECTED_PATH
      input=""
      _input
      ;;
    /s\ *)
      raw_input=${input:3}
      IFS=' ' read -p "Select:" -r -a selected <<< "$raw_input"
      for i in ${selected[@]}; do
        echo "\"$(pwd)/${items[$i]}\"" >> $SELECTED_PATH
      done
      sort -u $SELECTED_PATH -o $SELECTED_PATH
      _output
      ;;
    *)
      digit_pattern='^[0-9]+$'
      if [[ "$input" =~ $digit_pattern ]]; then
        cd ${items[$input]}
        _output
      else
        _output $input
      fi
      ;;
  esac
}

_search() {
  if [ -z $1 ]; then
    items=($($CMD_LIST))
  else
    items=($($CMD_LIST | grep -i $1))
  fi
  if [[ ${#items[@]} -eq 1 && -d ${items[0]} ]]; then
    input=""
    cd ${items[0]}
    _output
  fi
}

_output() {
  _search $1
  index=0
  output=""
  input=""
  for item in ${items[@]}; do
    if [ -d $item ]; then
      output+="$index - $item/\n"
    elif [ -f $item ]; then
      output+="$index - $item\n"
    fi
    let "index++"
  done
  _clear
  echo ""
  echo -e $output | column
  echo ""
  _input
}

# bookmark manager
shopt -s expand_aliases
source ~/.bash_extensions/bookmark.sh

cd $1
_output

