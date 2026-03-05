function command_exists_guard() {
    if [ -z $(command -v "$1") ]; then
        echo "ERROR: Command '$1' not installed!" >&2
        exit 1
    fi
}

