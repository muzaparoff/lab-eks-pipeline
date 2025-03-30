#!/bin/bash
export TF_VAR_db_password=$(openssl rand -base64 16)
echo "Generated database password and set as TF_VAR_db_password"
echo "You may want to save this password: $TF_VAR_db_password"
