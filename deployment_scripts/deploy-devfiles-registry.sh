#!/bin/bash

ENV=$1
NAMESPACE=$2

kubectl version --short

echo "========== REPLACING THE LATEST BUILD TAG IN CRD OF ${ENV} ENVIRONMENT =========="

#fetch the currently deployed build
currentimage=`kubectl get deployment devfile-registry -o=jsonpath='{$.spec.template.spec.containers[:1].image}' -n ${NAMESPACE}`
currenttag=${currentimage#*:}

#fetch the new build to be deployed
newtag=`cat ${ENV}/image-tags/devfiles_registry_latest.txt`

#updating the crd.yaml and devfiles_registry_previous.txt
echo "Image to be deployed in devfiles registry is : us.icr.io/apihub-cr/che-devfile-registry:${newtag}"
sed -i "s/che-devfile-registry:.*'/che-devfile-registry:${newtag}'/" "${ENV}/yaml/crd.yaml"
true > ${ENV}/image-tags/devfiles_registry_previous.txt
echo ${currenttag} > ${ENV}/image-tags/devfiles_registry_previous.txt

echo "========== APPLYING THE BELOW CRD FILE =========="
#print the updated crd.yaml content before applying
cat ${ENV}/yaml/crd.yaml
echo ""

#applying the crd.yaml and reading the output of the command
OUTPUT=`kubectl apply -f ${ENV}/yaml/crd.yaml -n ${NAMESPACE}`

#if pass,checkin the crd.yaml and devfiles_registry_previous.txt changes else exit with failure
if [[ "${OUTPUT}" == "checluster.org.eclipse.che/"*" configured" ]] || [[ "${OUTPUT}" == "checluster.org.eclipse.che/"*" unchanged" ]]
        then
			git config --global user.email 'apihub@in.ibm.com'
			git config --global user.name 'apihub'
			git add --all
			git commit -m "updating devfiles tag in crd of ${ENV} environment"
			git push https://${MYUSER}:${MYTOKEN}@github.ibm.com/ibm-api-marketplace/playground-resources.git HEAD:reorg -f
		else
		    echo "Failed to deploy new build of devfiles registry"
			exit 1
fi

