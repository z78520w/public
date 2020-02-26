#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

clear
setup_path="/www"
if [ "$1" ];then
	IDC_CODE=$1
fi
get_ip(){
	IP=$(curl -s ipinfo.io/ip)
	[ -z ${IP} ] && IP=$(curl -s http://api.ipify.org)
	[ -z ${IP} ] && IP=$(curl -s ipv4.icanhazip.com)
	[ -z ${IP} ] && IP=$(curl -s ipv6.icanhazip.com)
	[ ! -z ${IP} ] && echo ${IP} || echo
}
get_char(){
	SAVEDSTTY=`stty -g`
	stty -echo
	stty cbreak
	dd if=/dev/tty bs=1 count=1 2> /dev/null
	stty -raw
	stty echo
	stty $SAVEDSTTY
}
Red_Error(){
	echo '=================================================';
	printf '\033[1;31;40m%b\033[0m\n' "$1";
	exit 1;
}
check_port(){
	unset panelPort
	until [[ ${panelPort} -ge '1' && ${panelPort} -le '65535' && ${panelPort} -ne '20' && ${panelPort} -ne '21' && ${panelPort} -ne '80' && ${panelPort} -ne '443' && ${panelPort} -ne '888' ]]
	do
		clear
		echo && read -p "请输入将安装宝塔面板的端口(默认:2020)：" panelPort
		[ -z "${panelPort}" ] && panelPort=2020
		if [[ -n "$(lsof -i:${panelPort})" ]]; then
			echo "端口${panelPort}已被占用!!!"
			read -p "是否继续将宝塔面板安装在${panelPort}端口[y/n](默认:n)：" yn
			if [[ $yn != 'y' ]]; then
				check_port
			fi
		fi
	done
}

is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ];then
	Red_Error "抱歉, 7.x不支持32位系统, 请使用64位系统或安装宝塔5.9!";
fi
isPy26=$(python -V 2>&1|grep '2.6.')
if [ "${isPy26}" ];then
	Red_Error "抱歉, 7.x不支持Centos6.x,请安装Centos7或安装宝塔5.9";
fi
Lock_Clear(){
	if [ -f "/etc/bt_crack.pl" ];then
		chattr -R -ia /www
		chattr -ia /etc/init.d/bt
		\cp -rpa /www/backup/panel/vhost/* /www/server/panel/vhost/
		mv /www/server/panel/BTPanel/__init__.bak /www/server/panel/BTPanel/__init__.py
		rm -f /etc/bt_crack.pl
	fi
}
Install_Check(){
	while [ "$yes" != 'y' ] && [ "$yes" != 'n' ]
	do
		echo -e "----------------------------------------------------"
		echo -e "已有Web环境，安装宝塔可能影响现有站点"
		echo -e "Web service is alreday installed,Can't install panel"
		echo -e "----------------------------------------------------"
		read -p "输入y强制安装/Enter y to force installation[y/n]：" yes;
	done 
	if [ "$yes" == 'n' ];then
		exit;
	fi
}
System_Check(){
	for serviceS in nginx httpd mysqld
	do
		if [ -f "/etc/init.d/${serviceS}" ]; then
			if [ "${serviceS}" == "httpd" ]; then
				serviceCheck=$(cat /etc/init.d/${serviceS}|grep /www/server/apache)
			elif [ "${serviceS}" == "mysqld" ]; then
				serviceCheck=$(cat /etc/init.d/${serviceS}|grep /www/server/mysql)
			else
				serviceCheck=$(cat /etc/init.d/${serviceS}|grep /www/server/${serviceS})
			fi
			[ -z "${serviceCheck}" ] && Install_Check
		fi
	done
}
Get_Pack_Manager(){
	if [ -f "/usr/bin/yum" ]; then
		PM="yum"
	elif [ -f "/usr/bin/apt-get" ]; then
		PM="apt-get"		
	fi
}

check_pip(){
	clear
	pip_array=($(whereis pip|awk -F 'pip: ' '{print $2}'))
	for node in ${pip_array[@]};
	do
		if [[ ! $node =~ [0-9] ]]; then
			rm -f $node
		fi
		if [[ $node =~ '2.7' ]]; then
			python_path=$node
		fi
	done
	pip_path=(/usr/bin/pip /usr/local/bin/pip)
	if [[ -n $python_path ]]; then
		for pip_dir in ${pip_path[@]};
		do
			ln -s $python_path $pip_dir
		done
		pip install --upgrade pip
	else
		py_ver='2.7.16'
		wget "https://www.python.org/ftp/python/${py_ver}/Python-${py_ver}.tgz"
		tar xvf Python-${py_ver}.tgz
		cd Python-${py_ver}
		./configure --prefix=/usr/local
		make && make install && cd /root
		rm -rf Python-${py_ver} Python-${py_ver}.tgz
		check_pip
	fi
}
Auto_Swap(){
	swap=$(free |grep Swap|awk '{print $2}')
	if [ "${swap}" -gt 1 ];then
		echo "Swap total sizse: $swap";
		return;
	fi
	if [ ! -d /www ];then
		mkdir /www
	fi
	swapFile="/www/swap"
	dd if=/dev/zero of=$swapFile bs=1M count=1025
	mkswap -f $swapFile
	swapon $swapFile
	echo "$swapFile    swap    swap    defaults    0 0" >> /etc/fstab
	swap=`free |grep Swap|awk '{print $2}'`
	if [ $swap -gt 1 ];then
		echo "Swap total sizse: $swap";
		return;
	fi
	
	sed -i "/\/www\/swap/d" /etc/fstab
	rm -f $swapFile
}
Service_Add(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
		chkconfig --add bt
		chkconfig --level 2345 bt on
	elif [ "${PM}" == "apt-get" ]; then
		update-rc.d bt defaults
	fi
}

get_node_url(){
	if [ ! -f /bin/curl ];then
		if [ "${PM}" = "yum" ]; then
			yum install curl -y
		elif [ "${PM}" = "apt-get" ]; then
			apt-get install curl -y
		fi
	fi
	
	echo '---------------------------------------------';
	echo "Selected download node...";
	nodes=(http://dg2.bt.cn http://183.235.223.101:3389 http://dg1.bt.cn http://125.88.182.172:5880 http://103.224.251.67 http://119.188.210.21:5880 http://download.bt.cn http://45.32.116.160 http://128.1.164.196);
	i=1;
	for node in ${nodes[@]};
	do
		start=`date +%s.%N`
		result=`curl -sS --connect-timeout 3 -m 60 $node/check.txt`
		if [ $result = 'True' ];then
			end=`date +%s.%N`
			start_s=`echo $start | cut -d '.' -f 1`
			start_ns=`echo $start | cut -d '.' -f 2`
			end_s=`echo $end | cut -d '.' -f 1`
			end_ns=`echo $end | cut -d '.' -f 2`
			time_micro=$(( (10#$end_s-10#$start_s)*1000000 + (10#$end_ns/1000 - 10#$start_ns/1000) ))
			time_ms=$(($time_micro/1000))
			values[$i]=$time_ms;
			urls[$time_ms]=$node
			i=$(($i+1))
			if [ $time_ms -lt 100 ];then
				break;
			fi
		fi
	done
	j=5000
	for n in ${values[@]};
	do
		if [ $j -gt $n ];then
			j=$n
		fi
		if [ $j -lt 100 ];then
			break;
		fi
	done
	if [ $j = 5000 ];then
		NODE_URL='http://download.bt.cn';
	else
		NODE_URL=${urls[$j]}
	fi
	download_Url=$NODE_URL
	btsb_Url=https://download.ccspump.com
	echo "Download node: $download_Url";
	echo '---------------------------------------------';
}
Remove_Package(){
	local PackageNmae=$1
	if [ "${PM}" == "yum" ];then
		isPackage=$(rpm -q ${PackageNmae}|grep "not installed")
		if [ -z "${isPackage}" ];then
			yum remove ${PackageNmae} -y
		fi 
	elif [ "${PM}" == "apt-get" ];then
		isPackage=$(dpkg -l|grep ${PackageNmae})
		if [ "${PackageNmae}" ];then
			apt-get remove ${PackageNmae} -y
		fi
	fi
}
Install_RPM_Pack(){
	yumPath=/etc/yum.conf
	Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
	isExc=$(cat $yumPath|grep httpd)
	if [ "$isExc" = "" ];then
		echo "exclude=httpd nginx php mysql mairadb python-psutil python2-psutil" >> $yumPath
	fi

	yumBaseUrl=$(cat /etc/yum.repos.d/CentOS-Base.repo|grep baseurl=http|cut -d '=' -f 2|cut -d '$' -f 1|head -n 1)
	[ "${yumBaseUrl}" ] && checkYumRepo=$(curl --connect-timeout 5 --head -s -o /dev/null -w %{http_code} ${yumBaseUrl})	
	if [ "${checkYumRepo}" != "200" ];then
		curl -Ss --connect-timeout 3 -m 60 http://download.bt.cn/install/yumRepo_select.sh|bash
	fi
	
	#尝试同步时间(从bt.cn)
	echo 'Synchronizing system time...'
	getBtTime=$(curl -sS --connect-timeout 3 -m 60 http://www.bt.cn/api/index/get_time)
	if [ "${getBtTime}" ];then	
		date -s "$(date -d @$getBtTime +"%Y-%m-%d %H:%M:%S")"
	fi

	if [ -z "${Centos8Check}" ]; then
		yum install ntp -y
		rm -rf /etc/localtime
		ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

		#尝试同步国际时间(从ntp服务器)
		ntpdate 0.asia.pool.ntp.org
		setenforce 0
	fi

	startTime=`date +%s`

	sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	yumPacks="wget python-devel python-imaging tar zip unzip openssl openssl-devel gcc libxml2 libxml2-devel libxslt* zlib zlib-devel libjpeg-devel libpng-devel libwebp libwebp-devel freetype freetype-devel lsof pcre pcre-devel vixie-cron crontabs icu libicu-devel c-ares"
	yum install -y ${yumPacks}

	for yumPack in ${yumPacks}
	do
		rpmPack=$(rpm -q ${yumPack})
		packCheck=$(echo ${rpmPack}|grep not)
		if [ "${packCheck}" ]; then
			yum install ${yumPack} -y
		fi
	done
	if [ -f "/usr/bin/dnf" ]; then
		dnf install -y redhat-rpm-config
	fi

	yum install epel-release -y
	
	if [ -z "${Centos8Check}" ];then
		yum install python-devel -y
	else
		yum install python3 python3-devel -y
		ln -sf /usr/bin/python3 /usr/bin/python
	fi
}
Install_Deb_Pack(){
	ln -sf bash /bin/sh
	apt-get update -y
	apt-get install ruby -y
	apt-get install lsb-release -y
	for pace in wget curl python python-dev python-imaging zip unzip openssl libssl-dev gcc libxml2 libxml2-dev libxslt zlib1g zlib1g-dev libjpeg-dev libpng-dev lsof libpcre3 libpcre3-dev cron;
	do apt-get -y install $pace --force-yes; done
	apt-get -y install python-dev

	tmp=$(python -V 2>&1|awk '{print $2}')
	pVersion=${tmp:0:3}
	if [ "${pVersion}" == '2.7' ];then
		apt-get -y install python2.7-dev
	fi

	if [ ! -d '/etc/letsencrypt' ];then
		mkdir -p /etc/letsencryp
		mkdir -p /var/spool/cron
		if [ ! -f '/var/spool/cron/crontabs/root' ];then
			echo '' > /var/spool/cron/crontabs/root
			chmod 600 /var/spool/cron/crontabs/root
		fi	
	fi
}
Install_Bt(){
	if [ -f ${setup_path}/server/panel/data/port.pl ];then
		panelPort=$(cat ${setup_path}/server/panel/data/port.pl)
	fi
	mkdir -p ${setup_path}/server/panel/logs
	mkdir -p ${setup_path}/server/panel/vhost/apache
	mkdir -p ${setup_path}/server/panel/vhost/nginx
	mkdir -p ${setup_path}/server/panel/vhost/rewrite
	mkdir -p ${setup_path}/server/panel/install
	mkdir -p /www/server
	mkdir -p /www/wwwroot
	mkdir -p /www/wwwlogs
	mkdir -p /www/backup/database
	mkdir -p /www/backup/site

	if [ ! -f "/usr/bin/unzip" ]; then
		if [ "${PM}" = "yum" ]; then
			yum install unzip -y
		elif [ "${PM}" = "apt-get" ]; then
			apt-get install unzip -y
		fi
	fi

	if [ -f "/etc/init.d/bt" ]; then
		/etc/init.d/bt stop
		sleep 1
	fi

	wget -O panel.zip ${btsb_Url}/install/src/panel6.zip -T 10
	wget -O /etc/init.d/bt ${download_Url}/install/src/bt6.init -T 10
	chattr -i /www/server/panel/install/public.sh
	chattr -i /www/server/panel/install/check.sh
	wget -O /www/server/panel/install/public.sh ${btsb_Url}/install/public.sh -T 10
	chattr +i /www/server/panel/install/public.sh

	if [ -f "${setup_path}/server/panel/data/default.db" ];then
		if [ -d "/${setup_path}/server/panel/old_data" ];then
			rm -rf ${setup_path}/server/panel/old_data
		fi
		mkdir -p ${setup_path}/server/panel/old_data
		mv -f ${setup_path}/server/panel/data/default.db ${setup_path}/server/panel/old_data/default.db
		mv -f ${setup_path}/server/panel/data/system.db ${setup_path}/server/panel/old_data/system.db
		mv -f ${setup_path}/server/panel/data/port.pl ${setup_path}/server/panel/old_data/port.pl
		mv -f ${setup_path}/server/panel/data/admin_path.pl ${setup_path}/server/panel/old_data/admin_path.pl
	fi

	unzip -o panel.zip -d ${setup_path}/server/ > /dev/null

	if [ -d "${setup_path}/server/panel/old_data" ];then
		mv -f ${setup_path}/server/panel/old_data/default.db ${setup_path}/server/panel/data/default.db
		mv -f ${setup_path}/server/panel/old_data/system.db ${setup_path}/server/panel/data/system.db
		mv -f ${setup_path}/server/panel/old_data/port.pl ${setup_path}/server/panel/data/port.pl
		mv -f ${setup_path}/server/panel/old_data/admin_path.pl ${setup_path}/server/panel/data/admin_path.pl
		if [ -d "/${setup_path}/server/panel/old_data" ];then
			rm -rf ${setup_path}/server/panel/old_data
		fi
	fi

	wget -O /www/server/panel/install/check.sh ${btsb_Url}/install/check.sh -T 10
	chattr +i /www/server/panel/install/check.sh
	rm -f panel.zip

	if [ ! -f ${setup_path}/server/panel/tools.py ];then
		Red_Error "ERROR: Failed to download, please try install again!"
	fi

	rm -f ${setup_path}/server/panel/class/*.pyc
	rm -f ${setup_path}/server/panel/*.pyc

	chmod +x /etc/init.d/bt
	chmod -R 600 ${setup_path}/server/panel
	chmod -R +x ${setup_path}/server/panel/script
	ln -sf /etc/init.d/bt /usr/bin/bt
	echo "${panelPort}" > ${setup_path}/server/panel/data/port.pl
}
Install_Pip(){
	curl -Ss --connect-timeout 3 -m 60 http://download.bt.cn/install/pip_select.sh|bash
	isPip=$(pip -V|grep python)
	if [ -z "${isPip}" ];then
		wget -O get-pip.py ${download_Url}/src/get-pip.py
		python get-pip.py
		rm -f get-pip.py
		isPip=$(pip -V|grep python)
		if [ -z "${isPip}" ];then
			if [ "${PM}" = "yum" ]; then
				if [ -z "${Centos8Check}" ];then
					yum install python-pip -y
					pip install --upgrade pip
				else
					yum install python3-pip -y
					pip3 install --upgrade pip
				fi
			elif [ "${PM}" = "apt-get" ]; then
				apt-get install python-pip -y
				pip install --upgrade pip
			fi
		fi
	fi
	pipVersion=$(pip -V|awk '{print $2}'|cut -d '.' -f 1)
	if [ "${pipVersion}" -lt "9" ];then
		pip install --upgrade pip
	fi
}
Install_Pillow(){
	isSetup=$(python -m PIL 2>&1|grep package)
	if [ "$isSetup" = "" ];then
		isFedora = `cat /etc/redhat-release |grep Fedora`
		if [ "${isFedora}" ];then
			pip install Pillow
			return;
		fi
		wget -O Pillow-3.2.0.zip $download_Url/install/src/Pillow-3.2.0.zip -T 10
		unzip Pillow-3.2.0.zip
		rm -f Pillow-3.2.0.zip
		cd Pillow-3.2.0
		python setup.py install
		cd ..
		rm -rf Pillow-3.2.0
	fi
	
	isSetup=$(python -m PIL 2>&1|grep package)
	if [ -z "${isSetup}" ];then
		Red_Error "Pillow installation failed."
	fi
}

Install_psutil(){
	isSetup=`python -m psutil 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O psutil-5.2.2.tar.gz $download_Url/install/src/psutil-5.2.2.tar.gz -T 10
		tar xvf psutil-5.2.2.tar.gz
		rm -f psutil-5.2.2.tar.gz
		cd psutil-5.2.2
		python setup.py install
		cd ..
		rm -rf psutil-5.2.2
	fi
	isSetup=$(python -m psutil 2>&1|grep package)
	if [ "${isSetup}" = "" ];then
		Red_Error "Psutil installation failed."
	fi
}
Install_chardet(){
	isSetup=$(python -m chardet 2>&1|grep package)
	if [ "${isSetup}" = "" ];then
		wget -O chardet-2.3.0.tar.gz $download_Url/install/src/chardet-2.3.0.tar.gz -T 10
		tar xvf chardet-2.3.0.tar.gz
		rm -f chardet-2.3.0.tar.gz
		cd chardet-2.3.0
		python setup.py install
		cd ..
		rm -rf chardet-2.3.0
	fi	
	
	isSetup=$(python -m chardet 2>&1|grep package)
	if [ -z "${isSetup}" ];then
		Red_Error "chardet installation failed."
	fi
}
Install_Python_Lib(){
	isPsutil=$(python -m psutil 2>&1|grep package)
	if [ "${isPsutil}" ];then
		PSUTIL_VERSION=`python -c 'import psutil;print psutil.__version__;' |grep '5.'` 
		if [ -z "${PSUTIL_VERSION}" ];then
			pip uninstall psutil -y 
		fi
	fi

	if [ "${PM}" = "yum" ]; then
		yum install libffi-devel -y
	elif [ "${PM}" = "apt-get" ]; then
		apt install libffi-dev -y
	fi

	pip install --upgrade setuptools

	TencentCloudCheck=$(cat /etc/hosts|grep -oE VM_[0-9]+_[0-9]+)
	if [ "${TencentCloudCheck}" ];then
		pip install -I requests
	fi
	
	python_gevent=$(rpm -qa|grep gevent)
	if [ "$python_gevent" != "" ];then
		yum remove python-gevent -y
		yum remove python-greenlet -y
		pip install greenlet -I
		pip install gevent -I
	fi

	pip install -r ${setup_path}/server/panel/requirements.txt
	pip install werkzeug==0.16.1
    pip install setuptools==41.2
	pip install greenlet
	pip install gevent
	pip install psutil chardet virtualenv Flask Flask-Session Flask-SocketIO flask-sqlalchemy Pillow gevent-websocket paramiko
	pip install qiniu oss2 upyun cos-python-sdk-v5
	Install_Pillow
	Install_psutil
	Install_chardet
}

Set_Bt_Panel(){
	password=$(cat /dev/urandom | head -n 16 | md5sum | head -c 8)
	sleep 1
	admin_auth="/www/server/panel/data/admin_path.pl"
	if [ ! -f ${admin_auth} ];then
		auth_path=$(cat /dev/urandom | head -n 16 | md5sum | head -c 8)
		echo "/${auth_path}" > ${admin_auth}
	fi
	auth_path=$(cat ${admin_auth})
	cd ${setup_path}/server/panel/
	/etc/init.d/bt start
	python -m py_compile tools.py
	python tools.py username
	username=$(python tools.py panel ${password})
	cd ~
	echo "${password}" > ${setup_path}/server/panel/default.pl
	chmod 600 ${setup_path}/server/panel/default.pl
	/etc/init.d/bt restart
	sleep 3
	isStart=$(ps aux |grep 'BT-Panel'|grep -v grep|awk '{print $2}')
	if [ -z "${isStart}" ];then
		Red_Error "ERROR: The BT-Panel service startup failed."
	fi
}
Set_Firewall(){
	firewall_restart(){
		if [[ ${release} == 'centos' ]]; then
			if [[ ${version} -ge '7' ]]; then
				firewall-cmd --reload
			else
				service iptables save
				if [ -e /root/test/ipv6 ]; then
					service ip6tables save
				fi
			fi
		else
			iptables-save > /etc/iptables.up.rules
			if [ -e /root/test/ipv6 ]; then
				ip6tables-save > /etc/ip6tables.up.rules
			fi
		fi
		echo -e "${Info}防火墙设置完成！"
	}
	add_firewall(){
		if [[ ${release} == 'centos' &&  ${version} -ge '7' ]]; then
			if [[ -z $(firewall-cmd --zone=public --list-ports |grep -w ${port}/tcp) ]]; then
				firewall-cmd --zone=public --add-port=${port}/tcp --add-port=${port}/udp --permanent >/dev/null 2>&1
			fi
		else
			if [[ -z $(iptables -nvL INPUT |grep :|awk -F ':' '{print $2}' |grep -w ${port}) ]]; then
				iptables -I INPUT -p tcp --dport ${port} -j ACCEPT
				iptables -I INPUT -p udp --dport ${port} -j ACCEPT
				iptables -I OUTPUT -p tcp --sport ${port} -j ACCEPT
				iptables -I OUTPUT -p udp --sport ${port} -j ACCEPT
				if [ -e /root/test/ipv6 ]; then
					ip6tables -I INPUT -p tcp --dport ${port} -j ACCEPT
					ip6tables -I INPUT -p udp --dport ${port} -j ACCEPT
					ip6tables -I OUTPUT -p tcp --sport ${port} -j ACCEPT
					ip6tables -I OUTPUT -p udp --sport ${port} -j ACCEPT
				fi
			fi
		fi
	}
	port=20 && add_firewall
	port=21 && add_firewall
	port=80 && add_firewall
	port=443 && add_firewall
	port=888 && add_firewall
	port=${panelPort} && add_firewall && firewall_restart
}
Get_Ip_Address(){
	getIpAddress=""
	getIpAddress=$(curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/getIpAddress)
	if [ -z "${getIpAddress}" ] || [ "${getIpAddress}" = "0.0.0.0" ]; then
		isHosts=$(cat /etc/hosts|grep 'www.bt.cn')
		if [ -z "${isHosts}" ];then
			echo "" >> /etc/hosts
			echo "103.224.251.67 www.bt.cn" >> /etc/hosts
			getIpAddress=$(curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/getIpAddress)
			if [ -z "${getIpAddress}" ];then
				sed -i "/bt.cn/d" /etc/hosts
			fi
		fi
	fi

	ipv4Check=$(python -c "import re; print(re.match('^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$','${getIpAddress}'))")
	if [ "${ipv4Check}" == "None" ];then
		ipv6Address=$(echo ${getIpAddress}|tr -d "[]")
		ipv6Check=$(python -c "import re; print(re.match('^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$','${ipv6Address}'))")
		if [ "${ipv6Check}" == "None" ]; then
			getIpAddress="SERVER_IP"
		else
			echo "True" > ${setup_path}/server/panel/data/ipv6.pl
			sleep 1
			/etc/init.d/bt restart
		fi
	fi

	if [ "${getIpAddress}" != "SERVER_IP" ];then
		echo "${getIpAddress}" > ${setup_path}/server/panel/data/iplist.txt
	fi
}
Setup_Count(){
	curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/SetupCount?type=Linux\&o=$1 > /dev/null 2>&1
	if [ "$1" != "" ];then
		echo $1 > /www/server/panel/data/o.pl
		cd /www/server/panel
		python tools.py o
	fi
	echo /www > /var/bt_setupPath.conf
}

Install_Main(){
	check_pip
	Lock_Clear
	System_Check
	Get_Pack_Manager
	get_node_url

	MEM_TOTAL=$(free -g|grep Mem|awk '{print $2}')
	if [ "${MEM_TOTAL}" -le "1" ];then
		Auto_Swap
	fi

	startTime=`date +%s`
	if [[ ${PM} == 'yum' ]]; then
		Install_RPM_Pack
	elif [[ ${PM} == 'apt-get' ]]; then
		Install_Deb_Pack
	fi

	Install_Bt

	Install_Pip
	Install_Python_Lib

	Set_Bt_Panel
	Service_Add
	Set_Firewall

	Get_Ip_Address
	Setup_Count ${IDC_CODE}
	clear && echo
}

check_port
echo "
+----------------------------------------------------------------------
| Bt-WebPanel 7.1.1 FOR CentOS/Ubuntu/Debian
+----------------------------------------------------------------------
| Copyright © 2015-2099 BT-SOFT(http://www.bt.cn) All rights reserved.
+----------------------------------------------------------------------
| The WebPanel URL will be http://$(get_ip):${panelPort} when installed.
+----------------------------------------------------------------------
"
while [ "$go" != 'y' ] && [ "$go" != 'n' ]
do
	read -p "Do you want to install Bt-Panel to the $setup_path directory now?[y/n](默认:y)：" go;
	[ -z $go ] && go='y'
done
if [ "$go" == 'n' ];then
	exit;
fi

Install_Main

echo -e "=================================================================="
echo -e "\033[32mCongratulations! Installed successfully!\033[0m"
echo -e "=================================================================="
echo -e "Bt-Panel: http://${getIpAddress}:${panelPort}$auth_path"
echo -e "username: $username"
echo -e "password: $password"
echo -e "\033[33mWarning:\033[0m"
echo -e "\033[33mIf you cannot access the panel, \033[0m"
echo -e "\033[33mrelease the following port (${panelPort}|888|80|443|20|21) in the security group\033[0m"
echo -e "=================================================================="

endTime=`date +%s`
((outTime=($endTime-$startTime)))
echo -e "Time consumed:\033[32m $outTime \033[0msecond!"
rm -rf bt_install.sh
echo -e "\033[32m\033[01m[信息]\033[0m按任意键继续..."
char=`get_char`
rm -f bt_install.sh
