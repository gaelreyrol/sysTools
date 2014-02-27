# !/bin/sh

if [[ "$(id -u)" != "0" ]]; then
	echo "[-] This script must be run as root"
	exit -1
fi

echo "[+] Updating dependencies..."
apt-get update > /dev/null
apt-get upgrade -y > /dev/null

echo "[+] Starting web installation script"
echo "[?] What service would you like as web engine ? :"
echo "[?] - Nginx [nginx]";echo "[?] - Apache [apache2]"
read -p "[?] You choice : " string

if [[ "$string" = "nginx" ]]; then
	echo "[+] Installing nginx..."
	apt-get install -y nginx > /dev/null
	engine="nginx"
elif [[ "$string" = "apache2" ]]; then
	echo "[+] Installing apache2..."
	apt-get install -y apache2 > /dev/null
	engine="apache2"
else
	echo "[-] Error: Unknown engine"
	exit -1
fi

echo "[+] Installing MySQL..."
if [[ "$engine" = "nginx" ]]; then
	apt-get install -y php5-mysql > /dev/null
	apt-get install -y mysql-server
elif [[ "$engine" = "apache2" ]]; then
	apt-get install -y libapache2-mod-auth-mysql php5-mysql > /dev/null
	apt-get install -y mysql-server
fi

echo "[+] Run default script after mysql install"
sudo mysql_install_db
echo "[+] Run secure script after mysql install"
sudo /usr/bin/mysql_secure_installation

echo "[+] Installing PHP..."
apt-get install -y php5
echo "[+] Select additionnal packages for php"
apt-cache search php5-
read -p "[?] Type packages : " packages
for i in $packages ; do
	echo "[+] PHP: Installing $i..."
	apt-get install -y $i > /dev/null
done

read -p "[?] Enable CloudFlare module ? : [y/n]" char
if [[ "$char" = "y" ]]; then
	if [[ "$engine" = "nginx" ]]; then
		echo "[-] Failed nginx realip module part is not supported..."
	elif [[ "$engine" = "apache2" ]]; then
		echo "[+] Installing realip module for apache2..."
		wget https://www.cloudflare.com/static/misc/mod_cloudflare/debian/mod_cloudflare-wheezy-amd64.latest.deb\
		-o /tmp/mod_cloudflare-wheezy-amd64.latest.deb
		dpkg -i mod_cloudflare-wheezy-amd64.latest.deb
	fi
fi

read -p "[?] Enable Phalcon module ? : [y/n]" char
if [[ "$char" = "y" ]]; then
	echo "[+] Installing phalcon module"
	git clone --depth=1 git://github.com/phalcon/cphalcon.git /tmp > /dev/null
	/tmp/cphalcon/build/./install > /dev/null
	if [[ "$engine" = "apache2" ]]; then
		echo "[+] Adding phalcon module to php.ini"
		echo "extension=phalcon.so" >> /etc/php5/apache2/php.ini
	fi
fi

if [[ "$engine" = "nginx" ]]; then
	echo "[+] Restarting nginx service..."
	service nginx restart
else
	echo "[+] Restarting apache2 service..."
	service apache2 restart
fi
