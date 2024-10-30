#!/bin/bash

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPT_PATH

tar xzvf $(ls *.certs.tar.gz)


NS=$1
SECRET_NAME=$2
WORKLOAD_NAME=$3

kubectl -n $NS get secret/$SECRET_NAME -o yaml > $SECRET_NAME-backup.yaml

kubectl -n $NS delete secret/$SECRET_NAME
kubectl -n $NS create secret tls $SECRET_NAME --cert=./fullchain.pem --key=./privkey.pem

DEPLOYMENT=$(kubectl -n $NS get deploy $WORKLOAD_NAME -o Name | grep $WORKLOAD_NAME)
if [[ ! -z "$DEPLOYMENT" ]]; then
    kubectl -n $NS rollout restart deploy/$WORKLOAD_NAME
fi

STATEFUL_SET=$(kubectl -n $NS get statefulset $WORKLOAD_NAME -o Name | grep $WORKLOAD_NAME)
if [[ ! -z "$STATEFUL_SET" ]]; then
fi

DAEMON_SET=$(kubectl -n $NS get daemonset $WORKLOAD_NAME -o Name | grep $WORKLOAD_NAME)
if [[ ! -z "$DAEMON_SET" ]]; then
fi


