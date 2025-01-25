#!/bin/bash

echo "Stopping Docker if running..."
osascript -e 'quit app "Docker"' 2>/dev/null

echo "Uninstalling Docker from Homebrew..."
brew uninstall --cask --force docker 2>/dev/null

echo "Removing Docker app and related files..."
sudo rm -rf /Applications/Docker.app
sudo rm -rf ~/Library/Group\ Containers/group.com.docker
sudo rm -rf ~/Library/Containers/com.docker.docker
sudo rm -rf ~/.docker

echo "Removing Docker binaries..."
sudo rm -f /usr/local/bin/docker
sudo rm -f /usr/local/bin/docker-compose
sudo rm -f /usr/local/bin/docker-credential-desktop
sudo rm -f /usr/local/bin/docker-credential-osxkeychain
sudo rm -f /opt/homebrew/bin/docker
sudo rm -f /opt/homebrew/bin/docker-compose

echo "Removing Docker completion files..."
sudo rm -f /opt/homebrew/share/zsh/site-functions/_docker
sudo rm -f /opt/homebrew/share/zsh/site-functions/_docker-compose
sudo rm -f /opt/homebrew/share/fish/vendor_completions.d/docker.fish
sudo rm -f /opt/homebrew/share/fish/vendor_completions.d/docker-compose.fish

echo "Cleanup complete!"
