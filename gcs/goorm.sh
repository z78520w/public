#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
stty erase ^H

sh_ver='1.0.0'
green_font(){
	echo -e "\033[32m\033[01m$1\033[0m\033[37m\033[01m$2\033[0m"
}
red_font(){
	echo -e "\033[31m\033[01m$1\033[0m"
}
white_font(){
	echo -e "\033[37m\033[01m$1\033[0m"
}
yello_font(){
	echo -e "\033[33m\033[01m$1\033[0m"
}
Info=`green_font [信息]` && Error=`red_font [错误]` && Tip=`yello_font [注意]`

[ $(id -u) != '0' ] && { echo -e "${Error}您必须以root用户运行此脚本！\n${Info}使用$(red_font 'sudo su')命令切换到root用户！"; exit 1; }

app_name="$(pwd)/sshcopy"
if [ ! -e $app_name ]; then
	echo -e "${Info}正在下载免密登录程序..."
	wget -qO $app_name https://github.com/Jrohy/sshcopy/releases/download/v1.4/sshcopy_linux_386 && chmod +x $app_name
fi

clear && echo
unset IP ssh_port passward
until [[ -n $IP ]]
do
	read -p "请输入Goorm服务器的IP：" IP
done
until [[ -n $ssh_port ]]
do
	read -p "请输入 ${IP} 的SSH端口：" ssh_port
done
until [[ -n $passward ]]
do
	read -p "请输入 ${IP} 的登录密码：" passward
done

$app_name -ip $IP -user root -port $ssh_port -pass $passward

if [ -e /var/spool/cron/root ]; then
	corn_path='/var/spool/cron/root'
elif [ -e /var/spool/cron/crontabs/root ]; then
	corn_path='/var/spool/cron/crontabs/root'
else
	corn_path="$(pwd)/temp"
	echo 'SHELL=/bin/bash' > $corn_path
fi

echo "*/2 * * * *  ssh -p ${ssh_port} root@${IP}" >> $corn_path
if [[ $corn_path == "$(pwd)/temp" ]]; then
	crontab -u root $corn_path
	rm -f $corn_path
fi
echo -e "${Info}定时任务添加成功！"

donation_developer(){
	github='https://raw.githubusercontent.com/AmuyangA/public/master'
	yello_font '您的支持是作者更新和完善脚本的动力！'
	yello_font '请访问以下网址扫码捐赠：'
	green_font "[支付宝] \c" && white_font "${github}/donation/alipay.jpg"
	green_font "[微信]   \c" && white_font "${github}/donation/wechat.png"
	green_font "[银联]   \c" && white_font "${github}/donation/unionpay.png"
	green_font "[QQ]     \c" && white_font "${github}/donation/qq.png"
}
echo && read -p "是否捐赠作者?[y:是 n:退出脚本](默认:n)：" num
[ -z $num ] && num='n'
if [[ $num != 'n' ]]; then
	donation_developer
fi
