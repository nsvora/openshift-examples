#!/bin/bash

. $(dirname ${BASH_SOURCE})/../util.sh

backtotop

desc 'Run as cluster administrator'
run 'oc login -u system:admin'

backtotop

desc 'Install Istio'

run 'oc project default'
run 'oc adm policy add-scc-to-user anyuid  -z default'
run 'oc adm policy add-scc-to-user privileged -z default'
run "oc patch scc/privileged --patch '{\"allowedCapabilities\":[\"NET_ADMIN\"]}'"

backtotop

desc 'Install Istio Service Mesh'
run 'git clone https://github.com/istio/istio'
run 'cd istio'
run 'git checkout 0.1.6'


backtotop

desc 'Apply necessary permissions '

run 'oc adm policy add-cluster-role-to-user cluster-admin -z default'
run 'oc adm policy add-cluster-role-to-user cluster-admin -z istio-pilot-service-account'
run 'oc adm policy add-cluster-role-to-user cluster-admin -z istio-ingress-service-account'

run 'oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account'
run 'oc adm policy add-scc-to-user privileged -z istio-ingress-service-account'

run 'oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account'
run 'oc adm policy add-scc-to-user privileged -z istio-pilot-service-account'
run 'oc apply -f install/kubernetes/istio.yaml'

backtotop

desc 'Isntall addons'
run 'oc apply -f install/kubernetes/addons/prometheus.yaml'
run 'oc apply -f install/kubernetes/addons/grafana.yaml'
run 'oc apply -f install/kubernetes/addons/servicegraph.yaml'

backtotop

desc 'Deploy sample app'  
desc 'Install istioctl first'  
desc 'curl -L https://git.io/getIstio | sh -'  
desc 'export PATH="$PATH:/Users/jjonagam/istio/istio-0.1.6/bin"'  

backtotop
desc 'Deploy bookInfo app'  
run 'oc apply -f <(istioctl kube-inject  -f samples/apps/bookinfo/bookinfo.yaml)'  
run 'oc expose svc servicegraph'  

backtotop
desc 'Test service mesh / using grafana pod (it can be another pod)'  
run 'open http://$(oc get routes servicegraph -o jsonpath={.spec.host})/dotviz' 
run 'export GRAFANA=$(oc get pods -l app=grafana -o jsonpath={.items[0].metadata.name})'
run 'oc exec $GRAFANA -- curl -o /dev/null -s -w "%{http_code}\n" http://istio-ingress/productpage'  

backtotop
desc 'Integrating services into istio'
desc 'Lets look at apps.yaml'
run 'open https://istio.io/docs/tasks/integrating-services-into-istio.html'
run 'istioctl kube-inject -f ../apps.yaml'
run "CLIENT=$(kubectl get pod -l app=service-one -o jsonpath='{.items[0].metadata.name}')"
run "SERVER=$(kubectl get pod -l app=service-two -o jsonpath='{.items[0].metadata.name}')"
run "kubectl exec -it ${CLIENT} -c app -- curl service-two:80 | grep x-request-id"

backtotop
run "kubectl logs ${CLIENT} proxy"
run "kubectl logs ${SERVER} proxy"
run "kubectl exec -it ${SERVER} -c app -- curl localhost:8080 | grep x-request-id"
run "kubectl get deployment service-one -o yaml"





 
