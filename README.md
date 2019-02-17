# Simple Docker Nginx With PureFTP
> **注意：目前还未开发完成，仅有基本功能。**
### 简介
将Nginx与PureFTP安装在同一个Docker alpine:3.9 容器中，供个人博客使用。
- 支持PureFTP虚拟用户
- 解决Nginx与PureFTP文件权限冲突问题（二者都使用www用户）
### 使用
0. 使用dos2unix替换文件中的^M字符（windows文本编辑器遗留问题，等待修复）
1. 修改ftppassfile中的密码（虚拟FTP账户www的用户密码）
2. 修改docker-nginx中的配置文件
3. 修改docker-pureftpd中的配置文件
4. 根据以上情况调整Dockerfile，例如新增虚拟主机文件夹等
5. Docker打包镜像sudo docker build -t  miaomi .  
6. 新建容器并运行
``` shell
sudo docker run -d -p 20-21:20-21 \
    -p 21000-21010:21000-21010 \
    -p 80:80 -p 443:443 \
    --name test1 miaomi:latest
```
### TODO 等待完成
- 关联Nginx与PureFTP配置文件到本地。
- 增加更易使用的PureFTP增加新虚拟用户脚本。
- 增加更易使用的Nginx、PureFTP开启或重启等命令脚本。
- 增加PHP-fpm。
