#!/bin/bash
echo "╔═══════════════════════════════════════════╗"
echo "║           � Start RRS Install �         ║"
echo "╚═══════════════════════════════════════════╝"
echo "Choose install mode...";
echo "  1. First Installation";
echo "  2. Update RRS, RRSWEB";
echo "  3. Check Version (test)";
echo "  4. exit";
while true;do
	read -p "Enter the number (1/2/3/4): " mode
	
	case "$mode" in
		1)
			echo "First Installation";
			break
			;;
		2)
			echo "Update RRS, RRSWEB";
			break
			;;
		3)
			echo "Check Version notion. Cancel Installation";
			exit 0
			;;
		4)
			echo "Cancel Installation";
			exit 0
			;;
		*)
			echo "Wrong Input";
			;;
	esac
done


echo "mode = $mode";

echo "Choose dashboard mode...";
echo "  1. normal Mode";
echo "  2. techtaka Mode";
while true;do
	read -p "Enter the number (1/2/3): " choice
	
	case "$choice" in
		1)
			echo "Install Normal Mode";
			break
			;;
		2)
			echo "Install Techtaka Mode";
			break
			;;
		*)
			echo "Wrong Input";
			;;
	esac
done

if [ "$mode" == 1 ];then
	echo "1. Apt Update and Install Curl";
	sudo apt update && sudo apt-get install -y curl
	echo "========================================================";
	
	echo "2. Install nvm(Node Version Manager)";
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
	echo "========================================================";
	
	# Load NVM into the script
	echo "3. Load nvm";
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  
	echo "========================================================";
	
	echo "4. Install NodeJS and npm(node package manager) and mplayer(sound)";
	sudo apt-get install -y nodejs npm mplayer
	echo "========================================================";
	
	echo "5. Install NodeJS latest Version";
	nvm install --lts
	echo "========================================================";
	
	echo "6. Install NPM latest Version";
	npm install -g npm@latest
	echo "========================================================";
fi

echo "7. Check NodeJS Version";
node --version 
export GIT_ASKPASS=echo
export GIT_USERNAME=yjheo4
export GIT_PASSWORD_1=zkXoH0E1qjJxcBFk8
export GIT_PASSWORD_2=IoZk6JvchutCX3407CX
export GIT_PASSWORD=ghp_+$GIT_PASSWORD_1+$GIT_PASSWORD_2
echo "========================================================";

echo "8. Install pm2(Process Manager)";
sudo npm i -g pm2
echo "========================================================";

echo "9. Clone RRS";
cd ~ && git clone --depth 1 https://$GIT_USERNAME:$GIT_PASSWORD@github.com/rainbow-mobile/web_robot_server.git
echo "========================================================";

echo "10. Set Lastest Version RRS";
cd ~/web_robot_server
git remote set-url origin https://$GIT_PASSWORD@github.com/rainbow-mobile/web_robot_server
git pull
git reset --hard origin/main
echo "========================================================";

echo "11. Install Packages for RRS";
npm install 
echo "========================================================";

echo "12. Build RRS";
npm run build
rm -rf src
echo "========================================================";

echo "13. Clone RRSWEB";
cd ~ && git clone --depth 1 https://$GIT_USERNAME:$GIT_PASSWORD@github.com/rainbow-mobile/web_robot_ui.git
echo "========================================================";

echo "14. Set Lastest Version RRSWEB";
cd web_robot_ui
git remote set-url origin https://$GIT_PASSWORD@github.com/rainbow-mobile/web_robot_ui
git pull
git reset --hard origin/main
echo "========================================================";

echo "15. Install Packages for RRS";
npm install
echo "========================================================";

echo "16. Check Mode : $mode";
echo "========================================================";

if [ "$choice" == 2 ];then
    echo "17. Check Mode -> UI_MODE='techtaka' add to env";
    echo "UI_MODE='techtaka'" > .env
    echo "ROBOT_TYPE='SRV'" >> .env
    echo "USE_DOCKING='false'" >> .env
    echo "USE_RTSP='false'" >> .env
    echo "USE_TASKMAN='false'" >> .env
    echo "USE_FULLSCREEN='true'" >> .env
    echo "SINGLE_MODE='false'" >> .env
else
    echo "17. Check Mode -> UI_MODE='normal' add to env";
    echo "UI_MODE='normal'" > .env
    echo "ROBOT_TYPE='SRV'" >> .env
    echo "USE_DOCKING='true'" >> .env
    echo "USE_RTSP='false'" >> .env
    echo "USE_TASKMAN='true'" >> .env
    echo "USE_FULLSCREEN='false'" >> .env
    echo "SINGLE_MODE='true'" >> .env
fi
echo "========================================================";

echo "18. Build RRSWEB";
npm run build
rm -rf src/ app/\(main\)/ app/\(full-page\)/ store/ pages/ layout/
echo "========================================================";

echo "mode = $mode";
if [ "$mode" == 1 ];then
	echo "19. Install mediamtx";
	cd ~
	sudo apt install -y gstreamer1.0-rtsp
	curl -L -o mediamtx.tar.gz https://github.com/bluenviron/mediamtx/releases/download/v1.11.2/mediamtx_v1.11.2_linux_amd64.tar.gz
	tar -xvzf mediamtx.tar.gz
	echo "========================================================";
		
	echo "20. Set UFW : 8180,11334,11337,3306,8554,8889";
	sudo ufw allow 8180
	sudo ufw allow 11334 
	sudo ufw allow 11337 
	sudo ufw allow 11339 
	sudo ufw allow 3306
	sudo ufw allow 8554
	sudo ufw allow 8889
	echo "========================================================";
	
	echo "21. Install mariadb";
	sudo apt install mariadb-server
	systemctl restart mariadb
	echo "========================================================";
	
echo "22. Set mariadb user";
sudo mysql <<EOF
create user if not exists 'rainbow'@'%' identified by 'rainbow';
grant all privileges on *.* to 'rainbow'@'%';
FLUSH PRIVILEGES;
CREATE DATABASE if not exists rainbow_rrs default CHARACTER SET UTF8;
EOF
echo "========================================================";

echo "23. Make browser.sh";
cd ~
cat <<EOF > browser.sh
#!/bin/bash
export DISPLAY=:0
if ! pgrep -x "firefox" > /dev/null
then
  firefox --kiosk "http://localhost:8180"
else
  echo "Firefox is already running"
fi
EOF
	chmod +x browser.sh
	echo "========================================================";
	
	echo "24. nmcli permissions";
	# sudoers 파일 경로 (기본 경로 사용)
	SUDOERS_FILE="/etc/sudoers"
	
	# 추가하려는 줄
	LINE_TO_ADD="rainbow ALL=(ALL) NOPASSWD: /usr/bin/nmcli"
	
	# 해당 줄이 이미 sudoers 파일에 존재하는지 확인
	if ! grep -qF "$LINE_TO_ADD" "$SUDOERS_FILE"; then
	    # sudoers 파일의 마지막에 추가
	    echo "$LINE_TO_ADD" | sudo tee -a $SUDOERS_FILE > /dev/null
	
	    # sudoers 파일에 문법 오류가 없는지 확인
	    sudo visudo -c
	    if [ $? -eq 0 ]; then
	        echo "sudoers 파일이 성공적으로 업데이트되었습니다."
	    else
	        echo "sudoers 파일에 오류가 있습니다. 변경을 롤백합니다."
	        # 오류가 있으면 변경사항 되돌리기
	        sudo sed -i '$d' $SUDOERS_FILE
	    fi
	else
	    echo "이미 해당 라인이 존재합니다. 추가하지 않았습니다."
	fi
	echo "========================================================";
else
	echo "mode false = $mode";
fi


echo "Need PM2 Setting?";
echo "  1. yes";
echo "  2. yes (with browser)";
echo "  3. no";
while true;do
	read -p "Enter the number (1/2/3): " pm2_need
	
	case "$pm2_need" in
		1)
			echo "25. Program Manager";
			pm2 delete all
			pm2 start npm --name server --cwd ~/web_robot_server -- run start:prod --kill-timeout 3000
			pm2 start npm --name webui --cwd ~/web_robot_ui -- run start
			pm2 start ~/slamnav2/SLAMNAV2 --cwd ~/slamnav2 --kill-timeout 3000
			pm2 start ~/mediamtx
			pm2 save
			startup_command=$(pm2 startup | grep 'sudo' | tail -n 1)
			eval $startup_command
			break
			;;
		2)
			echo "25. Program Manager";
			pm2 delete all
			pm2 start npm --name server --cwd ~/web_robot_server -- run start:prod --kill-timeout 3000
			pm2 start npm --name webui --cwd ~/web_robot_ui -- run start
			pm2 start ~/slamnav2/SLAMNAV2 --cwd ~/slamnav2 --kill-timeout 3000
			pm2 start --name browser browser.sh --restart-delay 20000
			pm2 start ~/mediamtx
			pm2 save
			startup_command=$(pm2 startup | grep 'sudo' | tail -n 1)
			eval $startup_command
			break
			;;
		3)
			break
			;;
		*)
			echo "Wrong Input";
			;;
	esac
done


echo "========================================================";
echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║              Done RRS Install             ║"
echo "║             Need to check Error           ║"
echo "╚═══════════════════════════════════════════╝"

