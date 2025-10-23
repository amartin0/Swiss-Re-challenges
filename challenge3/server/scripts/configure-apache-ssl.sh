#!/bin/bash
# Script to configure Apache SSL parameters according to Mozilla Intermediate TLS
# It updates ssl.conf and default-ssl.conf with recommended parameters.
# Usage: sudo ./configure-apache-ssl.sh 

set -e

# -------------------------
# ssl.conf configuration
# -------------------------
SSL_CONF="/etc/apache2/mods-available/ssl.conf"  # Adjust path if needed

if [ ! -f "$SSL_CONF" ]; then
    echo "ssl.conf not found at $SSL_CONF. Please verify the path."
    exit 1
fi

echo "Using SSL configuration file: $SSL_CONF"

# Backup ssl.conf
BACKUP="${SSL_CONF}.bak.$(date +%F-%H%M%S)"
cp "$SSL_CONF" "$BACKUP"
echo "Backup created at $BACKUP"

# Function to add or replace a parameter, uncommenting if necessary
# Function to set or replace a parameter safely
set_ssl_param() {
    local file="$1"
    local param="$2"
    local value="$3"

    # Delete any existing line for this parameter (commented or uncommented)
    sed -i "/^\s*#\?\s*$param\s\+/d" "$file"
    # Add the new line at the end
    echo "$param $value" >> "$file"
}



# Set SSL parameters according to Mozilla Intermediate
set_ssl_param "$SSL_CONF" "SSLProtocol" "-all +TLSv1.2 +TLSv1.3"
set_ssl_param "$SSL_CONF" "SSLOpenSSLConfCmd" "Curves X25519:prime256v1:secp384r1"
set_ssl_param "$SSL_CONF" "SSLCipherSuite" "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305"
set_ssl_param "$SSL_CONF" "SSLHonorCipherOrder" "off"
set_ssl_param "$SSL_CONF" "SSLSessionTickets" "off"

echo "SSL parameters in ssl.conf updated successfully."

# -------------------------
# default-ssl.conf VirtualHost configuration
# -------------------------
DEFAULT_SSL_CONF="/etc/apache2/sites-enabled/default-ssl.conf"

if [ ! -f "$DEFAULT_SSL_CONF" ]; then
    echo "default-ssl.conf not found at $DEFAULT_SSL_CONF. Please verify the path."
else
    echo "Updating default-ssl.conf VirtualHost *:443 directives..."

    BACKUP2="${DEFAULT_SSL_CONF}.bak.$(date +%F-%H%M%S)"
    cp "$DEFAULT_SSL_CONF" "$BACKUP2"
    echo "Backup created at $BACKUP2"

    # Ensure SSLEngine on and Protocols h2 http/1.1 inside VirtualHost *:443
    awk -v RS='' -v ORS='\n\n' '
    BEGIN {in_vhost=0}
    {
        block=$0
        if (block ~ /<VirtualHost \*:443>/) {
            in_vhost=1
            # SSLEngine
            if (block ~ /SSLEngine/) {
                gsub(/SSLEngine\s+.*/, "SSLEngine on", block)
            } else {
                block=gensub(/(<VirtualHost \*:443>)/, "\\1\n        SSLEngine on", "g", block)
            }
            # Protocols
            if (block ~ /Protocols/) {
                gsub(/Protocols\s+.*/, "Protocols h2 http/1.1", block)
            } else {
                block=gensub(/(<VirtualHost \*:443>)/, "\\1\n        Protocols h2 http/1.1", "g", block)
            }
        }
        print block
    }
    ' "$DEFAULT_SSL_CONF" > "${DEFAULT_SSL_CONF}.tmp"

    mv "${DEFAULT_SSL_CONF}.tmp" "$DEFAULT_SSL_CONF"
    echo "VirtualHost directives updated successfully."
fi

# -------------------------
# Test Apache and reload
# -------------------------
echo "Testing Apache configuration..."
apachectl configtest

echo "Reloading Apache..."
if systemctl is-active --quiet httpd; then
    systemctl reload httpd
elif systemctl is-active --quiet apache2; then
    systemctl reload apache2
else
    echo "Apache service not detected. Please reload manually."
fi

echo "Done."
