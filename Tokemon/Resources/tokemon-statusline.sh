#!/bin/sh
# =============================================================================
# Tokemon Terminal Statusline Helper
# =============================================================================
#
# This script provides shell functions to display Claude usage in your terminal
# prompt. The Tokemon app writes usage data to ~/.tokemon/statusline which this
# script reads and formats for display.
#
# INSTALLATION
# ------------
# Add this line to your ~/.bashrc or ~/.zshrc:
#
#   [ -f ~/.tokemon/tokemon-statusline.sh ] && source ~/.tokemon/tokemon-statusline.sh
#
# USAGE - BASH
# ------------
# Add $(tokemon_statusline) to your PS1:
#
#   PS1='$(tokemon_statusline) \u@\h:\w\$ '
#
# USAGE - ZSH
# -----------
# Enable prompt substitution and add to PROMPT:
#
#   setopt PROMPT_SUBST
#   PROMPT='$(tokemon_statusline) %n@%m:%~%# '
#
# OPTIONS
# -------
# To disable colors, set TOKEMON_COLOR=0 before sourcing:
#
#   export TOKEMON_COLOR=0
#
# FILES
# -----
# ~/.tokemon/statusline       - Plain text statusline (no ANSI codes)
# ~/.tokemon/statusline-color - Colored statusline (with ANSI codes)
# ~/.tokemon/status.json      - Raw JSON data for custom integrations
#
# =============================================================================

# Get file age in seconds (handles both GNU and BSD stat)
_tokemon_file_age() {
    _file="$1"
    if stat -c %Y "$_file" >/dev/null 2>&1; then
        # GNU stat
        _mtime=$(stat -c %Y "$_file")
    else
        # BSD stat (macOS)
        _mtime=$(stat -f %m "$_file")
    fi
    _now=$(date +%s)
    echo $((_now - _mtime))
}

# Main statusline function for shell prompts
tokemon_statusline() {
    _statusline_file="$HOME/.tokemon/statusline"
    _statusline_color="$HOME/.tokemon/statusline-color"

    # Check if file exists
    if [ ! -f "$_statusline_file" ]; then
        return 0
    fi

    # Check file age (stale if older than 5 minutes)
    _age=$(_tokemon_file_age "$_statusline_file")
    if [ "$_age" -gt 300 ]; then
        return 0
    fi

    # Choose colored or plain based on TOKEMON_COLOR env var
    if [ "$TOKEMON_COLOR" = "0" ] || [ "$TOKEMON_COLOR" = "false" ]; then
        _use_file="$_statusline_file"
    elif [ -f "$_statusline_color" ]; then
        _use_file="$_statusline_color"
    else
        _use_file="$_statusline_file"
    fi

    # Output without trailing newline
    printf "%s" "$(cat "$_use_file")"
}

# JSON output function for custom integrations
tokemon_json() {
    _json_file="$HOME/.tokemon/status.json"

    if [ -f "$_json_file" ]; then
        cat "$_json_file"
    fi
}
