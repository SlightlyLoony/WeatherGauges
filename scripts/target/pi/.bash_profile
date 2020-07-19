# These entries primarily let apt-get commands play nice...
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LANGUAGE=en_US.UTF-8

# Colorize ls by default...
alias ls='ls --color=auto'

# Make sure we have a display defined...
export DISPLAY=:0

# If we're not running through SSH, then this is a local session - created only by automatic login, and therefore
# created exactly once.  So we therefore run our startup script.
# If SSH_CLIENT or SSH_TTY is defined, then we're running under SSH.
if [[ ! -v SSH_CLIENT && ! -v SSH_TTY ]]
then
  source /home/pi/deploy/pi/startup.bash &>/home/pi/startup.out
fi
