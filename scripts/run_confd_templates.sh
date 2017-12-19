#!/bin/bash

#echo "### Starting configure Rundeck templated files... ###"
#rdeck_home=${RDECK_BASE:-/var/lib/rundeck}
#lock_file=${rdeck_home}/.entrypoint.lock
#while [ ! -f ${lock_file} ]; do
#    echo "  # Rundeck is being installed. Waiting till it finishes..."
#    sleep 5
#done
#/bin/confd ${CONFD_OPTS}
#echo "### Rundeck templated files configured successfully. ###"
#exit 0

#!/bin/bash

confd_template_folder="/etc/confd/templates/etc/rundeck/projects"
confd_configuration_folder="/etc/confd/conf.d"
project_configuration_folder="/etc/rundeck"

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