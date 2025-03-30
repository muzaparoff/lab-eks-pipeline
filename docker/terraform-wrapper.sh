#!/bin/bash

# If the command is 'plan -upgrade', convert it to proper flags
if [ "$1" = "plan" ] && [ "$2" = "-upgrade" ]; then
    terraform init -upgrade
    terraform plan
else
    terraform "$@"
fi
