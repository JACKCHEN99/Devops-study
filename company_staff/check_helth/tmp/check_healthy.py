#! /usr/bin/env python
# -*- coding: utf-8 -*-
import requests
import json
import sys

def get_url(check_url_line):
    url = check_url_line[1]
    #print(url)
    try:
        result = requests.get(url, timeout=10)
        retcode,retbody=result.status_code,result.content
        try:
            content=json.loads(retbody)
            if content.get('status',None):
                status=content.get('status').lower()
            else:
                status=content.get('data').get('status').lower()
            if status =='up':
                status = '1'
            else:
                status ='0'
            print(status)
            # return app_name,status
        except:
            if retcode == 200:
                status = '1'
            else:
                status = '0'
            print(status)
            # return app_name,status
    except:
        status = '0'
        print(status)
        # return app_name,status
    exit()
if __name__=="__main__":
    with open('/data/health.list', 'r', encoding='utf-8') as f:
        dic = []
        app_name=sys.argv[1]
        for line in f.readlines():
            if app_name in line:
                line = line.strip('\n')
                b = line.split('|')
                #print(b)
                #dic.append(b)
                get_url(b)
