#!/bin/bash

confd_template_folder="/etc/confd/templates/etc/rundeck/projects"
confd_configuration_folder="/etc/confd/conf.d"
project_configuration_folder="/etc/rundeck"
confd_backend=${CONFD_OPTS:-"env"}

function parse_args {
    backend_args=$1

    # remove extra spaces and make all settings have an equal between its value
    backend_args=$( echo "${backend_args}" | tr -s " " | tr " " "\n" )

    for arg in ${backend_args}; do
        if [[ $arg == "-backend="* ]]; then
            BACKEND_TYPE=$(echo $arg | awk -F "=" '{ print $2 }')
        elif [[ $arg == "-auth-token="* ]]; then
            BACKEND_TOKEN=$(echo $arg | awk -F "=" '{ print $2 }')
        elif [[ $arg == "-node="* ]]; then
            BACKEND_NODE=$(echo $arg | awk -F "=" '{ print $2 }')
            if [[ "${BACKEND_NODE}" == "http://"* ]] || [[ "${BACKEND_NODE}" == "https://"* ]]; then
                BACKEND_URL=$(echo "${BACKEND_NODE}" | awk -F "/" '{ print $3}' | awk -F ":" '{ print $1}')
                BACKEND_PORT=$(echo "${BACKEND_NODE}" | awk -F "/" '{ print $3}' | awk -F ":" '{ print $2}')
            fi 
        elif [[ $arg == "-prefix="* ]]; then
            BACKEND_PREFIX=$(echo $arg | awk -F "=" '{ print $2 }')
        fi
    done
}

parse_args "${confd_backend}"

if [[ ${BACKEND_TYPE} == "vault" ]]; then
    if [ ! -z $BACKEND_PORT ]; then 
        PORT="-p ${BACKEND_PORT}"
    else 
        PORT=""
    fi
    
    nodes=$(python ${RDECK_BASE}/scripts/get_key_from_vault.py -a ${BACKEND_TOKEN} -s /project/nodes -t ${BACKEND_URL} --prefix ${BACKEND_PREFIX} --secret-backend '' ${PORT})
else
    nodes=${PROJECT_NODES}
fi

for project in $(echo $PROJECT_NODES | jq '.= keys|.[]' | sed 's/\"//g'); do
    project_name=$(echo ${project} | sed 's/_/-/g' | tr '[:upper:]' '[:lower:]')
    # duplicate template folders (confd)
    cp -r ${confd_template_folder}/PROJECT_NAME ${confd_template_folder}/${project_name}
    cp ${confd_configuration_folder}/etc_rundeck_projects_PROJECT_NAME_etc_resources.json.toml ${confd_configuration_folder}/etc_rundeck_projects_${project_name}_etc_resources.json.toml
    # replace template_project_name with real project_name name (confd)
    find ${confd_template_folder}/${project_name} -type f -exec sed -i "s/PROJECT_NAME/${project_name}/g" {} +
    find ${confd_template_folder}/${project_name} -type f -exec sed -i "s/PROJECT_INTERNAL_NAME/${project}/g" {} +
    find ${confd_configuration_folder}/etc_rundeck_projects_${project_name}* -type f -exec sed -i "s/PROJECT_NAME/${project_name}/g" {} +
done

# remove templates
rm -rf ${confd_template_folder}/PROJECT_NAME/
rm -rf ${confd_configuration_folder}/*PROJECT_NAME*

# create final projects folders
cp -r ${confd_template_folder} ${project_configuration_folder}