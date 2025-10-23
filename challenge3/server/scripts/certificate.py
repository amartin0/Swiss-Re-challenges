#!/usr/bin/env python3
"""
Retrieve a PFX certificate from Azure Key Vault using credentials
stored in local files (Service Principal credentials).
Then extract the public certificate (.crt) and private key (.key) in PEM format.
This version uses only built-in Python modules.
"""

import urllib.request
import urllib.parse
import json
import base64
import subprocess
import sys
import os

# -------------------------
# CONFIGURATION PARAMETERS
# -------------------------
SECRETS_DIR = "/tmp/workingdir/secrets-App-Registration"
KEYVAULT_NAME = "kv-lab-challenge3"
CERTIFICATE_NAME = "challenge3"
OUTPUT_DIR = "/tmp/workingdir/cert_output"

# -------------------------
# STEP 0: Read secrets from files
# -------------------------
def read_secret_file(filename):
    """Reads a secret value from a file and strips whitespace."""
    filepath = os.path.join(SECRETS_DIR, filename)
    if not os.path.isfile(filepath):
        raise FileNotFoundError(f"Missing secret file: {filepath}")
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read().strip()

try:
    TENANT_ID = read_secret_file("TENANT-ID")
    CLIENT_ID = read_secret_file("CLIENT-ID")
    CLIENT_SECRET = read_secret_file("CLIENT-SECRET")
except Exception as e:
    print(f"[ERROR] Unable to read secrets: {e}")
    sys.exit(1)

# Azure AD OAuth2 token endpoint
TOKEN_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"

# -------------------------
# STEP 1: Obtain Access Token
# -------------------------
def get_access_token():
    """Authenticate with Azure AD using Service Principal credentials."""
    data = urllib.parse.urlencode({
        "grant_type": "client_credentials",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "scope": "https://vault.azure.net/.default"
    }).encode("utf-8")

    req = urllib.request.Request(TOKEN_URL, data=data)
    with urllib.request.urlopen(req) as resp:
        token_info = json.load(resp)
        return token_info["access_token"]

# -------------------------
# STEP 2: Get Certificate Secret from Key Vault
# -------------------------
def get_certificate_pfx(access_token):
    """Retrieve a base64-encoded PFX certificate from Azure Key Vault."""
    vault_url = f"https://{KEYVAULT_NAME}.vault.azure.net/secrets/{CERTIFICATE_NAME}?api-version=7.3"
    req = urllib.request.Request(vault_url)
    req.add_header("Authorization", f"Bearer {access_token}")
    with urllib.request.urlopen(req) as resp:
        secret_info = json.load(resp)
        pfx_b64 = secret_info["value"]
        return base64.b64decode(pfx_b64)

# -------------------------
# STEP 3: Save PFX and Extract PEM
# -------------------------
def save_and_extract_pem(pfx_bytes, password=""):
    """Save PFX to disk and extract .crt and .key files using OpenSSL."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    pfx_path = os.path.join(OUTPUT_DIR, "certificate.pfx")
    crt_path = os.path.join(OUTPUT_DIR, "certificate.crt")
    key_path = os.path.join(OUTPUT_DIR, "certificate.key")

    with open(pfx_path, "wb") as f:
        f.write(pfx_bytes)
    print(f"[+] PFX saved to: {pfx_path}")

    # Extract private key
    subprocess.run([
        "openssl", "pkcs12", "-in", pfx_path, "-nocerts", "-nodes",
        "-out", key_path, "-passin", f"pass:{password}"
    ], check=True)
    print(f"[+] Private key saved to: {key_path}")

    # Extract public certificate
    subprocess.run([
        "openssl", "pkcs12", "-in", pfx_path, "-clcerts", "-nokeys",
        "-out", crt_path, "-passin", f"pass:{password}"
    ], check=True)
    print(f"[+] Public certificate saved to: {crt_path}")

# -------------------------
# MAIN EXECUTION
# -------------------------
def main():
    try:
        print(f"Connecting to Azure Key Vault: {KEYVAULT_NAME}")
        token = get_access_token()

        print(f"Retrieving certificate '{CERTIFICATE_NAME}'...")
        pfx_bytes = get_certificate_pfx(token)

        print("Extracting certificate and key...")
        save_and_extract_pem(pfx_bytes)

        print("✅ Operation completed successfully.")
    except urllib.error.HTTPError as e:
        print(f"[HTTP Error] {e.code}: {e.reason}")
        print(e.read().decode())
        sys.exit(1)
    except Exception as e:
        print(f"[Error] {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

