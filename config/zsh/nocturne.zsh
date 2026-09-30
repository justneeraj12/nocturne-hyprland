# Nocturne additions for the user's existing Oh My Zsh + Powerlevel10k setup.
# Loaded after ~/.p10k.zsh so aliases, completions, and project tooling stay intact.

# A compact two-line prompt: context above, uncluttered input below.
typeset -g POWERLEVEL9K_MODE=nerdfont-v3
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs newline prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs virtualenv node_version time newline)
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%117F╭─'
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%117F├─'
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%117F╰─'
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='·'
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=238

# Rounded powerline caps with the same blue/cyan/purple palette as the desktop.
typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''

typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=235
typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=117
typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION=''
typeset -g POWERLEVEL9K_DIR_BACKGROUND=24
typeset -g POWERLEVEL9K_DIR_FOREGROUND=255
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=117
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=159
typeset -g POWERLEVEL9K_VCS_BACKGROUND=235
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=120
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=117
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=221
typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=120
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=210
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=183
typeset -g POWERLEVEL9K_TIME_FOREGROUND=117
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=117
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=210
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION='❯'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION='❯'

# Modern tools, exposed through new aliases rather than replacing core commands.
if (( $+commands[eza] )); then
  alias l='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto --git'
  alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
fi
if (( $+commands[batcat] )); then
  alias preview='batcat --style=numbers,changes --color=always'
elif (( $+commands[bat] )); then
  alias preview='bat --style=numbers,changes --color=always'
fi
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
  --color=bg+:#1f2335,bg:#0f111a,spinner:#bb9af7,hl:#7aa2f7 \
  --color=fg:#a9b1d6,header:#7dcfff,info:#73daca,pointer:#bb9af7 \
  --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#7dcfff \
  --border=rounded --prompt='  ' --pointer='◆' --marker='✓'"

