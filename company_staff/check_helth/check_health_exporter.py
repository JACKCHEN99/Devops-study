#!/usr/bin/env python
# -*- coding:utf-8 -*-

from random import randint
from flask import Flask, Response
from prometheus_client import Gauge, generate_latest, CollectorRegistry
import requests
import json
# from gevent import monkey;monkey.patch_all()
import gevent

app = Flask(__name__)

@app.route('/metrics')
def hello():
    dict_result = dict()
    registry = CollectorRegistry()
    app_dict = {
        'http://192.168.1.229':'uatstable',
        'http://192.168.1.179':'uat',
        'http://192.168.1.181':'beta',
        'http://192.168.1.60':'mixed',
    }
    def get_url(check_url_line):
        app_name = check_url_line[0]
        url = check_url_line[1]
        service_type = check_url_line[2]

        if app_name not in dict_result:
            dict_result[app_name] = {}

        try:
            result = requests.get(url, timeout=3)
            retcode, retbody = result.status_code, result.content
            try:
                content = json.loads(retbody)
                if content.get('status', None):
                    status = content.get('status').lower()
                else:
                    status = content.get('data').get('status').lower()
                if status == 'up':
                    status = '1'
                else:
                    status = '0'

                dict_result[app_name][service_type] = status

            except:
                if retcode == 200:
                    status = '1'
                else:
                    status = '0'
                dict_result[app_name][service_type] = status

        except:
            status = '0'
            dict_result[app_name][service_type] = status

    from concurrent.futures import ThreadPoolExecutor
    threadPool = ThreadPoolExecutor(max_workers=6, thread_name_prefix="test_")
    # 读取txt文件, 并处理成任务进入多线程处理
    with open('/home/jason/文档/vscode/exporter/check_list.txt', 'r', encoding='utf-8') as f:
        tasks = []
        for line in f.readlines():
            line = line.strip('\n')
            app_name,part_url = line.split('|')
            for before_url,service_type in app_dict.items():
                url =  before_url +':'+ part_url
                future = threadPool.submit(get_url,[app_name,url,service_type])

        threadPool.shutdown(wait=True)

    for app_name,data_dict in dict_result.items():
        gauge = Gauge(app_name, 'health check status', ['env'], registry=registry)

        for service_type, status in data_dict.items():
            gauge.labels(service_type).set(status)

    return Response(generate_latest(registry), mimetype='text/plain')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)  # 服务器上启动
    # app.run(port=5000)   # 电脑本地启动
