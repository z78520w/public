#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
stty erase ^H

sh_ver='1.1.5'
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

echo "cd $(pwd)" > /root/.bashrc

if [[ -f /etc/redhat-release ]]; then
	release="centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
	release="debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
	release="ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
	release="centos"
elif cat /proc/version | grep -q -E -i "debian"; then
	release="debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
	release="ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
	release="centos"
fi
if [[ ${release} == "centos" ]]; then
	PM='yum'
else
	PM='apt'
fi
ssh_port=$(hostname -f|awk -F '-' '{print $2}')
HOSTNAME="$(hostname -f|awk -F "${ssh_port}-" '{print $2}').cloudshell.dev"
IP=$(curl -s ipinfo.io/ip)
[ -z ${IP} ] && IP=$(curl -s http://api.ipify.org)
[ -z ${IP} ] && IP=$(curl -s ipv4.icanhazip.com)
[ -z ${IP} ] && IP=$(curl -s ipv6.icanhazip.com)
pw=$(tr -dc 'A-Za-z0-9!@#$%^&*()[]{}+=_,' </dev/urandom | head -c 17)
echo root:${pw} |chpasswd
sed -i '1,/PermitRootLogin/{s/.*PermitRootLogin.*/PermitRootLogin yes/}' /etc/ssh/sshd_config
sed -i '1,/PasswordAuthentication/{s/.*PasswordAuthentication.*/PasswordAuthentication yes/}' /etc/ssh/sshd_config
if [[ ${release} == "centos" ]]; then
	service sshd restart
else
	service ssh restart
fi

clear
green_font '免费撸谷歌云一键脚本' "版本号：${sh_ver}"
echo -e "            \033[37m\033[01m--胖波比--\033[0m\n"
echo -e "${Info}主机名1：  $(red_font $HOSTNAME)"
echo -e "${Info}主机名2：  $(red_font $IP)"
echo -e "${Info}SSH端口：  $(red_font $ssh_port)"
echo -e "${Info}用户名：   $(red_font root)"
echo -e "${Info}密码是：   $(red_font $pw)"

echo -e "\n${Tip}请务必记录您的登录信息！！"
yello_font '——————————————————————————————————————————————————————————'
green_font ' 1.' '  用这个Cloud Shell定时唤醒另一个Cloud Shell'
green_font ' 2.' '  如果你想在另一个服务器上定时唤醒这个Cloud Shell'
green_font ' 3.' '  赞赏作者'
green_font ' 4.' '  退出'
yello_font '——————————————————————————————————————————————————————————'

github='https://raw.githubusercontent.com/AmuyangA/public/master'
one_to_another(){
	app_name="$(pwd)/sshcopy"
	if [ ! -e $app_name ]; then
		echo -e "${Info}正在下载免密登录程序..."
		wget -qO $app_name https://github.com/Jrohy/sshcopy/releases/download/v1.4/sshcopy_linux_386 && chmod +x $app_name
	fi

	clear && echo
	read -p "请输入远程服务器的IP(主机名2)：" IP
	read -p "请输入 ${IP} 的SSH端口(默认:6000)：" ssh_port
	[ -z $ssh_port ] && ssh_port='6000'
	read -p "请输入 ${IP} 的登录用户(默认:root)：" user
	[ -z $user ] && user='root'
	read -p "请输入 ${IP} 的登录密码：" passward

	$app_name -ip $IP -user $user -port $ssh_port -pass $passward

	if [ -e /var/spool/cron/root ]; then
		corn_path='/var/spool/cron/root'
	elif [ -e /var/spool/cron/crontabs/root ]; then
		corn_path='/var/spool/cron/crontabs/root'
	else
		corn_path="$(pwd)/temp"
		echo 'SHELL=/bin/bash' > $corn_path
	fi

	echo "*/10 * * * *  ssh -p ${ssh_port} ${user}@${IP}" >> $corn_path
	if [[ $corn_path == "$(pwd)/temp" ]]; then
		crontab -u root $corn_path
		rm -f $corn_path
	fi
	echo -e "${Info}定时任务添加成功！"
	/etc/init.d/cron restart
}
donation_developer(){
	yello_font '您的支持是作者更新和完善脚本的动力！'
	yello_font '请访问以下网址扫码捐赠：'
	green_font "[支付宝] \c" && white_font "${github}/donation/alipay.jpg"
	green_font "[微信]   \c" && white_font "${github}/donation/wechat.png"
	green_font "[银联]   \c" && white_font "${github}/donation/unionpay.png"
	green_font "[QQ]     \c" && white_font "${github}/donation/qq.png"
	start_menu
}

start_menu(){
	echo && read -p "请输入数字[1-4](默认:1)：" num
	[ -z $num ] && num=1
	case "$num" in
		1)
		one_to_another
		;;
		2)
		echo '在另一台服务器上运行以下一键脚本：'
		green_font "wget -O gcs_k.sh ${github}/gcs/gcs_k.sh && chmod +x gcs_k.sh && ./gcs_k.sh"
		start_menu
		;;
		3)
		donation_developer
		;;
		4)
		exit 0
		;;
		*)
		echo -e "${Error}请输入正确数字 [1-4]"
		start_menu
		;;
	esac
	echo -e "\n${Info}如果您之前在 $(green_font 'https://ssh.cloud.google.com') 执行过此脚本"
	echo -e "${Info}那么以后再执行此脚本只需运行 $(red_font './gcs.sh') 即可，即使机器重置也不受影响"
	echo -e "${Info}更新脚本命令：$(green_font 'wget -O gcs.sh '${github}'/gcs/gcs.sh && chmod +x gcs.sh')"
}
start_menu