# NOC presentation layer for the user's existing Zsh configuration.
# It is loaded last, preserving aliases, plugins, completions and project tooling.

[[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/nocturne/terminal-palette.zsh ]] \
  && source ${XDG_CONFIG_HOME:-$HOME/.config}/nocturne/terminal-palette.zsh
: ${NOC_BASE:='#07090a'} ${NOC_SURFACE:='#0b0f10'} ${NOC_OVERLAY:='#111719'}
: ${NOC_LINE:='#1b2925'} ${NOC_TEXT:='#a7b8b1'} ${NOC_MUTED:='#4d5d58'}
: ${NOC_ACCENT:='#5f8f76'} ${NOC_ACCENT2:='#477463'}

# A compact two-line prompt: context above, uncluttered input below.
typeset -g POWERLEVEL9K_MODE=nerdfont-v3
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs newline prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs virtualenv node_version time newline)
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%F{'$NOC_ACCENT'}┌─%f'
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%F{'$NOC_ACCENT'}├─%f'
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%F{'$NOC_ACCENT'}└─%f'
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='─'
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND="$NOC_LINE"

# Compact, sharp joins match the NOC shell instead of importing another rice.
typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''

typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND="$NOC_ACCENT2"
typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND="$NOC_TEXT"
typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='NOC'
typeset -g POWERLEVEL9K_DIR_BACKGROUND="$NOC_SURFACE"
typeset -g POWERLEVEL9K_DIR_FOREGROUND="$NOC_TEXT"
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND="$NOC_MUTED"
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND="$NOC_ACCENT"
typeset -g POWERLEVEL9K_VCS_BACKGROUND="$NOC_OVERLAY"
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND="$NOC_ACCENT"
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='#7aa899'
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='#d9a85f'
typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND="$NOC_ACCENT"
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND='#e17780'
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND="$NOC_MUTED"
typeset -g POWERLEVEL9K_TIME_FOREGROUND="$NOC_ACCENT"
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%I:%M%P}'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND="$NOC_ACCENT"
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND='#e17780'
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
  --color=bg+:${NOC_OVERLAY},bg:${NOC_BASE},spinner:${NOC_ACCENT},hl:${NOC_ACCENT} \
  --color=fg:${NOC_TEXT},header:${NOC_ACCENT},info:${NOC_MUTED},pointer:${NOC_ACCENT} \
  --color=marker:${NOC_ACCENT},fg+:${NOC_TEXT},prompt:${NOC_ACCENT},hl+:${NOC_ACCENT} \
  --border=sharp --prompt=' NOC> ' --pointer='>' --marker='+'"

typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${NOC_MUTED}"
if (( ${+ZSH_HIGHLIGHT_STYLES} )); then
  ZSH_HIGHLIGHT_STYLES[command]="fg=${NOC_ACCENT}"
  ZSH_HIGHLIGHT_STYLES[builtin]="fg=${NOC_ACCENT}"
  ZSH_HIGHLIGHT_STYLES[path]="fg=${NOC_TEXT},underline"
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#e17780'
fi

# The user's .p10k file is loaded first; this explicit reload applies NOC's
# presentation without replacing their Powerlevel10k installation.
(( ${+functions[p10k]} )) && p10k reload
