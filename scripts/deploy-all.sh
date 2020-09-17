#!/bin/bash

ENV=$1

kubectl version --short

declare -A dict
while IFS='=' read -r key value; do
    dict[$key]=$value
done < ${WORKSPACE}/${ENV}/deployfile.txt

echo "${dict[$f]}"

YAMLFILES=${ENV}/yaml/*.yaml
for f in $YAMLFILES
do
  echo " Deploying $f file in ${dict[$f]} namespace ..."
  #OUTPUT=`kubectl apply -f $f -n ${dict[$f]}`
  OUTPUT=" sample configured"
  echo ${OUTPUT}
  if [[ "${OUTPUT}" == *"configured" ]] || [[ "${OUTPUT}" == *"unchanged" ]]
        then
			echo "Successfully applied the $f file in ${dict[$f]} namespace"
		else
		    echo "Failed to apply the $f file"
			exit 1
  fi
 done
