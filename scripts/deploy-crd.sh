#!/bin/bash

ENV=$1
NAMESPACE=$2

kubectl version --short

echo "========== APPLYING THE BELOW CRD FILE in ${ENV} ENVIRONMENT=========="
cat ${ENV}/yaml/crd.yaml
echo " "
OUTPUT=`kubectl apply -f ${ENV}/yaml/crd.yaml -n ${NAMESPACE}`
echo ${OUTPUT}
if [[ "${OUTPUT}" == "checluster.org.eclipse.che/"*" configured" ]] || [[ "${OUTPUT}" == "checluster.org.eclipse.che/"*" unchanged" ]]
        then
			echo "Successfully applied the CRD yaml file"
		else
		    echo "Failed to apply the CRD yaml file"
			exit 1
fi

