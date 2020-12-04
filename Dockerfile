FROM ubuntu:bionic

#15.02.2015 Update to Kivitendo 3.2
#18.12.2018 Update to Kivitendo 3.5.2
#17.12.2019 Update to Kivitendo 3.5.4
#20.01.2020 Update to Kivitendo 3.5.5
#04.12.2020 Update to Kivitendo 3.6.1

# parameter 
# Change this values to your preferences
ENV postgresversion 10
ENV locale de_DE
ENV postgrespassword docker




#Packages 
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get -qq update && apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt install -y  apache2 libarchive-zip-perl libclone-perl \
  libconfig-std-perl libdatetime-perl libdbd-pg-perl libdbi-perl \
  libemail-address-perl  libemail-mime-perl libfcgi-perl libjson-perl \
  liblist-moreutils-perl libnet-smtp-ssl-perl libnet-sslglue-perl \
  libparams-validate-perl libpdf-api2-perl librose-db-object-perl \
  librose-db-perl librose-object-perl libsort-naturally-perl \
  libstring-shellquote-perl libtemplate-perl libtext-csv-xs-perl \
  libtext-iconv-perl liburi-perl libxml-writer-perl libyaml-perl \
  libimage-info-perl libgd-gd2-perl libapache2-mod-fcgid \
  libfile-copy-recursive-perl postgresql libalgorithm-checkdigits-perl \
  make gcc apache2 libapache2-mod-fcgid libarchive-zip-perl libclone-perl libconfig-std-perl libdatetime-perl \
  libcam-pdf-perl libdbd-pg-perl libdbi-perl libemail-address-perl libemail-mime-perl libfcgi-perl libjson-perl liblist-moreutils-perl \
  libnet-smtp-ssl-perl libnet-sslglue-perl libparams-validate-perl libpdf-api2-perl librose-db-object-perl \
  librose-db-perl librose-object-perl libsort-naturally-perl libstring-shellquote-perl libtemplate-perl libtext-csv-xs-perl \
  libtext-iconv-perl liburi-perl libxml-writer-perl libyaml-perl libfile-copy-recursive-perl libgd-gd2-perl \
  libimage-info-perl libalgorithm-checkdigits-perl postgresql git perl-doc libapache2-mod-php php-gd php-imap \
  php-mail php-mail-mime php-pgsql php-fpdf imagemagick fonts-freefont-ttf php-curl dialog php-enchant aspell-de \
  libcgi-pm-perl libdatetime-set-perl libfile-mimeinfo-perl liblist-utilsby-perl libpbkdf2-tiny-perl libregexp-ipv6-perl \
  libtext-unidecode-perl libdaemon-generic-perl libfile-flock-perl libfile-slurp-perl libset-crontab-perl python3 python3-serial \
  libcrypt-pbkdf2-perl git libcgi-pm-perl aqbanking-tools desktop-file-utils supervisor
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install language-pack-de-base poppler-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install sudo
RUN DEBIAN_FRONTEND=noninteractive apt install -y  build-essential
RUN DEBIAN_FRONTEND=noninteractive update-mime-database /usr/share/mime && update-desktop-database

#Install missing Perl Modules
RUN cpan Path::Tiny File:Basedir File::DesktopEntry DateTime::event::Cron DateTime::Set \
         FCGI HTML::Restrict Image::Info PBKDF2::Tiny Text::Unidecode \
         Set::Infinite Rose::Db::Object File::MimeInfo Exception::Class \
         Daemon::Generic DateTime::Event::Cron File::Flock File::Slurp \
         List::UtilsBy Regexp::IPv6


# ADD KIVITENDO
# Kivitendo intallation
RUN cd /var/www/ && git clone https://github.com/kivitendo/kivitendo-erp.git
RUN cd /var/www/ && git clone https://github.com/kivitendo/kivitendo-crm.git
RUN cd /var/www/kivitendo-erp && git checkout release-3.5.6.1 && ln -s ../kivitendo-crm/ crm
ADD kivitendo.conf /var/www/kivitendo-erp/config/kivitendo.conf
RUN ln -s ../kivitendo-crm/ crm
RUN cd /var/www/ && sed -i '$adocument.write("<script type='text/javascript' src='crm/js/ERPplugins.js'></script>")' kivitendo-erp/js/kivi.js
RUN cd /var/www/kivitendo-erp/menus/user && ln -s ../../../kivitendo-crm/menu/10-crm-menu.yaml 10-crm-menu.yaml
RUN cd /var/www/kivitendo-erp/sql/Pg-upgrade2-auth && ln -s  ../../../kivitendo-crm/update/add_crm_master_rights.sql add_crm_master_rights.sql
RUN cd /var/www/kivitendo-erp/locale/de && ln -s ../../../../kivitendo-crm/menu/t8e/menu.de crm-menu.de && ln -s ../../../../kivitendo-crm/menu/t8e/menu-admin.de crm-menu-admin.de

#Check Kivitendo installation
RUN cd /var/www/kivitendo-erp/ && perl /var/www/kivitendo-erp/scripts/installation_check.pl


# ADD POSTGRES
# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install ``software-properties-common`` and PostgreSQL
RUN DEBIAN_FRONTEND=noninteractive apt-get update &&\
    apt-get install -y software-properties-common \
    postgresql-${postgresversion} postgresql-client-${postgresversion} postgresql-contrib-${postgresversion}

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-${postgresversion}`` package when it was ``apt-get installed``
USER postgres

# Set the locale of the db cluster
RUN pg_dropcluster --stop ${postgresversion} main && pg_createcluster --locale ${locale}.UTF-8 --start ${postgresversion} main

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD '${postgrespassword}';" &&\
    psql --command "CREATE USER kivitendo WITH SUPERUSER PASSWORD '${postgrespassword}';" &&\
    createdb -O docker docker &&\
    createdb -O kivitendo kivitendo

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible. 
RUN echo "host	all	all	0.0.0.0/0	md5" >> /etc/postgresql/${postgresversion}/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/${postgresversion}/main/postgresql.conf``
RUN sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "/etc/postgresql/${postgresversion}/main/postgresql.conf"

RUN service postgresql restart

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
RUN a2enmod fcgid

EXPOSE 80
 
# Update the default apache site with the config we created.
ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf
ADD apache-config.conf /etc/apache2/sites-available/000-default.conf
 
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



