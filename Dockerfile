# Use the official Ubuntu image as the base image
FROM ubuntu:22.04

# Set default values for build arguments
ARG GIBBON_VERSION="27.0.01"
ARG GIBBON_BASEDIR="/var/www/html"
ARG TZ="Asia/Kolkata"

# Environment variables
ENV GIBBON_VERSION=${GIBBON_VERSION}
ENV GIBBON_BASEDIR=${GIBBON_BASEDIR}
ENV TZ=${TZ}
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    mariadb-client \
    php \
    php-mysql \
    php-gd \
    php-zip \
    php-mbstring \
    php-xml \
    php-curl \
    php-intl \
    php-imagick \
    wget \
    unzip \
    curl \
    tzdata \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mods
RUN a2enmod rewrite

# Set the working directory
WORKDIR ${GIBBON_BASEDIR}

# Download and extract Gibbon
RUN wget https://github.com/GibbonEdu/core/releases/download/v${GIBBON_VERSION}/GibbonEduCore-InstallBundle.zip --no-check-certificate \
    && unzip GibbonEduCore-InstallBundle.zip \
    && rm -rf GibbonEduCore-InstallBundle.zip

# Download and extract Gibbon extensions
RUN wget https://github.com/jogiji/gibbon-extensions/releases/download/1/Extension.zip --no-check-certificate \
    && unzip Extension.zip -d ${GIBBON_BASEDIR}/modules \
    && rm Extension.zip

# Set the appropriate permissions
RUN chown -R www-data:www-data ${GIBBON_BASEDIR} \
    && find ${GIBBON_BASEDIR} -type f -exec chmod 644 {} \; \
    && find ${GIBBON_BASEDIR} -type d -exec chmod 755 {} \;

# Remove the default index.html file
RUN rm ${GIBBON_BASEDIR}/index.html

# Modify PHP configuration using sed commands
RUN sed -i 's/;max_file_uploads = .*/max_file_uploads = 30/' /etc/php/8.1/apache2/php.ini \
    && sed -i 's/;magic_quotes_gpc = .*/magic_quotes_gpc = Off/' /etc/php/8.1/apache2/php.ini \
    && sed -i 's/;register_globals = .*/register_globals = Off/' /etc/php/8.1/apache2/php.ini \
    && sed -i 's/;short_open_tag = .*/short_open_tag = On/' /etc/php/8.1/apache2/php.ini \
    && sed -i 's/;allow_url_fopen = .*/allow_url_fopen = On/' /etc/php/8.1/apache2/php.ini \
    && sed -i 's/;max_input_vars = .*/max_input_vars = 6000/' /etc/php/8.1/apache2/php.ini \
    && sed -i 's/error_reporting = .*/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT \& ~E_NOTICE/' /etc/php/8.1/apache2/php.ini

# Add Apache configuration
COPY webserver/gibbon.conf /etc/apache2/sites-available/gibbon.conf
RUN a2dissite 000-default.conf \
    && a2ensite gibbon.conf

# Expose port 80
EXPOSE 80

# Start Apache server
CMD ["apache2ctl", "-D", "FOREGROUND"]