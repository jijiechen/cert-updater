#!/bin/bash

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
KEY_FILE=$SCRIPT_PATH/../.working/git-crypt-key
ENCRYPTED_FILE=

function print_usage(){
  echo "cat ./encrypted | ./decrypt.sh --key-file <path-to-key-file>"
  echo "OR"
  echo "./decrypt.sh --key-file <path-to-key-file> --file <path-to-encrypted-file>"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --key-file)
      KEY_FILE="$2"
      shift
      shift
      ;;
    --file)
      ENCRYPTED_FILE="$2"
      shift
      shift
      ;;
    --help)
      print_usage
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

if [[ ! "$KEY_FILE" ]]; then
  echo "key file not found."
  echo ""
  print_usage
  exit 1
fi

mkdir -p $SCRIPT_PATH/../.git-crypt
EXE=$SCRIPT_PATH/git-crypt-debian-amd64
if [[ -f "/etc/centos-release" ]]; then
    EXE=$SCRIPT_PATH/git-crypt-centos-amd64
fi
if [[ ! -f "$SCRIPT_PATH/../.git-crypt/git-crypt" ]]; then
  cp $EXE $SCRIPT_PATH/../.git-crypt/git-crypt
  chmod +x $SCRIPT_PATH/../.git-crypt/git-crypt
fi
EXE=$SCRIPT_PATH/../.git-crypt/git-crypt

if [[ "$ENCRYPTED_FILE" != "" ]]; then
    cat $ENCRYPTED_FILE | $EXE smudge --key-file $KEY_FILE
else
    cat <&0 | $EXE smudge --key-file $KEY_FILE
fi