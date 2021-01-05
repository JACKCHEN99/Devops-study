#! /usr/bin/env python
# -*- coding: utf-8 -*-
import requests
import json
import sys

def get_url(check_url_line):
    app_name = check_url_line[0]
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
            return app_name,status
        except:
            if retcode == 200:
                status = '1'
            else:
                status = '0'
            return app_name,status
    except:
        status = '0'
        return app_name,status
    exit()


if __name__=="__main__":
    with open('./check_list.txt', 'r', encoding='utf-8') as f:
        #dic = []
        result_all=""
        for line in f.readlines():
            line = line.strip('\n')
            b = line.split('|')
            #print(b)
            #dic.append(b)
            app_name,status = get_url(b)
            result = "{} {}\n".format(app_name,status)
            result_all += result
        print(result_all)
