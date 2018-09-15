#!/usr/bin/env bash

# A startup script to initialise a new sentry installation and setup the default user
set -o errexit
set -o nounset

if [[ -n "${SENTRY_ADMIN_PASSWORD_ENCRYPTED:-""}" ]]; then 
    echo ${SENTRY_ADMIN_PASSWORD#"base64:"}| base64 -d > "/tmp/cipher.blob"
    SENTRY_ADMIN_PASSWORD="$(aws --region "${AWS_REGION}" kms decrypt --ciphertext-blob "fileb:///tmp/cipher.blob" --output text --query Plaintext | base64 -d || return $?)"
fi

#Run Upgrade/Migration 
sentry upgrade --noinput 

#Create default admin user
user_status=0
sentry permissions list --user "${SENTRY_ADMIN_EMAIL}" || user_status=$? 

if [[ "${user_status}" != 0 ]]; then
    sentry createuser --no-input --email "${SENTRY_ADMIN_EMAIL}" --password "${SENTRY_ADMIN_PASSWORD}" --superuser 
else
    echo "user ${SENTRY_ADMIN_EMAIL} already exists"
fi