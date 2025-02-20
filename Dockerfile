FROM dreamfactorysoftware/df-base-img:ubuntu-20

# Configure Nginx
COPY dreamfactory.conf /etc/nginx/sites-available/dreamfactory.conf

# Get DreamFactory
RUN git clone https://github.com/dreamfactorysoftware/dreamfactory.git /opt/dreamfactory

WORKDIR /opt/dreamfactory

# Uncomment lines 12 & 21 if you would like to upgrade your environment while replacing the License Key value with your issued Key and adding the license files to the df-docker directory.
COPY composer.* /opt/dreamfactory/

# Install packages
RUN composer install --no-dev --ignore-platform-reqs && \
    php artisan df:env --db_connection=sqlite --df_install=Docker && \
    chown -R www-data:www-data /opt/dreamfactory && \
    rm /etc/nginx/sites-enabled/default
COPY docker-entrypoint.sh /docker-entrypoint.sh

# RUN sed -i "s,\#DF_REGISTER_CONTACT=,DF_LICENSE_KEY=YOUR_LICENSE_KEY," /opt/dreamfactory/.env

# Set proper permission to docker-entrypoint.sh script and forward error logs to docker log collector
RUN chmod +x /docker-entrypoint.sh && ln -sf /dev/stderr /var/log/nginx/error.log && rm -rf /var/lib/apt/lists/*

## added by Azure SSh
# Install OpenSSH and set the password for root to "Docker!". In this example, "apk add" is the install instruction for an Alpine Linux-based image.
RUN apt-get update
RUN apt install -y openssh-server\
     && echo "root:Docker!" | chpasswd 
# Copy the sshd_config file to the /etc/ssh/ directory
COPY sshd_config /etc/ssh/

# Copy and configure the ssh_setup file
RUN mkdir -p /tmp
COPY ssh_setup.sh /tmp
RUN chmod +x /tmp/ssh_setup.sh \
    && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null)

RUN mkdir -p /opt/startup
COPY init_container.sh /opt/startup
RUN chmod 755 /opt/startup/init_container.sh


# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV SSH_PORT 2222
ENV PORT 80
EXPOSE 80 2222

CMD ["/tmp/init_container.sh", "/docker-entrypoint.sh"]
