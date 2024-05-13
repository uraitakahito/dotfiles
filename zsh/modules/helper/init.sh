# Checks if running on MacOS Darwin.
function is-darwin {
  [[ "$OSTYPE" == darwin* ]]
}

# Checks if running on Visual Studio Code Terminal.
function is-vscode {
  [[ "$TERM_PROGRAM" == "vscode" ]]
}

# Checks if running on VSCode and Remote Containers.
function has-vscode-remote-containers {
  [[ -n "${VSCODE_REMOTE_CONTAINERS_SESSION:-}" ]]
}

function has-path {
  [[ -n "${PATH:-}" ]]
}
