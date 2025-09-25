#!/bin/bash
# Install common Linux package managers (apt, yum, dnf, zypper)
if command -v apt >/dev/null 2>&1; then
    echo "apt is already available."
elif command -v yum >/dev/null 2>&1; then
    echo "yum is already available."
elif command -v dnf >/dev/null 2>&1; then
    echo "dnf is already available."
elif command -v zypper >/dev/null 2>&1; then
    echo "zypper is already available."
else
    echo "No common package manager found. Please install one manually."
fi
