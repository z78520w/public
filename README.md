## 支持CentOS,Debian,Ubuntu
此脚本所有功能可以共存在一台VPS上。小白使用V2Ray的话，安装或者添加用户之后请设置为websocket传输，否则默认kcp会被Qos，老司机请自由发挥。
使用Trojan域名模式请确认域名解析生效后再安装，如果证书申请失败则无法使用，自己有受信任证书上传到/root/certificate文件夹替换证书和私钥重启Trojan即可使用。NaiveProxy设置的是只能用域名和证书，否则就失去了它的意义。更多玩法自行摸索。。。有疑问留issue
## 超级VP.一键脚本
wget --no-check-certificate https://raw.githubusercontent.com/AmuyangA/public/master/svok && chmod +x svok && ./svok

![avatar](https://raw.githubusercontent.com/AmuyangA/public/master/donation/show.png)
