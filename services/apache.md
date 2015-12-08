# Apache

## Discovery

- **Find out what sites are enabled on this server**: `apache2ctl -S` *should* give you a summary list, but may produce errors if config is wonky. As a fallback, navigate to /etc/apache2/sites-enabled and `ls` then `less` each file to view the URL it will be available at.
