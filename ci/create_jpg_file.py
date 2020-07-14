import requests
import base64
#from PIL import Image
from io import BytesIO
import sys
import re

def get_as_base64(url):
    return base64.b64encode(requests.get(url).content)

def create_base64_file_from_url(url, filename="this_jpg",header="image/jpeg"):
    content = str(requests.get(url).content)
    idx = re.search('thumbnailUrl.*?jpg', str(content))
    content = content[idx.start():idx.end()]
    idx = re.search('http.*?jpg', str(content))
    imgurl = content[idx.start():idx.end()]
    imgb64 = get_as_base64(imgurl)
    f = open(filename,'w')
    f.write('"image/jpeg": "{}",\n'.format(str(imgb64)))
    f.close()


if __name__ == "__main__":

    #url = sys.argv[1]  
    url = 'https://www.bilibili.com/video/BV1Hp4y1S7Au'  
    print(url)
    create_base64_file_from_url(url)