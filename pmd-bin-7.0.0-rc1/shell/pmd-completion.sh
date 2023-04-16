#!/usr/bin/env bash
#
# pmd Bash Completion
# =======================
#
# Bash completion support for the `pmd` command,
# generated by [picocli](https://picocli.info/) version 4.7.0.
#
# Installation
# ------------
#
# 1. Source all completion scripts in your .bash_profile
#
#   cd $YOUR_APP_HOME/bin
#   for f in $(find . -name "*_completion"); do line=". $(pwd)/$f"; grep "$line" ~/.bash_profile || echo "$line" >> ~/.bash_profile; done
#
# 2. Open a new bash console, and type `pmd [TAB][TAB]`
#
# 1a. Alternatively, if you have [bash-completion](https://github.com/scop/bash-completion) installed:
#     Place this file in a `bash-completion.d` folder:
#
#   * /etc/bash-completion.d
#   * /usr/local/etc/bash-completion.d
#   * ~/bash-completion.d
#
# Documentation
# -------------
# The script is called by bash whenever [TAB] or [TAB][TAB] is pressed after
# 'pmd (..)'. By reading entered command line parameters,
# it determines possible bash completions and writes them to the COMPREPLY variable.
# Bash then completes the user input if only one entry is listed in the variable or
# shows the options if more than one is listed in COMPREPLY.
#
# References
# ----------
# [1] http://stackoverflow.com/a/12495480/1440785
# [2] http://tiswww.case.edu/php/chet/bash/FAQ
# [3] https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
# [4] http://zsh.sourceforge.net/Doc/Release/Options.html#index-COMPLETE_005fALIASES
# [5] https://stackoverflow.com/questions/17042057/bash-check-element-in-array-for-elements-in-another-array/17042655#17042655
# [6] https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html#Programmable-Completion
# [7] https://stackoverflow.com/questions/3249432/can-a-bash-tab-completion-script-be-used-in-zsh/27853970#27853970
#

if [ -n "$BASH_VERSION" ]; then
  # Enable programmable completion facilities when using bash (see [3])
  shopt -s progcomp
elif [ -n "$ZSH_VERSION" ]; then
  # Make alias a distinct command for completion purposes when using zsh (see [4])
  setopt COMPLETE_ALIASES
  alias compopt=complete

  # Enable bash completion in zsh (see [7])
  # Only initialize completions module once to avoid unregistering existing completions.
  if ! type compdef > /dev/null; then
    autoload -U +X compinit && compinit
  fi
  autoload -U +X bashcompinit && bashcompinit
fi

# CompWordsContainsArray takes an array and then checks
# if all elements of this array are in the global COMP_WORDS array.
#
# Returns zero (no error) if all elements of the array are in the COMP_WORDS array,
# otherwise returns 1 (error).
function CompWordsContainsArray() {
  declare -a localArray
  localArray=("$@")
  local findme
  for findme in "${localArray[@]}"; do
    if ElementNotInCompWords "$findme"; then return 1; fi
  done
  return 0
}
function ElementNotInCompWords() {
  local findme="$1"
  local element
  for element in "${COMP_WORDS[@]}"; do
    if [[ "$findme" = "$element" ]]; then return 1; fi
  done
  return 0
}

# The `currentPositionalIndex` function calculates the index of the current positional parameter.
#
# currentPositionalIndex takes three parameters:
# the command name,
# a space-separated string with the names of options that take a parameter, and
# a space-separated string with the names of boolean options (that don't take any params).
# When done, this function echos the current positional index to std_out.
#
# Example usage:
# local currIndex=$(currentPositionalIndex "mysubcommand" "$ARG_OPTS" "$FLAG_OPTS")
function currentPositionalIndex() {
  local commandName="$1"
  local optionsWithArgs="$2"
  local booleanOptions="$3"
  local previousWord
  local result=0

  for i in $(seq $((COMP_CWORD - 1)) -1 0); do
    previousWord=${COMP_WORDS[i]}
    if [ "${previousWord}" = "$commandName" ]; then
      break
    fi
    if [[ "${optionsWithArgs}" =~ ${previousWord} ]]; then
      ((result-=2)) # Arg option and its value not counted as positional param
    elif [[ "${booleanOptions}" =~ ${previousWord} ]]; then
      ((result-=1)) # Flag option itself not counted as positional param
    fi
    ((result++))
  done
  echo "$result"
}

# compReplyArray generates a list of completion suggestions based on an array, ensuring all values are properly escaped.
#
# compReplyArray takes a single parameter: the array of options to be displayed
#
# The output is echoed to std_out, one option per line.
#
# Example usage:
# local options=("foo", "bar", "baz")
# local IFS=$'\n'
# COMPREPLY=($(compReplyArray "${options[@]}"))
function compReplyArray() {
  declare -a options
  options=("$@")
  local curr_word=${COMP_WORDS[COMP_CWORD]}
  local i
  local quoted
  local optionList=()

  for (( i=0; i<${#options[@]}; i++ )); do
    # Double escape, since we want escaped values, but compgen -W expands the argument
    printf -v quoted %q "${options[i]}"
    quoted=\'${quoted//\'/\'\\\'\'}\'

    optionList[i]=$quoted
  done

  # We also have to add another round of escaping to $curr_word.
  curr_word=${curr_word//\\/\\\\}
  curr_word=${curr_word//\'/\\\'}

  # Actually generate completions.
  local IFS=$'\n'
  echo -e "$(compgen -W "${optionList[*]}" -- "$curr_word")"
}

# Bash completion entry point function.
# _complete_pmd finds which commands and subcommands have been specified
# on the command line and delegates to the appropriate function
# to generate possible options and subcommands for the last specified subcommand.
function _complete_pmd() {
  # Edge case: if command line has no space after subcommand, then don't assume this subcommand is selected (remkop/picocli#1468).
  if [ "${COMP_LINE}" = "${COMP_WORDS[0]} check" ];    then _picocli_pmd; return $?; fi
  if [ "${COMP_LINE}" = "${COMP_WORDS[0]} cpd" ];    then _picocli_pmd; return $?; fi
  if [ "${COMP_LINE}" = "${COMP_WORDS[0]} designer" ];    then _picocli_pmd; return $?; fi
  if [ "${COMP_LINE}" = "${COMP_WORDS[0]} cpd-gui" ];    then _picocli_pmd; return $?; fi
  if [ "${COMP_LINE}" = "${COMP_WORDS[0]} ast-dump" ];    then _picocli_pmd; return $?; fi

  # Find the longest sequence of subcommands and call the bash function for that subcommand.
  local cmds0=(check)
  local cmds1=(cpd)
  local cmds2=(designer)
  local cmds3=(cpd-gui)
  local cmds4=(ast-dump)

  if CompWordsContainsArray "${cmds4[@]}"; then _picocli_pmd_astdump; return $?; fi
  if CompWordsContainsArray "${cmds3[@]}"; then _picocli_pmd_cpdgui; return $?; fi
  if CompWordsContainsArray "${cmds2[@]}"; then _picocli_pmd_designer; return $?; fi
  if CompWordsContainsArray "${cmds1[@]}"; then _picocli_pmd_cpd; return $?; fi
  if CompWordsContainsArray "${cmds0[@]}"; then _picocli_pmd_check; return $?; fi

  # No subcommands were specified; generate completions for the top-level command.
  _picocli_pmd; return $?;
}

# Generates completions for the options and subcommands of the `pmd` command.
function _picocli_pmd() {
  # Get completion data
  local curr_word=${COMP_WORDS[COMP_CWORD]}

  local commands="check cpd designer cpd-gui ast-dump"
  local flag_opts="-h --help -V --version"
  local arg_opts=""

  if [[ "${curr_word}" == -* ]]; then
    COMPREPLY=( $(compgen -W "${flag_opts} ${arg_opts}" -- "${curr_word}") )
  else
    local positionals=""
    local IFS=$'\n'
    COMPREPLY=( $(compgen -W "${commands// /$'\n'}${IFS}${positionals}" -- "${curr_word}") )
  fi
}

# Generates completions for the options and subcommands of the `check` subcommand.
function _picocli_pmd_check() {
  # Get completion data
  local curr_word=${COMP_WORDS[COMP_CWORD]}
  local prev_word=${COMP_WORDS[COMP_CWORD-1]}

  local commands=""
  local flag_opts="-h --help --debug --verbose -D -v --no-fail-on-violation --benchmark -b --show-suppressed --no-ruleset-compatibility --no-cache --no-progress"
  local arg_opts="--encoding -e --dir -d --file-list --uri -u --format -f --property -P --ignore-list --relativize-paths-with -z --suppress-marker --minimum-priority --report-file -r --use-version --force-language --aux-classpath --cache --threads -t --rulesets -R"
  local format_option_args=("codeclimate" "csv" "emacs" "empty" "html" "ideaj" "json" "sarif" "summaryhtml" "text" "textcolor" "textpad" "vbhtml" "xml" "xslt" "yahtml") # --format values
  local StringString_option_args=("problem" "package" "file" "priority" "line" "desc" "ruleSet" "rule" "linePrefix" "linkPrefix" "htmlExtension" "fileName" "sourcePath" "classAndMethodName" "linePrefix" "linkPrefix" "htmlExtension" "color" "encoding" "encoding" "xsltFilename" "outputDir") # --property values
  local minimumPriority_option_args=("High" "Medium High" "Medium" "Medium Low" "Low") # --minimum-priority values
  local languageVersion_option_args=("apex-52" "apex-53" "apex-54" "apex-55" "apex-56" "apex-57" "ecmascript-3" "ecmascript-5" "ecmascript-6" "ecmascript-7" "ecmascript-8" "ecmascript-9" "ecmascript-ES2015" "ecmascript-ES2016" "ecmascript-ES2017" "ecmascript-ES2018" "ecmascript-ES6" "html-4" "html-5" "java-1.10" "java-1.3" "java-1.4" "java-1.5" "java-1.6" "java-1.7" "java-1.8" "java-1.9" "java-10" "java-11" "java-12" "java-13" "java-14" "java-15" "java-16" "java-17" "java-18" "java-19" "java-19-preview" "java-20" "java-20-preview" "java-5" "java-6" "java-7" "java-8" "java-9" "jsp-2" "jsp-3" "kotlin-1.6" "kotlin-1.7" "kotlin-1.8" "modelica-3.4" "modelica-3.5" "plsql-11g" "plsql-12.1" "plsql-12.2" "plsql-12c_Release_1" "plsql-12c_Release_2" "plsql-18c" "plsql-19c" "plsql-21c" "pom-4.0.0" "scala-2.10" "scala-2.11" "scala-2.12" "scala-2.13" "swift-4.2" "swift-5.0" "swift-5.1" "swift-5.2" "swift-5.3" "swift-5.4" "swift-5.5" "swift-5.6" "swift-5.7" "vf-52" "vf-53" "vf-54" "vf-55" "vf-56" "vf-57" "vm-2.0" "vm-2.1" "vm-2.2" "vm-2.3" "wsdl-1.1" "wsdl-2.0" "xml-1.0" "xml-1.1" "xsl-1.0" "xsl-2.0" "xsl-3.0") # --use-version values
  local forceLanguage_option_args=("apex" "ecmascript" "html" "java" "jsp" "kotlin" "modelica" "plsql" "pom" "scala" "swift" "vf" "vm" "wsdl" "xml" "xsl") # --force-language values

  type compopt &>/dev/null && compopt +o default

  case ${prev_word} in
    --encoding|-e)
      return
      ;;
    --dir|-d)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
    --file-list)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
    --uri|-u)
      return
      ;;
    --format|-f)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${format_option_args[@]}" ) )
      return $?
      ;;
    --property|-P)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${StringString_option_args[@]}" ) )
      return $?
      ;;
    --ignore-list)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
    --relativize-paths-with|-z)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
    --suppress-marker)
      return
      ;;
    --minimum-priority)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${minimumPriority_option_args[@]}" ) )
      return $?
      ;;
    --report-file|-r)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
    --use-version)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${languageVersion_option_args[@]}" ) )
      return $?
      ;;
    --force-language)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${forceLanguage_option_args[@]}" ) )
      return $?
      ;;
    --aux-classpath)
      return
      ;;
    --cache)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
    --threads|-t)
      return
      ;;
    --rulesets|-R)
      return
      ;;
  esac

  if [[ "${curr_word}" == -* ]]; then
    COMPREPLY=( $(compgen -W "${flag_opts} ${arg_opts}" -- "${curr_word}") )
  else
    local positionals=""
    local currIndex
    currIndex=$(currentPositionalIndex "check" "${arg_opts}" "${flag_opts}")
    if (( currIndex >= 0 && currIndex <= 2147483647 )); then
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      positionals=$( compgen -f -- "${curr_word}" ) # files
    fi
    local IFS=$'\n'
    COMPREPLY=( $(compgen -W "${commands// /$'\n'}${IFS}${positionals}" -- "${curr_word}") )
  fi
}

# Generates completions for the options and subcommands of the `cpd` subcommand.
function _picocli_pmd_cpd() {
  # Get completion data
  local curr_word=${COMP_WORDS[COMP_CWORD]}
  local prev_word=${COMP_WORDS[COMP_CWORD-1]}

  local commands=""
  local flag_opts="-h --help --debug --verbose -D -v --no-fail-on-violation --skip-duplicate-files --ignore-literals --ignore-identifiers --ignore-annotations --ignore-usings --ignore-literal-sequences --skip-lexical-errors --no-skip-blocks --non-recursive"
  local arg_opts="--encoding -e --dir -d --file-list --uri -u --language -l --minimum-tokens --format -f --skip-blocks-pattern --exclude"
  local language_option_args=("apex" "cpp" "cs" "dart" "ecmascript" "fortran" "gherkin" "go" "groovy" "html" "java" "jsp" "kotlin" "lua" "matlab" "modelica" "objectivec" "perl" "php" "plsql" "python" "ruby" "scala" "swift" "vf" "xml") # --language values
  local rendererName_option_args=("csv" "csv_with_linecount_per_file" "text" "vs" "xml") # --format values

  type compopt &>/dev/null && compopt +o default

  case ${prev_word} in
    --encoding|-e)
      return
      ;;
    --dir|-d)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
    --file-list)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
    --uri|-u)
      return
      ;;
    --language|-l)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${language_option_args[@]}" ) )
      return $?
      ;;
    --minimum-tokens)
      return
      ;;
    --format|-f)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${rendererName_option_args[@]}" ) )
      return $?
      ;;
    --skip-blocks-pattern)
      return
      ;;
    --exclude)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
  esac

  if [[ "${curr_word}" == -* ]]; then
    COMPREPLY=( $(compgen -W "${flag_opts} ${arg_opts}" -- "${curr_word}") )
  else
    local positionals=""
    local currIndex
    currIndex=$(currentPositionalIndex "cpd" "${arg_opts}" "${flag_opts}")
    if (( currIndex >= 0 && currIndex <= 2147483647 )); then
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      positionals=$( compgen -f -- "${curr_word}" ) # files
    fi
    local IFS=$'\n'
    COMPREPLY=( $(compgen -W "${commands// /$'\n'}${IFS}${positionals}" -- "${curr_word}") )
  fi
}

# Generates completions for the options and subcommands of the `designer` subcommand.
function _picocli_pmd_designer() {
  # Get completion data
  local curr_word=${COMP_WORDS[COMP_CWORD]}

  local commands=""
  local flag_opts="-h --help --debug --verbose -D -v -V --version"
  local arg_opts=""

  if [[ "${curr_word}" == -* ]]; then
    COMPREPLY=( $(compgen -W "${flag_opts} ${arg_opts}" -- "${curr_word}") )
  else
    local positionals=""
    local IFS=$'\n'
    COMPREPLY=( $(compgen -W "${commands// /$'\n'}${IFS}${positionals}" -- "${curr_word}") )
  fi
}

# Generates completions for the options and subcommands of the `cpd-gui` subcommand.
function _picocli_pmd_cpdgui() {
  # Get completion data
  local curr_word=${COMP_WORDS[COMP_CWORD]}

  local commands=""
  local flag_opts=""
  local arg_opts=""

  if [[ "${curr_word}" == -* ]]; then
    COMPREPLY=( $(compgen -W "${flag_opts} ${arg_opts}" -- "${curr_word}") )
  else
    local positionals=""
    local IFS=$'\n'
    COMPREPLY=( $(compgen -W "${commands// /$'\n'}${IFS}${positionals}" -- "${curr_word}") )
  fi
}

# Generates completions for the options and subcommands of the `ast-dump` subcommand.
function _picocli_pmd_astdump() {
  # Get completion data
  local curr_word=${COMP_WORDS[COMP_CWORD]}
  local prev_word=${COMP_WORDS[COMP_CWORD-1]}

  local commands=""
  local flag_opts="-h --help --debug --verbose -D -v --read-stdin -i"
  local arg_opts="--encoding -e --format -f --language -l -P --file"
  local format_option_args=("xml" "text") # --format values
  local language_option_args=("apex" "ecmascript" "html" "java" "jsp" "kotlin" "modelica" "plsql" "pom" "scala" "swift" "vf" "vm" "wsdl" "xml" "xsl") # --language values
  local StringString_option_args=("singleQuoteAttributes" "lineSeparator" "renderProlog" "renderCommonAttributes" "onlyAsciiChars" "maxLevel") # -P values

  type compopt &>/dev/null && compopt +o default

  case ${prev_word} in
    --encoding|-e)
      return
      ;;
    --format|-f)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${format_option_args[@]}" ) )
      return $?
      ;;
    --language|-l)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${language_option_args[@]}" ) )
      return $?
      ;;
    -P)
      local IFS=$'\n'
      COMPREPLY=( $( compReplyArray "${StringString_option_args[@]}" ) )
      return $?
      ;;
    --file)
      local IFS=$'\n'
      type compopt &>/dev/null && compopt -o filenames
      COMPREPLY=( $( compgen -f -- "${curr_word}" ) ) # files
      return $?
      ;;
  esac

  if [[ "${curr_word}" == -* ]]; then
    COMPREPLY=( $(compgen -W "${flag_opts} ${arg_opts}" -- "${curr_word}") )
  else
    local positionals=""
    local IFS=$'\n'
    COMPREPLY=( $(compgen -W "${commands// /$'\n'}${IFS}${positionals}" -- "${curr_word}") )
  fi
}

# Define a completion specification (a compspec) for the
# `pmd`, `pmd.sh`, and `pmd.bash` commands.
# Uses the bash `complete` builtin (see [6]) to specify that shell function
# `_complete_pmd` is responsible for generating possible completions for the
# current word on the command line.
# The `-o default` option means that if the function generated no matches, the
# default Bash completions and the Readline default filename completions are performed.
complete -F _complete_pmd -o default pmd pmd.sh pmd.bash
