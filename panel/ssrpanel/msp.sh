Green_font_prefix="\033[32m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
if [ -e /root/test/my ]; then
	echo -e "${Info}已允许数据库远程连接"
else
	echo -e "${Info}正在开启数据库远程连接权限..."
	docker exec -it sspanel_mysql_1 sh -c "mysql -uroot -psspanel -e\"grant all privileges on *.* to 'root'@'%' identified by 'sspanel';\""
	docker exec -it sspanel_mysql_1 sh -c "mysql -uroot -psspanel -e\"flush privileges;\""
	touch /root/test/my
fi
echo -e "${Info}请创建SS-PANEL管理员账户..."
docker exec -it sspanel sh -c "php xcat createAdmin"
docker exec -it sspanel sh -c "php xcat syncusers"
docker exec -it sspanel sh -c "php xcat initQQWry"
docker exec -it sspanel sh -c "php xcat resetTraffic"
docker exec -it sspanel sh -c "php xcat initdownload"