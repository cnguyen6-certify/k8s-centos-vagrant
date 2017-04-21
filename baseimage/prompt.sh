export PROMPT_COMMAND=__prompt_command

function __prompt_command() {
  local EXIT="$?"

  local RCol='\[\e[0m\]'

  local Red='\[\e[0;31m\]'
  local Gre='\[\e[0;32m\]'
  local BYel='\[\e[1;33m\]'
  local Blu='\[\e[0;34m\]'
  local BBlu='\[\e[1;34m\]'
  local Pur='\[\e[0;35m\]'

  PS1="${Blu}# ${Gre}\u ${RCol}@ ${BYel}\H ${RCol}in ${BYel}\w ${RCol}[\t]"
  if [ $EXIT != 0 ]; then
    PS1+=" ${Red}FAIL${RCol}\n"
  fi
  PS1+="\n${Red}\\$\[$(tput sgr0)\] "
}
