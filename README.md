
## Initialize git-crypt

This repo stores confidential information so it needs to be crypted.

We use [git-crypt](https://github.com/AGWA/git-crypt) to crypt private keys of SSH keys and certificates.

(todo)

## Request and push certificate automatically

1. Fork this repo and enable GitHub Action in your forked repo.
2. Create your own branch
3. Add an Action variable `CERTS_BRANCH` and set its value to the name of your branch

(todo)

## Request certificates

### Request certificates for a new domain
1. Open `config.yaml` and add item under `certificates` or add an domain element under an exsiting certificate element.


### Force to request new certificate for domain
1. Delete the corresponding directory under `certs`, push your updates to remote and trigger the workflow `update-certs` manually.


### Request a certificate on demand
1. Trigger the workflow `update-certs` manually with specified domain name.


## Configure your pushes

We support these kinds of pushes after certs are requests:
- SSH
- Tencent Cloud CDN
- Tencent Cloud API Gateway (this service is being deprecated)

### Push to SSH

When you want to push to a server using SSH, you need to:
1. Generaete your key pair and store it under the `ssh` directory
2. Author your installer scripts to use the certificates

### Push to Tencent Cloud

(todo)