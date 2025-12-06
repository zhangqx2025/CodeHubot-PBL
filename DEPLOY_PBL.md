# CodeHubot-PBL 容器化部署指南

本指南介绍如何将 CodeHubot-PBL 项目容器化部署，并连接到 CodeHubot 的基础服务（MySQL, Redis）。

## 前提条件

1. **CodeHubot** 主项目必须已经部署并运行。
   - PBL 系统依赖 CodeHubot 的 MySQL 和 Redis 服务。
   - 必须确保 CodeHubot 的 Docker 网络（默认为 `docker_aiot-network`）存在。

## 部署步骤

1. **赋予脚本执行权限**：
   ```bash
   chmod +x deploy.sh
   ```

2. **运行部署脚本**：
   ```bash
   ./deploy.sh
   ```

   该脚本会自动：
   - 检查 Docker 环境和网络。
   - 构建后端（FastAPI）和前端（Vue+Nginx）镜像。
   - 启动服务。

## 访问服务

- **前端页面**：http://localhost:8082
- **后端 API**：http://localhost:8082/api (通过 Nginx 代理)

## 配置说明

### 网络配置
`docker-compose.yml` 中使用了外部网络 `docker_aiot-network`。这是 CodeHubot 默认创建的网络名称。
如果您的 CodeHubot 使用了不同的网络名称（可以通过 `docker network ls` 查看），请修改 `docker-compose.yml` 中的 `networks` 部分：

```yaml
networks:
  aiot-network:
    external: true
    name: 您的实际网络名称
```

### 数据库连接
后端服务通过容器名称 `codehubot-mysql` 连接到数据库。如果 CodeHubot 的数据库容器名称不同，请修改 `docker-compose.yml` 中的 `DATABASE_URL` 环境变量。

### 端口冲突
PBL 前端默认占用 **8082** 端口。如果该端口被占用，可以在 `docker-compose.yml` 中修改 `pbl-frontend` 的端口映射。
