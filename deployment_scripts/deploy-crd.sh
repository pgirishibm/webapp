#!/bin/bash

ENV=$1
NAMESPACE=$2

kubectl version --short

echo "\n\n========== APPLYING THE BELOW CRD FILE in ${ENV} ENVIRONMENT=========="
cat ${ENV}/yaml/crd.yaml
echo "\n\n"
OUTPUT=`kubectl apply -f ${ENV}/yaml/crd.yaml -n ${NAMESPACE}`
if [[ "${OUTPUT}" == "checluster.org.eclipse.che/${NAMESPACE} configured" ]] || [[ "${OUTPUT}" == "checluster.org.eclipse.che/${NAMESPACE} unchanged" ]]
        then
			echo "Successfully applied the CRD yaml file"
		else
		    echo "Failed to apply the CRD yaml file"
			exit 1
fi

