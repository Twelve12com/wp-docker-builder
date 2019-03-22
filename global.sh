# Colors
GREEN='\033[1;32m' # Green
RED='\033[1;31m' # Red
RESET='\033[0m' # No Color




# Get project directory
BASEDIR=$(pwd)
echo -e "BASEDIR: ${BASEDIR}"




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

function wp {
	command docker-compose run --no-deps --rm wpcli --allow-root "$@"
}


function db_backup () {

	# Save the DB backup
	echo "Backing up the DB..."
	DB_FILE=`${BASEDIR}/site/database/dump/wordpress_data.sql`
	docker-compose exec db /usr/bin/mysqldump -u root --password=password wordpress_data > ${DB_FILE}
	tail -n +2 "${DB_FILE}" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "${DB_FILE}"
	echo -e "DB Backup saved in '${DB_FILE}' ... ${GREEN}done${RESET}"

}


function search_replace {


	FIND_DOMAIN=$1
	REPLACE_DOMAIN=$2

	# Remove the protocol
	find1="https://"
	find2="http://"
	replace=""
	FIND_DOMAIN="${FIND_DOMAIN/$find1/$replace}"
	FIND_DOMAIN="${FIND_DOMAIN/$find2/$replace}"

	REPLACE_DOMAIN="${REPLACE_DOMAIN/$find1/$replace}"
	REPLACE_DOMAIN="${REPLACE_DOMAIN/$find2/$replace}"


	echo "DB replacements starting (${FIND_DOMAIN} -> ${REPLACE_DOMAIN})..."


	# Check the same values
	if [[ $FIND_DOMAIN != $REPLACE_DOMAIN ]]; then


		# Force HTTP
		echo -e "Http forcing..."
		wp search-replace "https://${FIND_DOMAIN}" "http://${FIND_DOMAIN}" --recurse-objects --report-changed-only --all-tables
		echo -e "Http force ... ${GREEN}done${RESET}"

		# Domain change
		echo -e "Domain changing..."
		wp search-replace "${FIND_DOMAIN}" "${REPLACE_DOMAIN}" --recurse-objects --report-changed-only --all-tables
		echo -e "Domain change ... ${GREEN}done${RESET}"

		# Email corrections !!! TO-DO
		#wp search-replace "@${REPLACE_DOMAIN}" "@${FIND_DOMAIN}" --recurse-objects --report-changed-only

		echo -e "DB replacements from '${FIND_DOMAIN}' to '${REPLACE_DOMAIN}' ... ${GREEN}done${RESET}"



		# Rewrite Flush
		echo -e "Flushing the rewrite rules..."
		wp rewrite flush --hard
		echo -e "Flushing the rewrite rules ... ${GREEN}done${RESET}"


	else


		echo -e "${GREEN}Values are the same. ${RESET}"


	fi


}


function db_url_update () {


	echo -e "Checking registered domain name..."
	#OLD_DOMAIN="$(wp option get siteurl)" # DAMMIT BUG!
	wp option get siteurl
	read -ep "Write the URL above: " OLD_DOMAIN
	echo "Registered domain name: ${OLD_DOMAIN}"


	# URL replacements
	if [[ $OLD_DOMAIN != "http://${DOMAIN}" ]]; then

		# Do the replacements
		search_replace "${OLD_DOMAIN}" "${DOMAIN}"

	fi


}


function wait_for_mysql () {


	# Check MySQL to be ready
	while ! docker-compose exec db mysqladmin --user=root --password=password --host "${IP}" ping --silent &> /dev/null ; do
		echo "Waiting for database connection..."
		sleep 3
	done
	echo -e "MySQL is ready! ... ${GREEN}done${RESET}"


}