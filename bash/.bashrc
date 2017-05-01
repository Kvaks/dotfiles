export PATH=~/bin:~/bin/scripts:"${PATH}"
export CLOJURE_EXT=~/.clojure
export PATH=$PATH:~/opt/clojure-contrib/launchers/bash

source ~/.alias

#settings
ulimit -S -c 0          # Don't want any coredumps.
#set -o notify
#set -o noclobber #prevent > etc overwriting existing files
#set -o ignoreeof
#set -o nounset

# Enable options:
#shopt -s cdspell
#shopt -s cdable_vars
#shopt -s checkhash
#shopt -s checkwinsize
#shopt -s histappend
#shopt -s histverify
#shopt -s no_empty_cmd_completion
#shopt -s cmdhist #lagre multi-line commands as one
#shopt -s nocaseglob

#disable
shopt -u mailwarn
unset MAILCHECK 


#-------------------------------------------------------------
# Automatic setting of $DISPLAY (if not set already).
# This works for linux - your mileage may vary. ... 
# The problem is that different types of terminals give
# different answers to 'who am i' (rxvt in particular can be
# troublesome).
# I have not found a 'universal' method yet.
#-------------------------------------------------------------

function get_xserver ()
{
    case $TERM in
       xterm )
            XSERVER=$(who am i | awk '{print $NF}' | tr -d ')''(' ) 
            # Ane-Pieter Wieringa suggests the following alternative:
            # I_AM=$(who am i)
            # SERVER=${I_AM#*(}
            # SERVER=${SERVER%*)}

            XSERVER=${XSERVER%%:*}
            ;;
        aterm | rxvt)
        # Find some code that works here. ...
            ;;
    esac  
}

if [ -z ${DISPLAY:=""} ]; then
    get_xserver
    if [[ -z ${XSERVER}  || ${XSERVER} == $(hostname) || \
      ${XSERVER} == "unix" ]]; then 
        DISPLAY=":0.0"          # Display on local host.
    else
        DISPLAY=${XSERVER}:0.0  # Display on remote host.
    fi
fi

export DISPLAY


# Greeting, motd etc...
#-------------------------------------------------------------

# Define some colors first:
#red='\e[0;31m'
#RED='\e[1;31m'
#blue='\e[0;34m'
#BLUE='\e[1;34m'
#cyan='\e[0;36m'
#CYAN='\e[1;36m'
NC='\e[0m'              # No Color
# --> Nice. Has the same effect as using "ansi.sys" in DOS.

black="\[\033[0;38;5;0m\]"
red="\[\033[0;38;5;1m\]"
orange="\[\033[0;38;5;130m\]"
green="\[\033[0;38;5;2m\]"
yellow="\[\033[0;38;5;3m\]"
blue="\[\033[0;38;5;4m\]"
bblue="\[\033[0;38;5;12m\]"
magenta="\[\033[0;38;5;55m\]"
cyan="\[\033[0;38;5;6m\]"
white="\[\033[0;38;5;7m\]"
coldblue="\[\033[0;38;5;33m\]"
smoothblue="\[\033[0;38;5;111m\]"
iceblue="\[\033[0;38;5;45m\]"
turqoise="\[\033[0;38;5;50m\]"
smoothgreen="\[\033[0;38;5;42m\]"

framecolor=$iceblue
textcolor=$coldblue
hostcolor=$smoothgreen
xhostcolor=$red
#dircolor=$textcolor


function _exit()        # Function to run upon exit of shell.
{
    echo -e "${RED}Hasta la vista, baby${NC}"
}
#trap _exit EXIT

#-------------------------------------------------------------
# Shell Prompt
#-------------------------------------------------------------



########### Remote and local variations #########

mylocal ()
{
# local
#export PS1=$'\\[\\033m\\033[32m\\]\\u \\[\\033[33m\\w\\033[0m\\]\n$ '
#export PS2='> '
alias emacs=$emacs
}

# remote
myremote ()
{

SSHAGENT=/usr/bin/ssh-agent
SSHAGENTARGS="-s"
if [ -z "$SSH_AUTH_SOCK" -a -x "$SSHAGENT" ]; then
  eval `$SSHAGENT $SSHAGENTARGS`
  trap "kill $SSH_AGENT_PID" 0
fi

export hostcolor=$xhostcolor

#export PS1=$'\\[\\033m\\033[32m\\]\\u@\[\033[31m\]\\h \\[\\033[33m\\w\\033[0m\\]\n$ '
#export PS1=$'\\[\\033m\\033[32m\\]\\u@$hostcolor\\h \\[\\033[33m\\w\\033[0m\\]\n$ '
#export PS2='> '

export EDITOR="$emacs -nw"
alias emacs="$emacs -nw"

}

##### determine if local or remote

tmp=`echo $DISPLAY | awk -F : '{print $1}'`

if [ $TERM == linux ]; then
mylocal
elif [ -z $tmp ] ;then #-o  $tmp == localhost]; then
mylocal
else
myremote
fi

### HISTORY
HISTSIZE=9000
HISTFILESIZE=$HISTSIZE
HISTCONTROL=ignorespace:ignoredups

history() {
  _bash_history_sync
  builtin history "$@"
}

bash_history_sync() {
  builtin history -a         #1
  HISTFILESIZE=$HISTSIZE     #2
  builtin history -c         #3
  builtin history -r         #4
}


### END HISTORY




function pre_prompt {

bash_history_sync

newPWD="${PWD}"
user="whoami"
#dircolor=$textcolor
host=$(echo -n $HOSTNAME | sed -e "s/[\.].*//")
datenow=$(date "+%a, %d %b")
let promptsize=$(echo -n "┌($user@$host ddd., DD mmm YY)(${PWD})┐" \
                 | wc -c | tr -d " ")
let fillsize=${COLUMNS}-${promptsize}
fill=""
while [ "$fillsize" -gt "0" ] 
do 
    fill="${fill}─"
	let fillsize=${fillsize}-1
done
if [ "$fillsize" -lt "0" ]
then
    let cutt=3-${fillsize}
    newPWD="...$(echo -n $PWD | sed -e "s/\(^.\{$cutt\}\)\(.*\)/\2/")"
fi

if (echo $PWD |grep -q $HOME);then
    dircolor=$textcolor
#    echo home
else
    dircolor=$red
#    echo away
fi

}

PROMPT_COMMAND=pre_prompt


case "$TERM" in
xterm)
    PS1="$framecolor┌─($textcolor\u@$hostcolor\h $textcolor\$(date \"+%a, %d %b %y\")$framecolor)─\${fill}─($dircolor\$newPWD\
$framecolor)─┐\n$framecolor└─($textcolor\$(date \"+%H:%M\") \$$framecolor)─>$white "
    ;;
screen)
    PS1="$framecolor┌─($red$textcolor\u@\h \$(date \"+%a, %d %b %y\")$framecolor)─\${fill}─($textcolor\$newPWD\
$framecolor)─┐\n$framecolor└─($textcolor\$(date \"+%H:%M\") \$$framecolor)─>$white "
    ;;    
    *)
    PS1="┌─(\u@\h \$(date \"+%a, %d %b %y\"))─\${fill}─(\$newPWD\
)─┐\n└─(\$(date \"+%H:%M\") \$)─> "
    ;;
esac


#POWERLINEROOT='/usr/local/lib/python3.4/dist-packages/'
#POWERLINEROOT="$HOME/.local/lib/python3.5/site-packages/"
#POWERLINEROOT=/usr/lib/python2.7/dist-packages
#powerline-daemon -q
#POWERLINE_BASH_CONTINUATION=1
#POWERLINE_BASH_SELECT=1
#$POWERLINEROOT/powerline/bindings/bash/powerline.sh
