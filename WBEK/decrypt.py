# Author gevivesh@microsoft.com
# Provided AS-IS no warranty use by your responsability
# code marked as “sample” or “example” 

import base64
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource.resources import ResourceManagementClient
from azure.keyvault.secrets import SecretClient
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient , KeyWrapAlgorithm

# PARAMETERS
print("---THIS SCRIPT IS FOR WRAPPED BEK VMS ---")
default_credential = DefaultAzureCredential(additionally_allowed_tenants=['*'])
KEYVAULTNAME =  input('Enter your KeyVaultName:')
SUBID = input("Enter your Subscription id:")
VMNAME = input("Enter the VM NAME:") 
FILENAME = input("Enter the Name of the file to be generated example Key.bek:") 
KEY = ""
SECRET = ""

#CODE
KVUri = "https://" + KEYVAULTNAME + ".vault.azure.net/"
client = ResourceManagementClient(credential=default_credential,subscription_id=SUBID)
keyvaultclient = SecretClient(vault_url=KVUri, credential=default_credential)
secrets = keyvaultclient.list_properties_of_secrets()
for secret in secrets:
    Name = secret.tags.get('MachineName') 
    if Name != None:
        if Name.upper()==VMNAME.upper():
            SECRET = secret.name
            URL = secret.tags.get("DiskEncryptionKeyEncryptionKeyURL")
            if URL != None:
                URL = str(URL).upper()
                KEY = URL.split('/')[URL.split('/').index('KEYS')+1]

if KEY == "" or SECRET=="":
    print("ERROR: The VM was not found on the Keyvault or is not using Wrapped BEK ")
    exit()

key_client = KeyClient(vault_url=KVUri, credential=default_credential)
retrieved_secret = keyvaultclient.get_secret(SECRET)
key = key_client.get_key(KEY)
crypto_client = CryptographyClient(key, default_credential)
sec  = retrieved_secret.value
sec += "=" * ((4 - len(sec) % 4) % 4) 
key_bytes = base64.urlsafe_b64decode(sec)
result = crypto_client.unwrap_key(KeyWrapAlgorithm.rsa_oaep, key_bytes)
key = result.key
with open(FILENAME, 'wb') as f: 
    f.write(key)
    print("File was generated")