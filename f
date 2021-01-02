#!/usr/bin/env bash

CMD_LIST="ls -a -F -1"
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
  read -e -p "> " -i "$input" input
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
    ,\ *)
      path=${input:2}
      _commacd_forward $path
      _output
      ;;
    \?)
      _clear
      echo "Help: "
      echo ""
      echo "Type something to find and change directory"
      echo "Type an index of folder to open it"
      echo ""
      echo "Shortcuts:"
      echo ""
      echo "/  - Change current directory to root"
      echo "~  - Change current directory to home"
      echo "!  - Shell"
      echo "?  - Show help"
      echo "/a - Show all selected"
      echo "/c - Change directory"
      echo "/d - Delete selected"
      echo "/e - Execute command, can use with %s and /index"
      echo "/h - Toggle hide/unhide dotfiles"
      echo "/i - Execute command in silent"
      echo "/s - Select items by index"
      echo ""
      echo "Extends scripts:"
      echo ""
      echo ",  - Change directory with commacd"
      echo "/b - List bookmark with bash-bookmark"
      echo "/g - Go a bookmark with bash-bookmark"
      echo ""
      input=""
      _input
      ;;
    /a)
      _clear
      echo "Selected items: "
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
      echo "Bookmarks: "
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
    /d\ *)
      _clear
      selected=$(echo ${input:3} | sed 's/\ /d;/g')
      sed -i "$selected"d $SELECTED_PATH
      awk '{print NR,$0}' $SELECTED_PATH
      input=""
      _input
      ;;
    /e\ *)
      raw_cmd=${input:3}
      _command
      echo ""
      eval "$cmd"
      echo ""
      read -n 1 -s -r -p "Press any key to continue..."
      _output
      ;;
    /g\ *)
      _bm_change_directory ${input:3}
      _output
      ;;
    .|/h)
      if [[ $CMD_LIST =~ \ \-a ]]; then
        CMD_LIST="ls -F -1"
      else
        CMD_LIST="ls -F -a -1"
      fi
      _output
      ;;
    /i\ *)
      raw_cmd=${input:3}
      _command
      eval "$cmd"
      _output
      ;;
    /q)
      _clear
      exit 0
      ;;
    /s\ *)
      raw_input=${input:3}
      IFS=' ' read -p "Select:" -r -a selected <<< "$raw_input"
      for i in ${selected[@]}; do
        match=$(_index_of $i)
        echo "\"$match\"" >> $SELECTED_PATH
      done
      sort -u $SELECTED_PATH -o $SELECTED_PATH
      _output
      ;;
    *)
      digit_pattern='^[0-9]+$'
      if [[ "$input" =~ $digit_pattern ]]; then
        cd "$(_index_of $input)"
        _output
      else
        _output $input
      fi
      ;;
  esac
}

_index_of() {
  cmd=$(echo $CMD_LIST | sed 's/\ -F//')
  echo $(pwd)/$(eval "$cmd | sed -n '$1p'")
}

_output() {
  input=""
  _clear
  pwd
  echo ""
  cmd="$CMD_LIST | awk 'tolower(\$0) ~ /$1/{ print NR,\$0}'"
  match_count=$(eval $cmd | wc -l)
  if [ $match_count -eq 1 ]; then
    match_index=$(eval $cmd | cut -d ' ' -f 1)
    match=$(_index_of $match_index)
    if [ -d "$match" ]; then
      cd "$match"
      _output
    fi
  elif [ $match_count -eq 0 ]; then
    echo "Type ? for help"
  fi
  eval $cmd | column
  echo ""
  _input
}

_command() {
  if [[ $raw_cmd =~ \ %s ]]; then
    params=$(cat $SELECTED_PATH | tr '\n' ' ')
    cmd=$(echo $raw_cmd | sed "s;%s;$params;")
    rm $SELECTED_PATH
  elif [[ $raw_cmd =~ \ /[0-9] ]]; then
    cmd=$(echo $raw_cmd | sed 's/\/\([0-9]\+\)/$(_index_of\ \1)/g')
  else
    cmd=$raw_cmd
  fi
}

# extend with other scripts
shopt -s expand_aliases
source ~/.bash_extensions/bookmark.sh
source ~/.bash_extensions/commacd.sh

cd $1
_output

