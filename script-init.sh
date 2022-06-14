# Create the file repository configuration:
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists:
sudo apt-get update
# Install the latest version of PostgreSQL.
# If you want a specific version, use 'postgresql-12' or similar instead of 'postgresql':

sudo apt-get -y install postgresql

sudo apt-get install sshpass

## INSTALL and ENABLE CITUS
curl https://install.citusdata.com/community/deb.sh > add-citus-repo.sh

sudo bash add-citus-repo.sh

# install the server and initialize db

sudo apt-get -y install postgresql-14-citus-10.2

# preload citus extension
sudo pg_conftool 14 main set shared_preload_libraries citus

sudo systemctl restart postgresql

sudo pg_conftool 14 main set listen_addresses '*'

# start the db server
sudo service postgresql restart

# and make it start automatically when computer does
sudo update-rc.d postgresql enable


# add the citus extension
sudo -i -u postgres psql -c "CREATE EXTENSION citus;"

mkdir -p /logs/archive
chown postgres:postgres -R /logs/



echo "postgres connection"


echo 'postgres:postgres' | sudo chpasswd

