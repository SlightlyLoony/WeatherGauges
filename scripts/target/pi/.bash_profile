# These entries primarily let apt-get commands play nice...
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LANGUAGE=en_US.UTF-8

# Colorize ls by default...
alias ls='ls --color=auto'

# Make sure we have a display defined...
export DISPLAY=:0

# If we're not running through SSH, then this is a local session - created only by automatic login, and therefore
# created exactly once - this is where we start our X server...

# If SSH_CLIENT or SSH_TTY is defined, then we're running under SSH.
if [[ ! -v SSH_CLIENT && ! -v SSH_TTY ]]
then
    # If the X server has not already been started, start it...
    while [[ $( ps ux | grep -c "[X]org" ) -eq 0 ]]
    do
      startx -- -nocursor &>xserver.out

      # NOTE: we should never get here, as startx never exits in normal use...
      # BUT if we do somehow get here, we'll start the X server again...
    done
fi
