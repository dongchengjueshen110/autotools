#!/bin/bash
## -------------------------------------------------------------------------
export PATH=/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:$PATH
export TERM="xterm-256color"
export WORKDIR="$( cd $(dirname "$0") &&  pwd )"
cd "${WORKDIR}" || exit 1
## -------------------------------------------------------------------------
info() {
    date +"$( tput bold ; tput setaf 2)%F %T Info: $@$( tput sgr0)"
}

warn() {
    date +"$( tput bold ; tput setaf 3)%F %T Warning: $@$( tput sgr0)"
}

error() {
    date +"$( tput bold ; tput setaf 1)%F %T Error: $@$( tput sgr0)"
}

err_exit() {
    date +"$( tput bold ; tput setaf 1)%F %T Error: $@$( tput sgr0)"
    exit 1
}
## -------------------------------------------------------------------------
help_msg() {
     echo -e "Usage:"
     echo -e "    $( basename $0 ) build single    Build and start the Confluence service."
     echo -e "    $( basename $0 ) start single    Start the Confluence service."
     echo -e "    $( basename $0 ) stop  single    Stop the Confluence service."
     echo -e "    $( basename $0 ) check single    Check the Confluence service."
}
## -------------------------------------------------------------------------
check_dc() {
    if ! docker ps >/dev/null 2>&1;then
        err_exit "No docker command found."
    fi
    if ! which docker-compose >/dev/null 2>&1;then
        err_exit "No docker-compose command found."
    fi
}
## -------------------------------------------------------------------------
get_evn() {
    if [ "$1" = "single" ];then
        CONFIG="${WORKDIR}/env.conf"
        if [[ ! -f ${CONFIG} ]] ; then
            err_exit "$( basename ${CONFIG} ) is not found!"
        else
            . "${CONFIG}"
        fi
        var_arrs=(BASE_DIR DATA_DIR MYSQL_PORT MYSQL_ROOT_PASSWORD MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD CONFLUENCE_HOST_PORT CONFLUENCE_MIN_MEM CONFLUENCE_MAX_MEM)
    fi
    for var in ${var_arrs[@]}
    do
        var2=`eval echo '$'"$var"`
        if [[ -z "${var2}" ]] ; then
            err_exit "${var} is empty!"
        fi
    done
}
## -------------------------------------------------------------------------
generate(){
    local _role="$1"
    local compose_tpl_file="${WORKDIR}/templates/docker-compose-${_role}-tpl.yml"
    local compose_file="${WORKDIR}/docker-compose-${_role}.yml"
    if [ ! -f "${compose_tpl_file}" ];then
        err_exit "The ${compose_tpl_file} template file does not exist."
    fi
    get_evn "${_role}"
    eval "cat <<EOF
$(<${compose_tpl_file})
EOF" > ${compose_file}
    mkdir -p "${DATA_DIR}"/mysql/{data,logs} && chown -R 999.999 "${DATA_DIR}"/mysql
    mkdir -p "${DATA_DIR}"/confluence-data && chown -R 2002.2002 "${DATA_DIR}"/confluence-data

    local setenv_tpl_sh="${WORKDIR}/templates/setenv-tpl.sh"
    local setenv_sh="${WORKDIR}/bin/setenv.sh"
    if [ ! -f "${setenv_tpl_sh}" ];then
        err_exit "The ${setenv_tpl_file} template file does not exist."
    fi
    if sed -e "s#_CONFLUENCE_MIN_MEM_#${CONFLUENCE_MIN_MEM}#g" \
           -e "s#_CONFLUENCE_MAX_MEM_#${CONFLUENCE_MAX_MEM}#g" \
          "${setenv_tpl_sh}" > "${setenv_sh}";then
          chmod +x "${setenv_sh}"
          info "setenv.sh generage success."   
    else
          err_exit "setenv.sh generage fail."
    fi
}
## -------------------------------------------------------------------------
build() {
    check_dc
    get_evn
    local _role="$1"
    local compose_file="${WORKDIR}/docker-compose-${_role}.yml"
    local mysql_image_count=`docker image ls mysql:5.7.33 | grep -v REPOSITORY | wc -l`
    if [ ${mysql_image_count} -eq 0 ];then
        if [ -f ${WORKDIR}/images/mysql-5.7.33.tar.gz ];then
            docker load -i ${WORKDIR}/images/mysql-5.7.33.tar.gz
        else
            info "It will take a long time, please be patient."
            docker pull mysql:5.7.33 
        fi
    fi
    local conflunce_image_count=`docker image ls atlassian/confluence-server:6.15.7-alpine | grep -v REPOSITORY | wc -l`
    if [ ${conflunce_image_count} -eq 0 ];then
        if [ -f ${WORKDIR}/images/confluence-server-6.15.7.tar.gz ];then
            docker load -i ${WORKDIR}/images/confluence-server-6.15.7.tar.gz
        else
            info "It will take a long time, please be patient."
            docker pull atlassian/confluence-server:6.15.7-alpine
        fi
    fi
    if ! docker network inspect default_bridge >/dev/null 2>&1;then
        docker network create --driver bridge --subnet 172.29.96.0/20 default_bridge
    fi
    generate "${_role}"
    if [ ! -f "${compose_file}" ];then
        err_exit "docker-compose:${compose_file}不存在."
    fi
    docker-compose -f "${compose_file}" up -d --force-recreate
    info "Checking..."
    sleep 10
    docker-compose -f "${compose_file}" ps 
}
## -------------------------------------------------------------------------
start() {
    local _role="$1"
    local compose_file="${WORKDIR}/docker-compose-${_role}.yml"
    if [ ! -f "${compose_file}" ];then
        err_exit "docker-compose:${compose_file}不存在."
    fi
    docker-compose -f docker-compose-single.yml  start
}
## -------------------------------------------------------------------------
stop() { 
    local _role="$1"
    local compose_file="${WORKDIR}/docker-compose-${_role}.yml"
    if [ ! -f "${compose_file}" ];then
        err_exit "docker-compose:${compose_file}不存在."
    fi
    docker-compose -f docker-compose-single.yml  stop
}
## -------------------------------------------------------------------------
check() {
    local _role="$1"
    local compose_file="${WORKDIR}/docker-compose-${_role}.yml"
    if [ ! -f "${compose_file}" ];then
        err_exit "docker-compose:${compose_file}不存在."
    fi
    docker-compose -f docker-compose-single.yml ps
}
## -------------------------------------------------------------------------
_do() {
    local _func="$1"
    local _role="$2"
    if [ "$_role" = "single" ];then
        "${_func}" ${@:2}
    else
       help_msg
   fi
}
## -------------------------------------------------------------------------
case "$1" in
    build )
        _do build ${@:2}
    ;;
    start )
        _do start ${@:2}
    ;;
    stop )
        _do stop ${@:2}
    ;;
    check )
        _do check ${@:2}
    ;;
    clear )
        _do clear ${@:2}
    ;;
    * )
        help_msg
    ;;
esac










