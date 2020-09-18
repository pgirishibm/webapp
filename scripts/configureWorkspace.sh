#!/bin/bash
if [ "$1" = "" ] ; then
	echo "specify workspace namespace, for example:"
	kubectl get ns | awk ' { print $1 } ' | grep -e "-ws-"
	exit 1
fi
WORKSPACE=$1
NAMESPACE=`echo $WORKSPACE | sed "s/-ws-.*//g"`
if [ "$NAMESPACE" = "" ] ; then
	echo "Invalid namespace"
	exit 1
fi

if [ "`kubectl get ns $WORKSPACE 2> /dev/null | grep -v -e "^NAME "`" = "" ] ; then
	echo "Workspace namespace $WORKSPACE does not exist"
	exit 1
fi

if [ "`kubectl get ns $NAMESPACE 2> /dev/null | grep -v -e "^NAME "`" = "" ] ; then
	echo "Namespace $NAMESPACE does not exist"
	exit 1
fi
echo "Namespace: $NAMESPACE"
echo "Workspace: $WORKSPACE"

############################################################
### add namespace/workspace label
############################################################
echo "
apiVersion: v1
kind: Namespace
metadata:
  name: $WORKSPACE
  labels:
    name: $WORKSPACE
---
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
  labels:
    name: $NAMESPACE
" | kubectl apply -f -

############################################################
### copy secrets from $NAMESPACE to the $WORKSPACE namespace
############################################################
if [ "`kubectl -n "$WORKSPACE" get secrets che-tls 2>/dev/null | grep "^che-tls "`" = "" ] ; then
	echo "    Copying che-tls secret to from $NAMESPACE to $WORKSPACE"
	echo "    `kubectl -n $NAMESPACE get secrets che-tls -o yaml | grep -v -e namespace: | kubectl apply -f - -n "$WORKSPACE"`"
else
	echo "    Secret che-tls already exists in workspace $WORKSPACE"
fi

##########################
### Setup network policies
##########################
echo "
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: dns
  namespace: $WORKSPACE
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
    - to:
      - namespaceSelector:
          matchLabels:
             name: kube-system
      ports:
      - protocol: TCP
        port: 53
      - protocol: UDP
        port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: squid
  namespace: $WORKSPACE
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
    - to:
      - namespaceSelector:
          matchLabels:
             name: kube-system
      ports:
      - protocol: TCP
        port: 3128
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kubernetes
  namespace: $WORKSPACE
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
    - to:
      - namespaceSelector:
          matchLabels:
             name: $WORKSPACE
      - ipBlock:
          cidr: 172.21.0.0/16
      - ipBlock:
          cidr: 172.20.0.0/16
---
# This is needed to get the terminal to start up in the browser
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: etcd
  namespace: $WORKSPACE
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
    - to:
      - namespaceSelector:
          matchLabels:
             name: $WORKSPACE
      - ipBlock:
          cidr: 172.20.0.0/24
#      - ipBlock:
#          cidr: 0.0.0.0/0
      ports:
      - protocol: TCP
        port: 2041
" | kubectl apply -f -

##########################
### Setup role bindings
##########################
echo "
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $WORKSPACE
  namespace: $WORKSPACE
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $WORKSPACE
subjects:
- kind: ServiceAccount
  name: che-workspace
  namespace: $WORKSPACE
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $WORKSPACE
  namespace: $WORKSPACE
  labels:
    app: che
    component: che
rules:
  - verbs:
      - get
      - update
      - create
    apiGroups:
      - rbac.authorization.k8s.io
    resources:
      - rolebindings
  - verbs:
      - get
      - create
      - watch
    apiGroups:
      - ''
    resources:
      - serviceaccounts
  - verbs:
      - create
    apiGroups:
      - ''
    resources:
      - pods/exec
  - verbs:
      - list
    apiGroups:
      - ''
    resources:
      - persistentvolumeclaims
      - configmaps
  - verbs:
      - list
    apiGroups:
      - apps
    resources:
      - secrets
  - verbs:
      - list
      - create
      - delete
    apiGroups:
      - ''
    resources:
      - secrets
  - verbs:
      - create
      - get
      - watch
    apiGroups:
      - ''
    resources:
      - persistentvolumeclaims
  - verbs:
      - get
      - list
      - create
      - watch
      - delete
    apiGroups:
      - ''
    resources:
      - pods
  - verbs:
      - get
      - list
      - create
      - patch
      - watch
      - delete
    apiGroups:
      - apps
    resources:
      - deployments
  - verbs:
      - list
      - create
      - delete
    apiGroups:
      - ''
    resources:
      - services
  - verbs:
      - create
      - delete
    apiGroups:
      - ''
    resources:
      - configmaps
  - verbs:
      - watch
    apiGroups:
      - ''
    resources:
      - events
  - verbs:
      - list
      - get
      - patch
      - delete
    apiGroups:
      - apps
    resources:
      - replicasets
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - list
      - create
      - watch
      - get
      - delete
  - apiGroups:
      - ''
    resources:
      - namespaces
    verbs:
      - get
" | kubectl apply -f -
