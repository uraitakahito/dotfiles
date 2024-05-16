# Checks if running on MacOS Darwin.
function is-darwin {
  [[ "$OSTYPE" == darwin* ]]
}

# Checks if running on Visual Studio Code Terminal.
function is-vscode {
  [[ "$TERM_PROGRAM" == "vscode" ]]
}

# Checks if script is being executed by VS Code.
# NOTE:
#  1. After installation, this environment variable will be removed.
#  2. When install.sh is executed, the 'code' CLI is not yet installed.
function has-vscode-remote-containers {
  [[ -n "${VSCODE_REMOTE_CONTAINERS_SESSION:-}" ]]
}

function has-path {
  [[ -n "${PATH:-}" ]]
}
