#!/bin/bash
# Script to copy certificate and private key, and update default-ssl.conf
# Usage: sudo ./update-apache-certs.sh 

set -e

# Source certificate and key
CERT_SRC="/tmp/workingdir/cert_output/certificate.crt"
KEY_SRC="/tmp/workingdir/cert_output/certificate.key"

# Destination paths
CERT_DST="/etc/ssl/certs/challenge3.crt"
KEY_DST="/etc/ssl/private/challenge3.key"

echo "Copying certificate and key to standard locations..."

mkdir -p /etc/ssl/certs /etc/ssl/private
cp "$CERT_SRC" "$CERT_DST"
cp "$KEY_SRC" "$KEY_DST"

chmod 644 "$CERT_DST"
chmod 600 "$KEY_DST"

echo "Certificate copied to $CERT_DST"
echo "Private key copied to $KEY_DST"

# Update default-ssl.conf with the new paths
DEFAULT_SSL_CONF="/etc/apache2/sites-enabled/default-ssl.conf"

if [ ! -f "$DEFAULT_SSL_CONF" ]; then
    echo "default-ssl.conf not found at $DEFAULT_SSL_CONF."
    exit 1
fi

echo "Updating SSLCertificateFile and SSLCertificateKeyFile in $DEFAULT_SSL_CONF ..."

# Function to set or replace a directive inside VirtualHost *:443
set_vhost_param() {
    local param="$1"
    local value="$2"

    awk -v param="$param" -v value="$value" '
    BEGIN {in_vhost=0}
    {
        if ($0 ~ /<VirtualHost \*:443>/) in_vhost=1
        if ($0 ~ /<\/VirtualHost>/) in_vhost=0
        if (in_vhost && $0 ~ "^[ \t]*"param) {
            $0=param" "value
        }
        print
    }
    END {}
    ' "$DEFAULT_SSL_CONF" > "${DEFAULT_SSL_CONF}.tmp"

    mv "${DEFAULT_SSL_CONF}.tmp" "$DEFAULT_SSL_CONF"
}

set_vhost_param "SSLCertificateFile" "$CERT_DST"
set_vhost_param "SSLCertificateKeyFile" "$KEY_DST"

echo "Certificate directives updated successfully."

# Test Apache and reload
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
