#!/bin/bash

# Prerequisites script for Kubernetes installation

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package index
echo "Updating package index..."
sudo apt-get update

# Install required packages
REQUIRED_PACKAGES=(
    "curl"
    "apt-transport-https"
    "ca-certificates"
    "software-properties-common"
)

for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! command_exists "$package"; then
        echo "Installing $package..."
        sudo apt-get install -y "$package"
    else
        echo "$package is already installed."
    fi
done

# Disable swap
if [ "$(swapon --show)" ]; then
    echo "Disabling swap..."
    sudo swapoff -a
    sudo sed -i '/ swap / s/^/#/' /etc/fstab
else
    echo "Swap is already disabled."
fi

# Check for Docker installation
if command_exists "docker"; then
    echo "Docker is installed. Please ensure it is not running before proceeding."
else
    echo "Docker is not installed. Please install Docker if required."
fi

echo "Prerequisites check completed."