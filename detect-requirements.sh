#!/bin/bash

set -e
DAYS_BEFORE_RENEW=15
DEBUG="${RUNNER_DEBUG}"
if [[ "$DEBUG" != "" ]]; then
    set -x
fi

TMP_CONFIG_FILE=$(mktemp)
function cleanup(){
    if [[ "$DEBUG" != "" ]]; then
        return
    fi

    echo "Cleaning up..."
    rm -f $TMP_CONFIG_FILE
}

trap "cleanup" EXIT INT TERM


if [[ "$DNSPOD_API_KEY" == "" ]]; then
    echo "Environment varible 'DNSPOD_API_KEY' is missing.."
    exit 1
fi
if [[ "$DNSPOD_API_TOKEN" == "" ]]; then
    echo "Environment varible 'DNSPOD_API_TOKEN' is missing.."
    exit 1
fi

# download yq
if [[ ! -f "./.yq/yq" ]]; then
    echo "Downloading yq..."
    (mkdir .yq && cd .yq; VERSION=v4.42.1 BINARY=yq_linux_amd64 bash -c 'curl -sL https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -o /dev/stdout | tar xz && mv ${BINARY} ./yq')
fi

for DOMAIN_COUNT in $(./.yq/yq '.certificates[].domains | length' ./config.yml); do
    if [[ "$DOMAIN_COUNT" -ge 2 ]]; then
        echo "Please do not include more than 1 domain in a certificate request, because we are always requesting wildcard certicicates for root domains."
        exit 1
    fi
done

# find domains
echo "finding domains to apply for certificates:"
SKIPPED_DOMAINS='['
CURRENT_TIMESTAMP=$(date +%s)

echo ""
for DOMAIN in $(./.yq/yq '.certificates[].domains[]' ./config.yml); do
    if [[ "${DOMAIN:0:2}" == "*." ]]; then
        # we only apply for wildcard certificates, so don't need to use *.
        echo "Don't use '*.' as prefix in '$DOMAIN', as we by default apply for wildcard domains."
        exit 1
    fi

    if [[ -d "./certs/$DOMAIN" ]] && [[ -f "./certs/$DOMAIN/cert.pem" ]]; then
        EXPIRY_TIMESTAMP=$(date --date="$(openssl x509 -enddate -noout -in ./certs/$DOMAIN/cert.pem | cut -d= -f 2)" +%s)
        EXPIRY_DAYS="$(( ($EXPIRY_TIMESTAMP - $CURRENT_TIMESTAMP) / (3600 * 24) ))"
        # skip certificates with longer EXPIRY_DAYS 
        if [[ "$EXPIRY_DAYS" -gt $DAYS_BEFORE_RENEW ]]; then
            if [[ "$SKIPPED_DOMAINS" != "[" ]]; then
                SKIPPED_DOMAINS="$SKIPPED_DOMAINS,"
            fi
            SKIPPED_DOMAINS="$SKIPPED_DOMAINS\"$DOMAIN\""
        else
            echo "*.$DOMAIN (expiring in $EXPIRY_DAYS days)"
        fi
    else
        echo "*.$DOMAIN (new)"
    fi
done
SKIPPED_DOMAINS="${SKIPPED_DOMAINS}]"

cp ./config.yml $TMP_CONFIG_FILE
if [[ "$DEBUG" != "" ]]; then
    ./.yq/yq -i '.acme.staging = true' ${TMP_CONFIG_FILE}
fi

CERT_COUNT=$(./.yq/yq '.certificates | length' $TMP_CONFIG_FILE)
declare -a CERTS_TO_REMOVE
CURRENT=0
while [[ $CURRENT -lt $CERT_COUNT ]]; do
    cp $TMP_CONFIG_FILE ${TMP_CONFIG_FILE}.old
    cat ${TMP_CONFIG_FILE}.old \
    | ./.yq/yq ".certificates[ $CURRENT ].domains = .certificates[ $CURRENT ].domains - $SKIPPED_DOMAINS" \
    | ./.yq/yq ".certificates[ $CURRENT ].domains += [ \"*.\" + .certificates[ $CURRENT ].domains[0] ]" \
    | ./.yq/yq "del(.certificates[ $CURRENT ].pushes)" \
    > ${TMP_CONFIG_FILE}
    
    DOMAIN_COUNT=$(./.yq/yq ".certificates[ $CURRENT ].domains | length" ${TMP_CONFIG_FILE})
    if [[ "$DOMAIN_COUNT" -le 1 ]]; then
        CERTS_TO_REMOVE+=( "$CURRENT" )
    fi
    CURRENT=$(( CURRENT+1 ))
done
rm -f ${TMP_CONFIG_FILE}.old
for TO_REMOVE in $(echo "${CERTS_TO_REMOVE[@]}" | rev); do
    ./.yq/yq -i "del(.certificates[ $TO_REMOVE ])" ${TMP_CONFIG_FILE}
done
CERTS_TO_UPDATE=$(./.yq/yq ".certificates | length" ${TMP_CONFIG_FILE})
if [[ "$CERTS_TO_UPDATE" == "0" ]]; then
    echo "No certs need to be updated."
    exit 0
fi

# generate config file
rm -rf ./.working
mkdir -p ./.working/dnsrobocert
mkdir -p ./.working/letsencrypt

cat ${TMP_CONFIG_FILE} \
    | sed "s:DNSPOD_API_KEY:$DNSPOD_API_KEY:g" \
    | sed "s:DNSPOD_API_TOKEN:$DNSPOD_API_TOKEN:g" \
    | sudo tee ./.working/dnsrobocert/config.yml > /dev/null

if [[ "$DEBUG" != "" ]]; then
    cat ./.working/dnsrobocert/config.yml
fi
