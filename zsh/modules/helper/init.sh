# Checks if running on MacOS Darwin.
function is-darwin {
  [[ "$OSTYPE" == darwin* ]]
}

# Checks if running on Visual Studio Code Terminal.
function is-vscode {
  [[ "$TERM_PROGRAM" == "vscode" ]]
}

# Checks if running on VSCode and Remote Containers.
function is-vscode-remote-containers {
  [[ -z "${VSCODE_REMOTE_CONTAINERS_SESSION:-true}" ]]
}

function has-path {
  [[ -z "${PATH:-true}" ]]
}
