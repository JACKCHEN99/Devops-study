#!/bin/bash
app=''

for i in $app;do
kubectl get pods -n uatstable | grep $i;done
