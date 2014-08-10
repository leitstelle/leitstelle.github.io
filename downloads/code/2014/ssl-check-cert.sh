#!/usr/bin/env bash
# Download this script directly:
# wget --no-check-certificate https://leitstelle.salzkraftwerk.org/downloads/code/2014/ssl-check-cert.sh

# Check if domain is given as first argument.
if [ -z "${1}" ]; then
    DOMAIN="domain.tld"
else
    DOMAIN=${1}
fi

cd ~/.ssl

# KEY
if [ -f "${DOMAIN}.private.pem" ]; then
	echo -e "\e[93m Check your private key.\e[0m"
	openssl rsa -in ${DOMAIN}.private.pem -check
else
	echo "No private key available."
fi

# CSR
if [ -f "${DOMAIN}.request.csr" ]; then
	echo -e "\e[93m Check your certificate request.\e[0m"
	openssl req -text -noout -verify -in ${DOMAIN}.request.csr
else
	echo "No certificate request available."
fi

# CRT
if [ -f "${DOMAIN}.pem.crt" ]; then
	echo -e "\e[93m Check your public certificate.\e[0m"
	openssl x509 -in ${DOMAIN}.crt.pem -noout -text
else
	echo "No public certificate available."
fi

# Uberspace
echo -e "\e[93m Check for uberspace users.\e[0m"
   if [ -f /usr/local/bin/uberspace-prepare-certificate ]; then
        uberspace-prepare-certificate -k ~/.ssl/${DOMAIN}.private.pem -c ~/.ssl/${DOMAIN}.crt.pem
   else
	echo "You are using no uberspace account."
   fi

