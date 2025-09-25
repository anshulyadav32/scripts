#!/bin/bash
# Linux equivalent: install apt (for Ubuntu/Debian)
if command -v apt >/dev/null 2>&1; then
    echo "apt is already installed."
else
    echo "apt is not installed. Please use your distribution's package manager."
fi
