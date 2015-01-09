FROM ubuntu:latest

MAINTAINER Daniel Binggeli <db@xbe.ch>

#Packages 
RUN apt-get update
RUN apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 libarchive-zip-perl libclone-perl \
  libconfig-std-perl libdatetime-perl libdbd-pg-perl libdbi-perl \
  libemail-address-perl  libemail-mime-perl libfcgi-perl libjson-perl \
  liblist-moreutils-perl libnet-smtp-ssl-perl libnet-sslglue-perl \
  libparams-validate-perl libpdf-api2-perl librose-db-object-perl \
  librose-db-perl librose-object-perl libsort-naturally-perl libpq5 \
  libstring-shellquote-perl libtemplate-perl libtext-csv-xs-perl \
  libtext-iconv-perl liburi-perl libxml-writer-perl libyaml-perl \
  libfile-copy-recursive-perl postgresql git build-essential \
  libgd-gd2-perl libimage-info-perl sed supervisor

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install language-pack-de-base

# Kivitendo Git Repo clonen
RUN git clone https://github.com/kivitendo/kivitendo-erp.git /var/www/kivitendo-erp

ADD kivitendo.conf /var/www/kivitendo-erp/config/kivitendo.conf


#Install missing Perl Modules
RUN cpan HTML::Restrict

#Check Kivitendo installation
RUN cd /var/www/kivitendo-erp/ && perl /var/www/kivitendo-erp/scripts/installation_check.pl


# ADD POSTGRES
# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.3``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 9.3
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python-software-properties software-properties-common postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3

# Note: The official Debian and Ubuntu images automatically ``apt-get clean``
# after each ``apt-get``

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.3`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN pg_dropcluster --stop 9.3 main && pg_createcluster --locale de_DE.UTF-8 --start 9.3 main
#RUN pg_createcluster --locale=de_DE.UTF-8 --encoding=de_DE.UTF-8 9.3 main
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    psql --command "CREATE USER kivitendo WITH SUPERUSER PASSWORD 'kivitendo';" &&\
    createdb -O docker docker &&\
    createdb -O kivitendo kivitendo

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible. 
RUN echo "host	all	all	0.0.0.0/0	md5" >> /etc/postgresql/9.3/main/pg_hba.conf
RUN echo "local	all	kivitendo	password" >> /etc/postgresql/9.3/main/pg_hba.conf
#RUN echo "local	all	kivitendo	127.0.0.1 255.255.255.255	password" >> /etc/postgresql/9.3/main/pg_hba.conf


# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
# RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf
	
RUN sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "/etc/postgresql/9.3/main/postgresql.conf"

# Expose the PostgreSQL port
EXPOSE 5432


# ADD APACHE
# Run the rest of the commands as the ``root`` user
USER root

RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd

# SET Servername to localhost
RUN echo "ServerName localhost" >> /etc/apache2/conf-available/servername.conf
RUN a2enconf servername

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
 
RUN chown -R www-data:www-data /var/www
RUN chmod u+rwx,g+rx,o+rx /var/www
RUN find /var/www -type d -exec chmod u+rwx,g+rx,o+rx {} +
RUN find /var/www -type f -exec chmod u+rw,g+rw,o+r {} +

#Kivitendo rights
RUN mkdir /var/www/kivitendo-erp/webdav
RUN chown -R www-data /var/www/kivitendo-erp/users /var/www/kivitendo-erp/spool /var/www/kivitendo-erp/webdav
RUN chown www-data /var/www/kivitendo-erp/templates /var/www/kivitendo-erp/users
RUN chmod -R +x /var/www/kivitendo-erp/

#Perl Modul im Apache laden
RUN a2enmod cgi.load


EXPOSE 80
 
# Update the default apache site with the config we created.
ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf
 
# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/var/log/apache2"]



# Scripts
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-apache2.sh /usr/local/bin/supervisord-apache2.sh
ADD supervisord-postgresql.conf /etc/supervisor/conf.d/supervisord-postgresql.conf
ADD supervisord-postgresql.sh /usr/local/bin/supervisord-postgresql.sh
ADD start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/*.sh


# By default, simply start apache.
CMD ["/usr/local/bin/start.sh"]



