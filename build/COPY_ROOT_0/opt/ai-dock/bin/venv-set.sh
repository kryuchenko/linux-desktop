#!/bin/bash

# Simple venv setup script
# In a real setup, this would activate different virtual environments
# For now, we'll just set some basic variables

case "$1" in
    serviceportal)
        export SERVICEPORTAL_VENV=/opt/ai-dock/venv/serviceportal
        export SERVICEPORTAL_VENV_PYTHON=python3
        ;;
    selkies)
        export SELKIES_VENV=/opt/ai-dock/venv/selkies
        ;;
    *)
        echo "Unknown venv: $1"
        ;;
esac