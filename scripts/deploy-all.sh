#!/bin/bash

ENV=$1
NAMESPACE=$2

kubectl version --short

YAMLFILES=${ENV}/yaml/*.yaml
for f in $YAMLFILES
do
  echo "Processing $f file..."
  OUTPUT=`kubectl apply -f ${ENV}/yaml/$f -n ${NAMESPACE}`
  cat ${OUTPUT}
  if [[ "${OUTPUT}" == *"configured" ]] || [[ "${OUTPUT}" == *"unchanged" ]]
        then
			echo "Successfully applied the $f file"
		else
		    echo "Failed to apply the $f file"
			exit 1
  fi
  cat $f
done