#!/bin/bash

. ./commons-scripts.sh

check_openstack_host

check_error_code() {
   if [ "$1" != "0" -o ! -f "$2" ]; then
       echo "$2 image doesn't build"
       exit 1
   fi
}

register_vanilla_image() {
   # 1 - hadoop version, 2 - username, 3 - image name
   case "$1" in
           1)
             glance --os-username ci-user --os-auth-url http://$OPENSTACK_HOST:5000/v2.0/ --os-tenant-name ci --os-password nova image-create --name $3 --file $3.qcow2 --disk-format qcow2 --container-format bare --is-public=true --property '_sahara_tag_ci'='True' --property '_sahara_tag_1.2.1'='True' --property '_sahara_tag_1.1.2'='True' --property '_sahara_tag_vanilla'='True' --property '_sahara_username'="${2}"
             ;;
           2.3)
             glance --os-username ci-user --os-auth-url http://$OPENSTACK_HOST:5000/v2.0/ --os-tenant-name ci --os-password nova image-create --name $3 --file $3.qcow2 --disk-format qcow2 --container-format bare --is-public=true --property '_sahara_tag_ci'='True' --property '_sahara_tag_2.3.0'='True' --property '_sahara_tag_vanilla'='True' --property '_sahara_username'="${2}"
             ;;
           2.4)
             glance --os-username ci-user --os-auth-url http://$OPENSTACK_HOST:5000/v2.0/ --os-tenant-name ci --os-password nova image-create --name $3 --file $3.qcow2 --disk-format qcow2 --container-format bare --is-public=true --property '_sahara_tag_ci'='True' --property '_sahara_tag_2.4.1'='True' --property '_sahara_tag_vanilla'='True' --property '_sahara_username'="${2}"
             ;;
   esac
}

register_hdp_image() {
   # 1 - hadoop version, 2 - username, 3 - image name
   case "$1" in
           1)
             glance --os-username ci-user --os-auth-url http://$OPENSTACK_HOST:5000/v2.0/ --os-tenant-name ci --os-password nova image-create --name $3 --file $3.qcow2 --disk-format qcow2 --container-format bare --is-public=true --property '_sahara_tag_ci'='True' --property '_sahara_tag_1.3.2'='True' --property '_sahara_tag_hdp'='True' --property '_sahara_username'="${2}"
             ;;
           2)
             glance --os-username ci-user --os-auth-url http://$OPENSTACK_HOST:5000/v2.0/ --os-tenant-name ci --os-password nova image-create --name $3 --file $3.qcow2 --disk-format qcow2 --container-format bare --is-public=true --property '_sahara_tag_ci'='True' --property '_sahara_tag_2.0.6'='True' --property '_sahara_tag_hdp'='True' --property '_sahara_username'="${2}"
             ;;
   esac
}

register_cdh_image() {
   # 1 - username, 2 - image name
   glance --os-username ci-user --os-auth-url http://$OPENSTACK_HOST:5000/v2.0/ --os-tenant-name ci --os-password nova image-create --name $2 --file $2.qcow2 --disk-format qcow2 --container-format bare --is-public=true --property '_sahara_tag_ci'='True' --property '_sahara_tag_5'='True' --property '_sahara_tag_cdh'='True' --property '_sahara_username'="${1}"
}

delete_image() {
   glance --os-username ci-user --os-auth-url http://$OPENSTACK_HOST:5000/v2.0/ --os-tenant-name ci --os-password nova image-delete $1
}

upload_image() {
   # 1 - plugin, 2 - username, 3 - image name
   delete_image $3

   case "$1" in
           vanilla-1)
             register_vanilla_image "1" "$2" "$3"
           ;;
           vanilla-2.3)
             register_vanilla_image "2.3" "$2" "$3"
           ;;
           vanilla-2.4)
             register_vanilla_image "2.4" "$2" "$3"
           ;;
           hdp1)
             register_hdp_image "1" "$2" "$3"
           ;;
           hdp2)
             register_hdp_image "2" "$2" "$3"
           ;;
           cdh)
             register_cdh_image "$2" "$3"
           ;;
   esac
}

rename_image() {
   # 1 - source image, 2 - target image
   glance --os-username ci-user --os-auth-url http://$OPENSTACK_HOST:5000/v2.0/ --os-tenant-name ci --os-password nova image-update $1 --name $2
}

plugin="$1"
image_type=${2:-ubuntu}
HADOOP_VERSION=${3:-1}
GERRIT_CHANGE_NUMBER=$ZUUL_CHANGE
SKIP_CINDER_TEST=True
SKIP_CLUSTER_CONFIG_TEST=True
SKIP_EDP_TEST=False
SKIP_MAP_REDUCE_TEST=False
SKIP_SWIFT_TEST=True
SKIP_SCALING_TEST=True
SKIP_TRANSIENT_TEST=True
ONLY_TRANSIENT_TEST=False
VANILLA_IMAGE=$HOST-sahara-vanilla-${image_type}-${GERRIT_CHANGE_NUMBER}-hadoop_1
VANILLA_TWO_IMAGE=$HOST-sahara-vanilla-${image_type}-${GERRIT_CHANGE_NUMBER}-hadoop_2
HDP_IMAGE=$HOST-sahara-hdp-centos-${GERRIT_CHANGE_NUMBER}-hadoop_1
HDP_TWO_IMAGE=$HOST-sahara-hdp-centos-${GERRIT_CHANGE_NUMBER}-hadoop_2
SPARK_IMAGE=$HOST-sahara-spark-ubuntu-${GERRIT_CHANGE_NUMBER}
SSH_USERNAME="ubuntu"
CDH_IMAGE=$HOST-ubuntu-cdh-${GERRIT_CHANGE_NUMBER}

case $plugin in
    vanilla)
       pushd /home/jenkins
       python -m SimpleHTTPServer 8000 > /dev/null &
       popd

       if [ "${image_type}" == 'centos' ]; then
           username='cloud-user'
       else
           username=${image_type}
       fi
       SSH_USERNAME=${username}

       case $HADOOP_VERSION in
           1)
              sudo ${image_type}_vanilla_hadoop_1_image_name=${VANILLA_IMAGE} JAVA_DOWNLOAD_URL='http://127.0.0.1:8000/jdk-7u51-linux-x64.tar.gz' SIM_REPO_PATH=$WORKSPACE bash diskimage-create/diskimage-create.sh -p vanilla -i $image_type -v 1
              check_error_code $? ${VANILLA_IMAGE}.qcow2
              upload_image "vanilla-1" "${username}" ${VANILLA_IMAGE}
              PLUGIN_TYPE=vanilla1
              ;;
           2.3)
              sudo ${image_type}_vanilla_hadoop_2_3_image_name=${VANILLA_TWO_IMAGE} JAVA_DOWNLOAD_URL='http://127.0.0.1:8000/jdk-7u51-linux-x64.tar.gz' SIM_REPO_PATH=$WORKSPACE bash diskimage-create/diskimage-create.sh -p vanilla -i $image_type -v 2.3
              check_error_code $? ${VANILLA_TWO_IMAGE}.qcow2
              upload_image "vanilla-2.3" "${username}" ${VANILLA_TWO_IMAGE}
              HADOOP_VERSION=2-3
              PLUGIN_TYPE=vanilla2
              ;;
           2.4)
              sudo ${image_type}_vanilla_hadoop_2_4_image_name=${VANILLA_TWO_IMAGE} JAVA_DOWNLOAD_URL='http://127.0.0.1:8000/jdk-7u51-linux-x64.tar.gz' SIM_REPO_PATH=$WORKSPACE bash diskimage-create/diskimage-create.sh -p vanilla -i $image_type -v 2.4
              check_error_code $? ${VANILLA_TWO_IMAGE}.qcow2
              upload_image "vanilla-2.4" "${username}" ${VANILLA_TWO_IMAGE}
              HADOOP_VERSION=2-4
              PLUGIN_TYPE=vanilla2
              ;;
       esac
    ;;

    spark)
       pushd /home/jenkins
       python -m SimpleHTTPServer 8000 > /dev/null &
       popd

       image_type="ubuntu"
       sudo ${image_type}_spark_image_name=${SPARK_IMAGE} JAVA_DOWNLOAD_URL='http://127.0.0.1:8000/jdk-7u51-linux-x64.tar.gz' SIM_REPO_PATH=$WORKSPACE bash diskimage-create/diskimage-create.sh -p "spark"
       check_error_code $? ${SPARK_IMAGE}.qcow2
       PLUGIN_TYPE=$plugin
       exit 0
    ;;

    hdp1)
       image_type="centos"
       sudo ${image_type}_hdp_hadoop_1_image_name=${HDP_IMAGE} SIM_REPO_PATH=$WORKSPACE bash diskimage-create/diskimage-create.sh -p hdp -v 1
       check_error_code $? ${HDP_IMAGE}.qcow2
       SSH_USERNAME="root"
       upload_image "hdp1" "root" ${HDP_IMAGE}
       PLUGIN_TYPE=$plugin
    ;;

    hdp2)
       image_type="centos"
       sudo ${image_type}_hdp_hadoop_2_image_name=${HDP_TWO_IMAGE} SIM_REPO_PATH=$WORKSPACE bash diskimage-create/diskimage-create.sh -p hdp -v 2
       check_error_code $? ${HDP_TWO_IMAGE}.qcow2
       SSH_USERNAME="root"
       upload_image "hdp2" "root" ${HDP_TWO_IMAGE}
       HADOOP_VERSION="2"
       PLUGIN_TYPE=$plugin
    ;;

    cdh)
       image_type="ubuntu"
       sudo cloudera_ubuntu_image_name=${CDH_IMAGE} SIM_REPO_PATH=$WORKSPACE bash diskimage-create/diskimage-create.sh -p cloudera -i ubuntu
       check_error_code $? ${CDH_IMAGE}.qcow2
       upload_image "cdh" "ubuntu" ${CDH_IMAGE}
       SSH_USERNAME="ubuntu"
       HADOOP_VERSION="2"
       PLUGIN_TYPE=$plugin
    ;;
esac

# This parameter is used for cluster name, because cluster name's length exceeds limit 64 characters with $image_type.
image_os="uOS"
if [ "$image_type" == "centos" ]; then
    image_os="cOS"
fi
if [ "$image_type" == "fedora" ]; then
    image_os="fOS"
fi

cd /tmp/
TOX_LOG=/tmp/sahara/.tox/venv/log/venv-1.log

create_database

sudo rm -rf sahara
git clone https://review.openstack.org/openstack/sahara
cd sahara
sudo pip install .

enable_pypi

write_sahara_main_conf etc/sahara/sahara.conf
start_sahara etc/sahara/sahara.conf

cd /tmp/sahara

CLUSTER_NAME="$HOST-$image_os-$HADOOP_VERSION-$BUILD_NUMBER-$ZUUL_CHANGE-$ZUUL_PATCHSET"
write_tests_conf sahara/tests/integration/configs/itest.conf

run_tests

cat_logs /tmp/sahara

if [ "$FAILURE" != 0 ]; then
    exit 1
fi

if [[ "$STATUS" != 0 ]]
then
    if [ "${plugin}" == "vanilla" ]; then
        if [ "${HADOOP_VERSION}" == "1" ]; then
            delete_image $VANILLA_IMAGE
        else
            delete_image $VANILLA_TWO_IMAGE
        fi
    fi
    if [ "${plugin}" == "hdp1" ]; then
        delete_image $HDP_IMAGE
    fi
    if [ "${plugin}" == "hdp2" ]; then
        delete_image $HDP_TWO_IMAGE
    fi
    if [ "${plugin}" == "cdh" ]; then
        delete_image $CDH_IMAGE
    fi
    exit 1
fi

if [ "$ZUUL_PIPELINE" == "check" ]
then
    if [ "${plugin}" == "vanilla" ]; then
        if [ "${HADOOP_VERSION}" == "1" ]; then
            delete_image $VANILLA_IMAGE
        else
            delete_image $VANILLA_TWO_IMAGE
        fi
    fi
    if [ "${plugin}" == "hdp1" ]; then
        delete_image $HDP_IMAGE
    fi
    if [ "${plugin}" == "hdp2" ]; then
        delete_image $HDP_TWO_IMAGE
    fi
    if [ "${plugin}" == "cdh" ]; then
        delete_image $CDH_IMAGE
    fi
else
    if [ "${plugin}" == "vanilla" ]; then
        if [ "${HADOOP_VERSION}" == "1" ]; then
            delete_image ${image_type}_sahara_vanilla_hadoop_1_latest
            rename_image $VANILLA_IMAGE ${image_type}_sahara_vanilla_hadoop_1_latest
        else
            delete_image ${image_type}_sahara_vanilla_hadoop_${HADOOP_VERSION}_latest
            rename_image $VANILLA_TWO_IMAGE ${image_type}_sahara_vanilla_hadoop_${HADOOP_VERSION}_latest
        fi
    fi
    if [ "${plugin}" == "hdp1" ]; then
        delete_image centos_sahara_hdp_hadoop_1_latest
        rename_image $HDP_IMAGE centos_sahara_hdp_hadoop_1_latest
    fi
    if [ "${plugin}" == "hdp2" ]; then
        delete_image centos_sahara_hdp_hadoop_2_latest
        rename_image $HDP_TWO_IMAGE centos_sahara_hdp_hadoop_2_latest
    fi
    if [ "${plugin}" == "cdh" ]; then
        delete_image ubuntu_cdh_latest
        rename_image $CDH_IMAGE ubuntu_cdh_latest
    fi
fi
