# Developed by gevivesh

import math
import sys  # Import for OS File , and getting parameters
import requests
from urllib import parse
import os

def getToken(params):
    bodyJSON = {
        "workspaceToken": params["workspace"], "email": ""
    }
    token = ""
    r = requests.post(
        "https://support.microsoft.com/supportformsapi/workspace/AccessTokens", json=bodyJSON)
    if r.status_code != 200:
        print('HTTP', r.status_code)
        print('Failure to get the Token')
        exit()
    else:
        r = dict(r.json())
        token = r["accessToken"]
    return token


def allocate_file(path, token, params):
    f_name = os.path.basename(path)
    f_size = int(os.path.getsize(path))
    pathfile = "/api/v1/workspaces/" + \
        params["wid"] + "/folders/external/files?filename=" + f_name
    myheader = {
        "method": "PUT",
        "authority": "api.dtmnebula.microsoft.com",
        "scheme": "https",
        "path":  pathfile,
        "authorization": "Bearer " + token,
        "accept": "application/json, text/plain, */*",
        "overwrite": "false",
        "origin": "https://support.microsoft.com",
        "accept-encoding": "gzip, deflate, br"
    }
    chunks = math.ceil(f_size/134217728)
    body = {"chunkSize": 134217728, "contentType": "text/xml",
            "fileSize": f_size, "numberOfChunks": chunks}
    r = requests.put("https://api.dtmnebula.microsoft.com/api/v1/workspaces/" +
                     params["wid"] + "/folders/external/files/metadata?filename=" + f_name, json=body, headers=myheader)


def read_in_chunks(file_object, chunk_size=134217728):
    while True:
        data = file_object.read(chunk_size)
        if not data:
            break
        yield data


def upload(file, params):
    f_name = os.path.basename(path)
    uri = "https://api.dtmnebula.microsoft.com/api/v1/workspaces/" + \
        params["wid"] + "/folders/external/files?filename=" + f_name
    pathfile = "/api/v1/workspaces/" + \
        params["wid"] + "/folders/external/files?filename=" + f_name
    content_path = os.path.abspath(file)
    content_size = os.stat(content_path).st_size
    myheaders = {
        "method": "PATCH",
        "authority": "api.dtmnebula.microsoft.com",
        "Host": "api.dtmnebula.microsoft.com",
        "scheme": "https",
        "path":  pathfile,
        "authorization": "Bearer " + token,
        "accept": "application/json, text/plain, */*",
        "accept-encoding": "gzip, deflate, br",
        "User-Agent": "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.19041.1320",
        "Content-Length": str(content_size),
        "Expect": "100-continue"
    }
    resp = 1
    f = open(content_path, 'rb')
    i = 0
    for chunk in read_in_chunks(f):
        myheaders['chunkindex'] = str(i)
        i = +1
        try:
            r = requests.patch(uri, data=chunk, headers=myheaders)
            if r.status_code > 299:
                print("HTTP Error code", r.status_code)
                print("Data has not been uploaded properly")
                resp *= 0
            else:
                print("Uploaded Chunk", i)
                print("Success HTTP ", r.status_code)
                resp *= 1
        except Exception as e:
            print(e)
            print("Exception has ocurred data has not uploaded correctly")
            exit()
    return resp

# ---------------------
url = sys.argv[1]
path = sys.argv[2]
params = dict(parse.parse_qsl(parse.urlsplit(url).query))

token = getToken(params)
allocate_file(path, token, params)
if upload(path, params) == 1:
    print("Data has been uploaded")
else:
    print("A Error has ocurred uploading the data")