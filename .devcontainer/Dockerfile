{
  "name": "codespace-egress-controlled",
  "build": { "dockerfile": "Dockerfile" },
  // NET_ADMIN is required for the container to manage its own iptables rules.
  "runArgs": ["--cap-add=NET_ADMIN"],
  // Applies the DNS allow-list + iptables lockdown on every start.
  "postStartCommand": "bash .devcontainer/egress-lockdown.sh",
  "remoteUser": "vscode",
  "customizations": {
    "vscode": {
      "extensions": [
        "cweijan.vscode-office"
      ],
      "settings": {
        "extensions.allowedExtensions": [
          "cweijan.vscode-office",
          "ms-python.python",
          "GitHub.copilot",
          "ms-azuretools.vscode-docker"
        ],
        "extensions.allowedWorkspaceExtensions": [
          "cweijan.vscode-office",
          "ms-python.python",
          "GitHub.copilot",
          "ms-azuretools.vscode-docker"
        ]
      }
    }
  }
}
