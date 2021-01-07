#!/usr/bin/env python
# -*- coding:utf-8 -*-

from random import randint
from flask import Flask, Response
from prometheus_client import Gauge, generate_latest, CollectorRegistry

app = Flask(__name__)

registry = CollectorRegistry()
gauge = Gauge('my_gauge', 'an example showed how to use gauge', ['machine_ip'], registry=registry)


@app.route('/metrics')
def hello():
    gauge.labels('127.0.0.1').set(2)
    return Response(generate_latest(registry), mimetype='text/plain')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
