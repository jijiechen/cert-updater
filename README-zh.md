
# 新增一个证书
1. 打开 `config.yaml` 在 `certificates.domains` 下面增加 certificates 和/或 domains 记录


# 强制立即申请一个证书
1. 删除 `certs` 下的对应目录，并 push 到仓库，然后执行 update-certs 任务


# 临时为某域名申请一个证书
1. 手动启动运行 update-certs 任务


