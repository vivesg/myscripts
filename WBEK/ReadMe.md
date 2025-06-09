## Wrapped BEK and BEK  Cloudshell Script / How To run it 

On Cloudshell  `shell.azure.com` Select Powershell mode 

![image](https://user-images.githubusercontent.com/8367687/215172927-f3e2516d-d75e-4d29-acde-4881e5de0b58.png)



Download the Files manually or with the following commands or upload the from your cloushell session  

    wget https://raw.githubusercontent.com/vivesg/myscripts/master/WBEK/decrypt.py -O decrypt.py
    

    wget https://raw.githubusercontent.com/vivesg/myscripts/master/WBEK/requirements.txt -O requirements.txt

Run

    pip install -r requirements.txt --user
then please run

    python decrypt.py 

And provide the values that's it

![image](https://github.com/vivesg/myscripts/assets/8367687/4b7e5f0e-0657-4b77-ab4c-8444043a0b41)


Then on the same path you are going to find the file that you generated with the name,  on the previous image the file is WRAPBEK_VM_adeBEKtoKEK_drive_C_20231129_2257.bek as an example

Then you can just click on download on the Shell session and put the name of the file and you you are all set you have the file to decrypt/unlock the VM

![image](https://user-images.githubusercontent.com/8367687/215176373-9cb49d82-2438-45ef-8fe5-6ec3e4b0e847.png)


Author: German Vives
