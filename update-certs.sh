#!/bin/bash

set -e
DEBUG="${RUNNER_DEBUG}"
if [[ "$DEBUG" != "" ]]; then
    set -x
fi

function cleanup(){
    if [[ "$DEBUG" != "" ]]; then
        return
    fi

    echo "Cleaning up..."

    rm -rf ./.working
}

trap "cleanup" EXIT INT TERM

if [[ ! -f "./.working/dnsrobocert/config.yml" ]]; then
    echo "Please run detect-requirements.sh before requesting certificates"
    exit 1
fi

# request certificates
CERTS_TO_UPDATE=$(./.yq/yq ".certificates | length" ./.working/dnsrobocert/config.yml)
if [[ "$CERTS_TO_UPDATE" == "0" ]]; then
    echo "No certs need to be updated."
    exit 0
fi

echo "Request $CERTS_TO_UPDATE certificates from Let's Encrypt..."

LE_START_TIME=$(date +%s)
dnsrobocert -c ./.working/dnsrobocert/config.yml -d $(pwd)/.working/letsencrypt --one-shot
LE_END_TIME=$(date +%s)
echo "Certificate application took $(( $LE_END_TIME - $LE_START_TIME ))s"


if [[ "$DEBUG" != "" ]]; then
    echo "dnsrobocert debug log:"
    cat ./.working/letsencrypt/logs/letsencrypt.log
fi

# extract certificates
for DOMAIN in $(./.yq/yq '.certificates[].domains[0]' ./.working/dnsrobocert/config.yml); do
    if [[ ! -d "./.working/letsencrypt/live/$DOMAIN" ]] || [[ ! -f "./.working/letsencrypt/live/$DOMAIN/cert.pem" ]]; then
        echo "Warning: certificates for '$DOMAIN' not found!"
    else
        FOLDER=certs
        if [[ "$DEBUG" != "" ]]; then
            FOLDER=staging-certs
        fi
        mkdir -p ./$FOLDER/$DOMAIN

        # privkey.pem, cert.pem, fullchain.pem, chain.pem
        # https://eff-certbot.readthedocs.io/en/latest/using.html#where-are-my-certificates
        cp -rL ./.working/letsencrypt/live/$DOMAIN/. ./$FOLDER/$DOMAIN/
    fi
done