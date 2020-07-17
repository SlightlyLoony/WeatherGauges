# These entries primarily let apt-get commands play nice...
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LANGUAGE=en_US.UTF-8

# Colorize ls by default...
alias ls='ls --color=auto'

# if the X server has not already been started, start it...
# this should execute when the pi user automatically logs in...
if [[ $( ps ux | grep -c [X]org ) -eq 0 ]]
then
  export DISPLAY=:0
  startx -- -nocursor
fi
