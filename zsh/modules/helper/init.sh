# Checks if running on MacOS Darwin.
function is-darwin {
  [[ "$OSTYPE" == darwin* ]]
}

# Checks if running on Visual Studio Code.
function is-vscode {
  [[ "$TERM_PROGRAM" == "vscode" ]]
}
