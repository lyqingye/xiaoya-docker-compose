# 简介
xiaoya emby docker-copmose 一键启动. 只要有docker, 无需考虑宿主机兼容性.

# 环境要求
- docker
- linux系统(任意发行版)
- 科学上网(tun模式), 确保镜像能正常构建

# 功能
- [x] 部署 xiaoya-alist
- [x] 部署 emby
- [x] 元数据定时更新下载(全量下载, 非爬虫)
- [x] xiaoya-alist 容器定时更新重启
- [ ] 元数据爬虫
- [ ] 阿里云定时清理
- [ ] 保留用户配置

# 配置
- ./alist/myopentoken.txt
- ./alist/mytoken.txt
- ./alist/temp_transfer_folder_id.txt

具体配置参考: https://xiaoyaliu.notion.site/xiaoya-docker-69404af849504fa5bcf9f2dd5ecaa75f#1d0efe7db420490894c025525954090b

# 部署
```shell
# 拉取镜像(首次运行)
docker-compose pull

# 构建镜像(首次运行)
docker-copmose build

# 启动
docker-compose up -d
```