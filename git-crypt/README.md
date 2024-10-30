
# Use with a Git Repo

```sh
git clone <repo-url>
git-crypt unlock <path-to-key-file>
```

# Decrypt a single file

```sh
cat ./encrypted-file | ./decrypt.sh --key-file <path-to-key-file>
```

# Issues
 * error while loading shared libraries: libcrypto.so.1.1: cannot open shared object file: No such file or directory
 * invalid exec format (running amd64 binary on a ARM system?)


## Solution:

### On ubuntu 22:

```sh
wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
```

### Other OS, including CentOS 7, and ARM systems:

Needs to recompile from source.

```sh
git clone https://github.com/AGWA/git-crypt.git
git checkout tag/0.7.0  # Git SHA: a1e6311f5622fb6b9027fc087d16062c7261280f
# incase you need a compiler on CentOS 7:
# yum install -y gcc-c++
make build
make install
# now you can use git-crypt
```