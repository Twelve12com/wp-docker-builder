# Colors
GREEN='\033[1;32m' # Green
RED='\033[1;31m' # Red
RESET='\033[0m' # No Color




# CHECK DOCKER WHETHER OR NOT RUNNING
rep=$(docker ps -q &>/dev/null)
status=$?


if [[ "$status" != "0" ]]; then
    
    echo 'Docker is opening...'
    open /Applications/Docker.app


    while [[ "$status" != "0" ]]; do

        echo 'Docker is starting...'
        sleep 3

        rep=$(docker ps -q &>/dev/null)
        status=$?

    done

    echo -e "${GREEN}Docker connected${RESET}"

else

	echo -e "${GREEN}Docker is running${RESET}"

fi



# FIND CURRENT OS
OS="Unknown"
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        OS="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="MacOS"
elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
		OS="cygwin"
elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
		OS="msys"
elif [[ "$OSTYPE" == "win32" ]]; then
        OS="Win32"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        OS="FreeBSD"
fi
echo "Operating System: ${OS}"






function sedreplace () {

	if [[ $OS == "MacOS" ]]; then

		sed -i "" "$1" "$2";

	else

		sed -i "$1" "$2";

	fi

}

function self_update () {

	# Builder updates
	echo "Updating the builder..."
	git pull
	git reset --hard
	git pull
	echo -e "Builder update complete ... ${GREEN}done${RESET}"

}

function server_permission_update () {

	echo "Fixing the server file permissions in ($1)..."
	docker-compose exec wp chown -R www-data:www-data $1
	# docker-compose exec wp chmod -R a=rwx $1
	docker-compose exec wp find $1 -type d ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 755 {} \;
	docker-compose exec wp find $1 -type f ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 644 {} \;
	echo -e "Server file permissions fixed ... ${GREEN}done${RESET}"

}

function permission_update () {

	echo "Fixing the file permissions in ($1)..."
	#sudo chown -R $(logname):staff $1
	find $1 ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chown $(logname):staff {} \;
	# sudo chmod -R a=rwx $1
	find $1 -type d ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 755 {} \;
	find $1 -type f ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 644 {} \;
	echo -e "File permissions fixed ... ${GREEN}done${RESET}"

}

function git_permission_update () {

	echo "Fixing the git permissions in ($1)..."
	# cd /path/to/repo.git
	sudo chmod -R g+rwX $1
	find $1 -type d -exec chmod g+s '{}' +
	echo -e "Git permissions fixed ... ${GREEN}done${RESET}"

}