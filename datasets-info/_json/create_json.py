#! /usr/bin/env python3

import os
import sys
import hashlib

def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()



HEADER="""
{
      "_comment": "generated by create_json.py",
      "name": "XXXX",
      "description": "XXXXXX",
      "website": "XXXXXX",
      "readme": "XXXXXX",
      "urls" : [ {
"""


FOOTER="""  ], 
       "type": "tsv",
       "tags": []
}
"""

if __name__ == '__main__':

   print(HEADER)

   for fname in sys.argv[1:]:
        md5sum = md5(fname)
        nbytes = os.path.getsize(fname)
        url =  "http://www.lexique.org" + os.path.abspath(fname).replace('/var/www','')
        print('        "urls": [{')
        print(f'            "url": "{url}",')
        print(f'            "bytes": {nbytes},')
        print(f'            "md5sum": "{md5sum}"')
        print('         },')

   print(FOOTER)




