# Author gevivesh@microsoft.com
import base64
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource.resources import ResourceManagementClient
from azure.keyvault.secrets import SecretClient
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient , KeyWrapAlgorithm
default_credential = DefaultAzureCredential()

KEYVAULTNAME =  input('Enter your KeyVaultName:')
SUBID = input("Enter your Subscription id:")
SECRET = input("Enter the Secret Name:") 
KEY = input("Enter the Key Name:") 
FILENAME = input("Enter the Name of the file:") 

# ---------------- #
KVUri = "https://" + KEYVAULTNAME + ".vault.azure.net/"
client = ResourceManagementClient(credential=default_credential,subscription_id=SUBID)
keyvaultclient = SecretClient(vault_url=KVUri, credential=default_credential)
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