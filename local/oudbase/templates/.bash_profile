# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/.local/bin:$HOME/bin

export PATH

# Check OUD_BASE and load if necessary
if [ "${OUD_BASE}" = "" ]; then
  if [ -f "${HOME}/.OUD_BASE" ]; then
    . "${HOME}/.OUD_BASE"
  else
    echo "ERROR: Could not load ${HOME}/.OUD_BASE"
  fi
fi

# define an oudenv alias
alias oud=". ${OUD_BASE}/local/bin/oudenv.sh"

# source oud environment
. ${OUD_BASE}/local/bin/oudenv.sh
