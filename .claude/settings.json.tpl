{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {{POST_EDIT_HOOK_ENTRIES}}
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git show:*)",
      "Bash(git branch:*)",
      "Bash(git fetch:*)",
      "Bash(git rev-parse:*)",
      {{PROJECT_ALLOW_ENTRIES}}
    ]
  }
}
