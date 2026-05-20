# Author gevivesh@microsoft.com
# Provided AS-IS no warranty use by your responsability
# code marked as “sample” or “example” 
# Educational Purposes

import base64
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource.resources import ResourceManagementClient
from azure.keyvault.secrets import SecretClient
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient , KeyWrapAlgorithm

# PARAMETERS
print("---THIS SCRIPT IS FOR WRAPPED BEK and BEK VMS ---")
default_credential = DefaultAzureCredential(additionally_allowed_tenants=['*'])
KEYVAULTNAME =  input('Enter your KeyVaultName:')
SUBID = input("Enter your Subscription id:")
LOOKUP_BY = input("Lookup by (1) VM Name or (2) Secret Name? Enter 1 or 2: ").strip()
if LOOKUP_BY == "2":
    SECRETNAME = input("Enter the Secret Name:")
    VMNAME = ""
else:
    VMNAME = input("Enter the VM NAME:")
    SECRETNAME = ""
KEY = ""
SECRET = ""
FILENAME = ".bek"

#REMOVE UNWANTES SPACES
KEYVAULTNAME = KEYVAULTNAME.replace(" ", "")
SUBID = SUBID.replace(" ", "")
VMNAME = VMNAME.replace(" ", "")
SECRETNAME = SECRETNAME.replace(" ", "")

# Determine the cloud environment and set the Key Vault URI accordingly
cloud_environment = input("Enter the cloud environment (Public, Fairfax, Mooncake): ").strip().lower()
if cloud_environment == "fairfax":
    KVUri = "https://" + KEYVAULTNAME + ".vault.usgovcloudapi.net/"
elif cloud_environment == "mooncake":
    KVUri = "https://" + KEYVAULTNAME + ".vault.azure.cn/"
else:
    KVUri = "https://" + KEYVAULTNAME + ".vault.azure.net/"

client = ResourceManagementClient(credential=default_credential, subscription_id=SUBID)
if cloud_environment == "fairfax" or cloud_environment == "mooncake":
    keyvaultclient = SecretClient(vault_url=KVUri, credential=default_credential, verify_challenge_resource=False)
else:
    keyvaultclient = SecretClient(vault_url=KVUri, credential=default_credential)

#CODE
secrets = keyvaultclient.list_properties_of_secrets()
for secret in secrets:
    if secret.tags != None:
        Name = secret.tags.get('MachineName')
    else:
        Name = None
    if LOOKUP_BY == "2":
        match = secret.name.lower() == SECRETNAME.lower()
        if match:
            VMNAME = Name if Name else SECRETNAME
    else:
        match = Name is not None and Name.upper() == VMNAME.upper()
    if match:
        SECRET = secret.name
        VolumeLetter = secret.tags.get("VolumeLetter")
        URL = secret.tags.get("DiskEncryptionKeyEncryptionKeyURL")
        if URL is not None:
            URL = str(URL).upper()
            KEY = URL.split('/')[URL.split('/').index('KEYS')+1]
            key_client = KeyClient(vault_url=KVUri, credential=default_credential)
            retrieved_secret = keyvaultclient.get_secret(SECRET)
            key = key_client.get_key(KEY)
            CreatedTime = secret.created_on
            time = CreatedTime.strftime("%Y%m%d_%H%M")
            crypto_client = CryptographyClient(key, default_credential)
            sec  = retrieved_secret.value
            sec += "=" * ((4 - len(sec) % 4) % 4)
            key_bytes = base64.urlsafe_b64decode(sec)
            result = crypto_client.unwrap_key(KeyWrapAlgorithm.rsa_oaep, key_bytes)
            key = result.key
            with open("WRAPBEK_VM_" + VMNAME + "_drive_" + VolumeLetter[0] + "_" + time  + FILENAME , 'wb') as f:
                f.write(key)
            print("===============================================")
            print("WRAP BEK File Key generated name: " +  "WRAPBEK_VM_" + VMNAME + "_drive_" + VolumeLetter[0] + "_" + time  + FILENAME  )
            print("VM: " + VMNAME )
            print("Volume Letter:  " + VolumeLetter)
            print("WRAP BEK Created on: " + time)
            print("===============================================")
        else:
            VolumeLetter = secret.tags.get("VolumeLetter")
            CreatedTime = secret.created_on
            time = CreatedTime.strftime("%Y%m%d_%H%M")
            SecretName = secret.name
            retrieved_secret = keyvaultclient.get_secret(SecretName)
            sec  = retrieved_secret.value
            bytes = sec.encode()
            rawbytes = base64.b64decode(bytes)
            with open("BEK_VM_" + VMNAME + "_drive_" + VolumeLetter[0] + "_" + time + FILENAME , 'wb') as fw:
                fw.write(rawbytes)
            print("===============================================")
            print("BEK File Key generated name:  " +  "BEK_VM_" + VMNAME + "_drive_" + VolumeLetter[0] + "_" + time  + FILENAME )
            print("VM: " + VMNAME )
            print("Volume Letter: " + VolumeLetter)
            print("BEK Created on: "  + time)
            print("===============================================")

if KEY == "" and SECRET=="":
    if LOOKUP_BY == "2":
        print("ERROR: The Secret '" + SECRETNAME + "' was not found on the Keyvault or is not using Wrapped BEK or BEK")
    else:
        print("ERROR: The VM was not found on the Keyvault or is not using Wrapped BEK or BEK")
    exit()
