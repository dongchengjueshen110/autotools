#############################################################################################################
# 声明：当前配置文件定义的变量均可以根据实际情况修改。

# 建议填写为当前磁盘最大存储空间目录,如果系统盘空间最大,建议填写为/data,如果挂在盘空间最大,建议填写为挂载目录
export BASE_DIR=""

# Mysql数据和日志存放目录根目录,默认不修改
export DATA_DIR="${BASE_DIR}/basic-data"

# Mysql映射到宿主机的端口,端口不冲突情况下,建议不要修改,不要设置成mysql默认端口
export MYSQL_PORT="53000"

# Confluence映射到宿主机的端口,端口不冲突情况下,建议不要修改,不要设置成Confluence默认端口
export CONFLUENCE_HOST_PORT="8090"

# JVM参数,根据实际情况调整,如果是专用服务器建议设置为机器内存的一半,但是最大不超过32g
# Confluence最小堆内存大小和最大堆内存大小,不超过32768m,如1024m
export CONFLUENCE_MIN_MEM=""
export CONFLUENCE_MAX_MEM=""

# Mysql root密码
export MYSQL_ROOT_PASSWORD="M%AUkk4L^7Q3qg9F"

# 用于连接Confluence服务的数据库名称
export MYSQL_DATABASE="confluence"

# 用于连接Confluence服务的数据库账号
export MYSQL_USER="confluence"

# 用于连接Confluence服务的数据库密码
MYSQL_PASSWORD="QvWVtSrWhjOVk*1H"
#############################################################################################################
