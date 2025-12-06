#!/bin/bash

# ==========================================
# CodeHubot-PBL 自动化部署脚本
# ==========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装"
        exit 1
    fi
}

check_network() {
    log_info "检查 Docker 网络..."
    if ! docker network inspect docker_aiot-network >/dev/null 2>&1; then
        log_warn "网络 'docker_aiot-network' 不存在。"
        log_warn "请确保 CodeHubot 主服务已启动，且网络名称正确。"
        log_warn "如果 CodeHubot 使用了不同的网络名称，请修改 docker-compose.yml 中的网络名称。"
        
        # 尝试查找类似的 aiot 网络
        POSSIBLE_NETWORKS=$(docker network ls --filter name=aiot --format "{{.Name}}")
        if [ -n "$POSSIBLE_NETWORKS" ]; then
            log_info "发现可能的网络: $POSSIBLE_NETWORKS"
        fi
        
        read -p "是否继续？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_info "网络 'docker_aiot-network' 检查通过 ✓"
    fi
}

build_images() {
    log_info "构建镜像..."
    docker-compose build
}

start_services() {
    log_info "启动服务..."
    docker-compose up -d
    
    log_info "等待服务启动..."
    sleep 5
    
    if docker-compose ps | grep -q "Up"; then
        log_info "服务启动成功 ✓"
        log_info "前端访问地址: http://localhost:8082"
        log_info "后端API地址: http://localhost:8082/api (通过前端代理)"
    else
        log_error "服务启动失败，请检查日志: docker-compose logs"
    fi
}

stop_services() {
    log_info "停止服务..."
    docker-compose down
}

# 主逻辑
ACTION="${1:-deploy}"

case "${ACTION}" in
    deploy)
        check_dependencies
        check_network
        stop_services
        build_images
        start_services
        ;;
    start)
        check_dependencies
        check_network
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        stop_services
        start_services
        ;;
    logs)
        docker-compose logs -f
        ;;
    *)
        echo "用法: $0 {deploy|start|stop|restart|logs}"
        exit 1
        ;;
esac
