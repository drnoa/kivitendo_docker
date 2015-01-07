#!/bin/bash

# Configuring Apache AllowOverride
ALLOW_OVERRIDE=${OVERRIDE:-false}
if [ "$ALLOW_OVERRIDE" = true ] ; then
	a2enmod rewrite
    sed -i -r 's/AllowOverride None$/AllowOverride All/' /etc/apache2/apache2.conf
fi
if [ "$ALLOW_OVERRIDE" = false ] ; then
	a2dismod rewrite
    sed -i -r 's/AllowOverride All$/AllowOverride None/' /etc/apache2/apache2.conf
fi

# Configuring PHP open_short_tag
OPEN_SHORT_TAG=${SHORT_TAG:-false}
if [ "$OPEN_SHORT_TAG" = true ] ; then
    sed -i -r 's/short_open_tag = Off$/short_open_tag = On/' /etc/php5/apache2/php.ini
    sed -i -r 's/short_open_tag = Off$/short_open_tag = On/' /etc/cli/apache2/php.ini
fi
if [ "$OPEN_SHORT_TAG" = false ] ; then
    sed -i -r 's/short_open_tag = On$/short_open_tag = Off/' /etc/php5/apache2/php.ini
    sed -i -r 's/short_open_tag = On$/short_open_tag = Off/' /etc/cli/apache2/php.ini
fi

# Configuring PHP display_errors
DISPLAY_ERRORS=${ERRORS:-false}
if [ "$DISPLAY_ERRORS" = true ] ; then
    sed -i -r 's/display_errors = Off$/display_errors = On/' /etc/php5/apache2/php.ini
    sed -i -r 's/display_errors = Off$/display_errors = On/' /etc/cli/apache2/php.ini
fi
if [ "$DISPLAY_ERRORS" = false ] ; then
    sed -i -r 's/display_errors = On$/display_errors = Off/' /etc/php5/apache2/php.ini
    sed -i -r 's/display_errors = On$/display_errors = Off/' /etc/cli/apache2/php.ini
fi
# Starting the apache2 server
source /etc/apache2/envvars
exec apache2 -D FOREGROUND