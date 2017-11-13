#!/bin/bash

echo "### Starting automated Rundeck setup... ###"

rdeck_home=${RDECK_BASE:-/var/lib/rundeck}
rdeck_config=${RDECK_CONFIG:-/etc/rundeck}
rdeck_version=${RDECK_VERSION:-2.9.3}
profile=${RDECK_CONFIG}/profile
lock_file=${rdeck_home}/.entrypoint.lock
no_local_db=${NO_LOCAL_MYSQL:-true}

while [ ! -f ${profile} ]; do
    echo "Rundeck is being installed. Waiting till it finishes..."
    sleep 2
done

function update_nodes { # $1 - json contents
    confd_config="/etc/confd"
    confd_template_folder=${confd_config}"/templates/etc/rundeck/projects"
    confd_configuration_folder=${confd_config}"/conf.d"

    for project in $(echo $1 | jq '.= keys|.[]' | sed 's/\"//g'); do
        project_name=$(echo ${project} | sed 's/_/-/g' | tr '[:upper:]' '[:lower:]')
        # duplicate template folders (confd)
        cp -r ${confd_template_folder}/PROJECT_NAME ${confd_template_folder}/${project_name}
        cp ${confd_configuration_folder}/etc_rundeck_projects_PROJECT_NAME_etc_resources.json.toml ${confd_configuration_folder}/etc_rundeck_projects_${project_name}_etc_resources.json.toml
        # replace PROJECT_NAME with real project_name name (confd)
        find ${confd_template_folder}/${project_name} -type f -exec sed -i "s/PROJECT_NAME/${project_name}/g" {} +
        find ${confd_template_folder}/${project_name} -type f -exec sed -i "s/PROJECT_INTERNAL_NAME/${project}/g" {} +
        find ${confd_configuration_folder}/etc_rundeck_projects_${project_name}* -type f -exec sed -i "s/PROJECT_NAME/${project_name}/g" {}
    done

    # remove templates
    rm -rf ${confd_template_folder}/PROJECT_NAME/
    rm -rf ${confd_configuration_folder}/*PROJECT_NAME*

    # create final projects folders
    cp -r ${confd_template_folder} ${rdeck_config}
}

if [ ! -f $lock_file ]; then
    echo "  # Creating Rundeck directories..." 
    mkdir -v -p "${rdeck_config}"/ssl  "${rdeck_config}"/keys "${rdeck_home}"/jumia_scripts /tmp/rundeck
    echo "  # Rundeck directories created."

    echo "  # Setting permissions and ownership..." 
    chown -R rundeck: "${rdeck_config}" "${rdeck_home}"
    chmod -R 750 "${rdeck_config}"
    echo "  # All permissions and ownership set up."
    
    echo "  # Creating lock to avoid execution of unnecessary steps..."
    touch ${rdeck_home}/.entrypoint.lock
    echo "  # Lock created."
else 
    echo "This is an upgrade of an existing version of Rundeck..."
fi 

echo "### Rundeck setup finished! ###" 

exit 0