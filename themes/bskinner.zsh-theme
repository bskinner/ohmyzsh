#
# The desired format of this prompt is:
#
# Standard:
#   [some/path]
#   user@machine➜
#
# Git (clean):
#   [some/path]
#   git:RepositoryName < branch:000000000 > ✔
#   user@machine➜
#
# Git (dirty w/ added, deleted, modified, renamed, and untracked changes):
#   [some/path]
#   git:RepositoryName < branch:000000000 > ✘ [ADMR!]
#   user@machine➜
#

# The maximum path depth that should be printed in the prompt
#   with depth being defined as the current directory, and
#   n-1 parents.
local max_path_depth=3

# Local color definitions to make life a bit easier when performing styling
local reset="%{$reset_color%}"
local bold_white="%{$fg_bold[white]%}"
local bold_yellow="%{$fg_bold[yellow]%}"
local bold_red="%{$fg_bold[red]%}"
local bold_green="%{$fg_bold[green]%}"
local bold_blue="%{$fg_bold[blue]%}"
local bold_cyan="%{$fg_bold[cyan]%}"
local cyan="%{$fg[cyan]%}"
local blue="%{$fg[blue]%}"
local yellow="%{$fg[yellow]%}"
local red="%{$fg[red]%}"

#
VCS_DIRTY_COLOR="${bold_red}"
VCS_CLEAN_COLOR="${bold_green}"

ZSH_THEME_GIT_PROMPT_PREFIX=": "
ZSH_THEME_GIT_PROMPT_SUFFIX="${reset}"
ZSH_THEME_GIT_PROMPT_DIRTY="${VCS_DIRTY_COLOR}✘${reset}"
ZSH_THEME_GIT_PROMPT_CLEAN="${VCS_CLEAN_COLOR}✔${reset}"

local git_prompt_added="A"
local git_prompt_modified="M"
local git_prompt_deleted="D"
local git_prompt_renamed="R"
local git_prompt_untracked="!"

# Styles!
local working_dir_writable_style="${bold_green}"
local working_dir_readonly_style="${bold_red}"

function bs_git_current_repo {
    local repo
    repo=$(basename `git rev-parse --show-toplevel`)
    echo ${repo}
}

function bs_git_inside_repo {
    local inside_work_tree="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
    echo ${inside_work_tree}
}

function bs_git_change_flags {
    if [[ "$(bs_git_inside_repo)" == "true" ]]; then
        local prompt_status=""
        local git_added=0
        local git_modified=0
        local git_deleted=0
        local git_renamed=0
        local git_untracked=0

        git status --porcelain | while read gstatus gfile; do
            case $gstatus in
                'A') git_added=1 ;;
                'D') git_deleted=1 ;;
                'M') git_modified=1 ;;
                'R') git_renamed=1 ;;
                '??') git_untracked=1 ;;
                *) ;;
            esac
        done

        if [[ $git_added -eq 1 ]]; then
            prompt_status+="${git_prompt_added}"
        fi

        if [[ $git_deleted -eq 1 ]]; then
            prompt_status+="${git_prompt_deleted}"
        fi

        if [[ $git_modified -eq 1 ]]; then
            prompt_status+="${git_prompt_modified}"
        fi

        if [[ $git_renamed -eq 1 ]]; then
            prompt_status+="${git_prompt_renamed}"
        fi

        if [[ $git_untracked -eq 1 ]]; then
            prompt_status+="${git_prompt_untracked}"
        fi
    fi

    echo "${prompt_status}"
}

function bskinner_precmd {
    local nl=$'\n'

    # Check to see if the working directory is currently writable
    #   (or not) and tweak the coloring of the path fragment to
    #   give a hint about the state.
    if [[ -w "${PWD}" ]]; then
        prompt_path="${working_dir_writable_style}%${max_path_depth}~${reset}"
    else
        prompt_path="${working_dir_readonly_style}%${max_path_depth}~${reset}"
    fi

    prompt_path="[${prompt_path}]"

    local user="%(!.${bold_red}.${bold_green})%n${reset}"
    local machine="%M"
    local marker="%(?:${bold_green}:${bold_red})➜ ${reset}"
    local main_prompt="${user}@${machine}${marker} "

    local vcs_status
    if [[ "$(bs_git_inside_repo)" == "true" ]]; then
        # We are inside a git working tree!
        vcs_status="${blue}git:${reset}${bold_blue}$(bs_git_current_repo)${reset} "
        vcs_status+="< ${bold_cyan}$(git_current_branch)${reset}:${yellow}$(git_prompt_short_sha)${reset} > "
        vcs_status+="$(parse_git_dirty)"

        if _tmp_status=$(git status --porcelain) && [[ -n ${_tmp_status} ]]; then
            vcs_status+=" [${bold_yellow}$(bs_git_change_flags)${reset}]"
        fi

        vcs_status+="${nl}"
    fi

    export PROMPT="${nl}${vcs_status}${prompt_path}${nl}${main_prompt}"
}


autoload -U add-zsh-hook
add-zsh-hook precmd bskinner_precmd