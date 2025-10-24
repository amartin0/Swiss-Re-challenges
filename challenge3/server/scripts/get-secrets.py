#!/usr/bin/env python3
"""
Retrieve secrets (TENANT-ID, CLIENT-ID, CLIENT-SECRET) from Azure Key Vault
using a User-Assigned Managed Identity (UAMI), and save each secret
to a file in /tmp/workingdir/secrets-App-Registration/.

Requirements:
  pip install azure-identity azure-keyvault-secrets
"""

import os
import sys
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient

# ----------------------------
# Configuration section
# ----------------------------

# Name of your Key Vault (without https:// or .vault.azure.net)
KEYVAULT_NAME = "kv-lab-challenge"

# Client ID of your User-Assigned Managed Identity (UAMI)
UAMI_CLIENT_ID = "36dac35d-79b0-40f3-bd66-ebc6399c12aa"

# Secrets to retrieve
SECRET_NAMES = ["TENANT-ID", "CLIENT-ID", "CLIENT-SECRET"]

# Output directory
OUTPUT_DIR = "/tmp/workingdir/secrets-App-Registration"

# ----------------------------
# Script logic
# ----------------------------

def main():
    try:
        vault_url = f"https://{KEYVAULT_NAME}.vault.azure.net/"
        credential = ManagedIdentityCredential(client_id=UAMI_CLIENT_ID)
        client = SecretClient(vault_url=vault_url, credential=credential)

        print(f"Connected to Key Vault: {vault_url}")

        # Ensure output directory exists
        os.makedirs(OUTPUT_DIR, exist_ok=True)

        for name in SECRET_NAMES:
            secret = client.get_secret(name)
            value = secret.value.strip()

            output_path = os.path.join(OUTPUT_DIR, name)
            with open(output_path, "w") as f:
                f.write(value)

            print(f"Secret '{name}' saved to {output_path}")

        print("\nAll secrets retrieved and saved successfully.")

    except Exception as e:
        print(f"Error retrieving secrets: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
