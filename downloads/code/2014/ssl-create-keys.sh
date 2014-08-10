#!/usr/bin/env bash
# Download this script directly:
# wget --no-check-certificate https://leitstelle.salzkraftwerk.org/downloads/code/2014/ssl-create-keys.sh

# Check if domain is given as first argument.
if [ -z "${1}" ]; then
    DOMAIN="domain.tld"
else
    DOMAIN=${1}
fi

mkdir -p ~/.ssl
cd ~/.ssl

# RSA-key pair with 4096 Bit key length.
# With a password:
#  openssl genrsa -aes256 -out ${DOMAIN}.private.pem 4096
# Without a password:
openssl genrsa -out ${DOMAIN}.private.pem 4096
openssl rsa -inform pem -in ${DOMAIN}.private.pem -outform pem -out ${DOMAIN}.private.key
openssl rsa -inform pem -in ${DOMAIN}.private.pem -outform der -out ${DOMAIN}.private.der

# Cert request for a X.509 cert, valid for 3 days.
# In interactive mode, you get a few questions asked. In the example here not. ;-)
# Important is 'CN (Common Name)'; Write here your '$DOMAIN'.
# If you want use '*.$DOMAIN', add it in 'CN' the field.
# If you want use '*.$DOMAIN.', add it as well.
openssl req -new -key ${DOMAIN}.private.pem -out ${DOMAIN}.request.csr -days 3 -subj "/CN=*.${DOMAIN}/CN=${DOMAIN}/CN=.${DOMAIN}./CN=${DOMAIN}."

