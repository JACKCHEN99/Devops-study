import getopt
import sys
import os
import subprocess
# -*- coding:utf-8 -*-
class generate_yaml(object):
    def __init__(self, appname, health, port):
        self.appname = appname
        self.health = health
        self.port = port

    def write_file(self, content):
        #files = "/opt/k8s-wade/{appname}.yaml".format(appname=self.appname)
        files = "/etc/ansible/roles/k8s/files/template/{appname}.yaml".format(appname=self.appname)
        file_new = "/etc/ansible/roles/k8s/files/template-health/{appname}.yaml".format(appname=self.appname)
        with open(files, 'w') as f:
            f.write(content)
        with open(file_new, 'w') as f:
            f.write(content)
        os.chdir("/etc/ansible/roles/k8s/files/template")
        if os.path.exists("{appname}.yaml".format(appname=self.appname)):
            status=0
        else:
            status=500
        return status


    def generate_config(self):
        if "static" in self.appname:
            port_in = 80
            delaytime = 30
        else:
            port_in = 8090
            delaytime = 120
        print(len(self.port))
        s=self.port
        print(type(s))
        s=s.split(",")
        print(s)
        if len(s) == 1:
            print(4)
            print(s[0])
            RENDER_RULES_TEMPLATE = """
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    dev: {{ appname }}
    k8s: {{ appname }}
  name: {{ appname }}
  namespace: {{ namespace }}
spec:
  replicas: 1
  revisionHistoryLimit: 5
  selector:
    matchLabels:
      ihr360-service: {{ appname }}
  template:
    metadata:
      annotations:
        ihr360-service: {{ appname }}
      labels:
        ihr360-service: {{ appname }}
      namespace: {{ namespace }}
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: ihr360-service
                operator: In
                values:
                - {{ appname }}
            topologyKey: kubernetes.io/hostname
      containers:
      - env:
        - name: spring.profiles.active
          value: {{ profiles }}
        - name: ihr360.config.brand
          value: {{ brand }}
        image: {{ registry }}/{{ appname }}:{{ version }}
        imagePullPolicy: Always
        livenessProbe: &id001
          httpGet:
            path: {health}
            port: {port_in}
            scheme: HTTP
          initialDelaySeconds: {delaytime}
          periodSeconds: 30
          timeoutSeconds: 3
        name: {{ appname }}
        ports:
        - containerPort: {port_in}
          name: rellport
          protocol: TCP
        readinessProbe: *id001
      nodeSelector:
        {{ nodeselectorname }}: {{ nodeselectorvalues }}
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  labels:
    dev: {{ appname }}
    k8s: {{ appname }}
  name: {{ appname }}
  namespace: {{ namespace }}
spec:
  ports:
  - name: rellport
    nodePort: {port}
    port: {port_in}
    protocol: TCP
    targetPort: {port_in}
  selector:
    ihr360-service: {{ appname }}
  type: NodePort    
""".format(health=self.health, port_in=port_in, delaytime=delaytime, port=s[0])
            #print(RENDER_RULES_TEMPLATE)
        else:
            print(3)
#            print(self.port)
            if s[0] < s[1]:
                port1 = s[0]
                port2 = s[1]
            else:
                port1 = s[1]
                port2 = s[0]
            RENDER_RULES_TEMPLATE = """
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    dev: {{ appname }}
    k8s: {{ appname }}
  name: {{ appname }}
  namespace: {{ namespace }}
spec:
  replicas: 1
  revisionHistoryLimit: 5
  selector:
    matchLabels:
      ihr360-service: {{ appname }}
  template:
    metadata:
      annotations:
        ihr360-service: {{ appname }}
      labels:
        ihr360-service: {{ appname }}
      namespace: {{ namespace }}
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: ihr360-service
                operator: In
                values:
                - {{ appname }}
            topologyKey: kubernetes.io/hostname
      containers:
      - env:
        - name: spring.profiles.active
          value: {{ profiles }}
        - name: ihr360.config.brand
          value: {{ brand }}
        image: {{ registry }}/{{ appname }}:{{ version }}
        imagePullPolicy: Always
        livenessProbe: &id001
          httpGet:
            path: {health}
            port: {port_in}
            scheme: HTTP
          initialDelaySeconds: {delaytime}
          periodSeconds: 30
          timeoutSeconds: 3
        name: {{ appname }}
        ports:
        - containerPort: {port_in}
          name: rellport
          protocol: TCP
        - containerPort: {port2}
          name: rellport1
          protocol: TCP
        readinessProbe: *id001
      nodeSelector:
        {{ nodeselectorname }}: {{ nodeselectorvalues }}
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  labels:
    dev: {{ appname }}
    k8s: {{ appname }}
  name: {{ appname }}
  namespace: {{ namespace }}
spec:
  ports:
  - name: rellport
    nodePort: {port1}
    port: {port_in}
    protocol: TCP
    targetPort: {port_in}
  - name: rellport1
    nodePort: {port2}
    port: {port2}
    protocol: TCP
    targetPort: {port2}
  selector:
    ihr360-service: {{ appname }}
  type: NodePort    
""".format(health=self.health, port_in=port_in, delaytime=delaytime, port1=port1, port2=port2)
        s=RENDER_RULES_TEMPLATE.replace("{", "{{").replace("}", "}}")
        #print(s)
        return s

    def send_remote(self):
        os.chdir("/etc/ansible")
        os.popen("nohup ansible-playbook k8s.yml &")
        #p = subprocess.Popen("ls", shell=True, close_fds=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        #print(p.stdout.read())
    def get_result(self,status):
        if status==0:
           result={
                "retcode":0,
                "stdout":"Generated content was successful",
                "stderr":''
                }
        else:
           result={
                "retcode":status,
                "stdout":'',
                "stderr":"Generated content was fails"
                }
        return result

if __name__=='__main__':
    s = {}
    if len(sys.argv) != 7:
        print("usage: python %s -p ports -a appname -t health"%sys.argv[0])
        exit("parameter error")
    else:
        try:
            ops, args = getopt.getopt(sys.argv[1:], "hp:a:t:", ["help", "ports=", "appname=", "health="])
            for o, a in ops:
                if o in ("-h", "--help"):

                    print("usage: python %s -p ports -a appname -t health" % sys.argv[0])
                    sys.exit()
                if o in ("-p", "--ports"):
                    ports = a
                    s["ports"] = ports

                if o in ("-a", "--appname"):
                    appname = a
                    s["appname"] = appname
                if o in ("-t", "--health"):
                    health = a
                    s["health"] = health
        except getopt.GetoptError:
            print("error")
    print(s)
    port = s["ports"]
    appname = s["appname"]
    health = s["health"]
    generate = generate_yaml(appname, health, port)
    s = generate.generate_config()
    t=generate.write_file(s)
    print(t)
    print(generate.get_result(t))
