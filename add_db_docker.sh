#!/bin/bash
usage() {
	echo "

Usage:

$0 docker db_name db_user 

docker: Nombre del contenedor de MariaDB/MySQL
db_name: Nombre de la base de datos que se va a crear
db_user: Nombre de usuario que se creara para manejar la base de datos
	"
}
if [ $# -eq 0 ]
then
	usage
	exit 0 
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
	usage
	exit 0
fi

if [ $# -ne 3 ]
then
	echo ""
	echo "Numero de argumentos incorrectos..."
	usage
	exit 1
fi

if [ "$3" = "root" ]
then
	echo "Error, Can not create a root user, choose a different user"
	exit 1
fi

dbdocker=$1
dbname=$2
dbuser=$3
dbpass="$(openssl rand -base64 12)"

docker exec -e newdb=$dbname $dbdocker sh -c 'exec mysql --user=root --password=$MARIADB_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $newdb"'

if [ $? -eq 0 ]
then
	echo "Database created successfully"
else
	echo "Something went wrong... Database not created"
	exit 1
fi

cat << EOF > user.sql
CREATE USER '${dbuser}'@'%' IDENTIFIED BY '${dbpass}';
GRANT ALL ON ${dbname}.* TO '${dbuser}'@'%';
FLUSH PRIVILEGES;
EOF
docker cp user.sql mariadb-server:/tmp

docker exec -i $dbdocker sh -c 'exec mysql --user=root --password=$MARIADB_ROOT_PASSWORD < /tmp/user.sql'
if [ $? -eq 0 ]
then
	echo "User created successfully, all permissions granted on database"
else
	echo "Something went wrong user not created"
	exit 1
fi
docker exec -i $dbdocker sh -c 'rm -f /tmp/user.sql'
echo ""
echo "DB NAME: $dbname"
echo "DB USER: $dbuser"
echo "DB PASSWD: $dbpass"
exit 0

