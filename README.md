# PicoClaw Web 部署说明

本镜像用于部署 PicoClaw WebUI / Launcher。

镜像地址：

```text
ghcr.io/jbtt-2025/pico-claw-web:latest
```

## 端口说明

PicoClaw 里常见两个端口：

```text
18800：WebUI / Launcher 默认端口
18790：Gateway 默认端口
```

本镜像的目标是暴露 WebUI。

在 Render 这类 PaaS 上，公网入口使用平台提供的 `$PORT`。  
`18790` 不需要公网暴露，除非要接入 LINE、DingTalk、飞书、Slack 等 webhook 回调，或有外部设备需要连接 Gateway。

## 环境变量

推荐设置：

```env
PICOCLAW_HOME=/var/data/picoclaw
PICOCLAW_LAUNCHER_TOKEN=请替换为足够长的随机字符串
```

说明：

```text
PICOCLAW_HOME：PicoClaw 数据目录
PICOCLAW_LAUNCHER_TOKEN：WebUI 登录 Token
PORT：PaaS 平台提供的 Web 服务端口，Render 会自动注入
```

## Render 部署

### 1. 创建 Web Service

选择：

```text
New Web Service
```

部署方式选择 Docker。

镜像填写：

```text
ghcr.io/jbtt-2025/pico-claw-web:latest
```

### 2. 设置环境变量

在 Render 的 Environment 中添加：

```env
PICOCLAW_HOME=/var/data/picoclaw
PICOCLAW_LAUNCHER_TOKEN=请替换为足够长的随机字符串
```

不需要手动设置 `PORT`。  
Render 会自动提供 `$PORT`，镜像会让 WebUI 监听该端口。

### 3. 设置持久化磁盘

添加 Disk：

```text
Mount Path: /var/data
```

建议容量按实际使用量设置。

### 4. 部署完成后访问

部署完成后，打开 Render 提供的公网地址。

登录时使用：

```text
PICOCLAW_LAUNCHER_TOKEN
```

对应的值。

## Docker 单命令部署

本地直接运行：

```bash
docker run -d \
  --name pico-claw-web \
  -p 18800:18800 \
  -e PORT=18800 \
  -e PICOCLAW_HOME=/var/data/picoclaw \
  -e PICOCLAW_LAUNCHER_TOKEN='请替换为足够长的随机字符串' \
  -v pico-claw-data:/var/data \
  ghcr.io/jbtt-2025/pico-claw-web:latest
```

访问：

```text
http://localhost:18800
```

查看日志：

```bash
docker logs -f pico-claw-web
```

停止容器：

```bash
docker stop pico-claw-web
```

删除容器：

```bash
docker rm pico-claw-web
```

数据保存在 Docker volume：

```text
pico-claw-data
```

## Gateway 端口 18790

默认情况下不需要暴露 `18790`。

只有需要外部 webhook 或外部设备接入 Gateway 时，才考虑额外暴露它。

示例：

```bash
docker run -d \
  --name pico-claw-web \
  -p 18800:18800 \
  -p 18790:18790 \
  -e PORT=18800 \
  -e PICOCLAW_HOME=/var/data/picoclaw \
  -e PICOCLAW_LAUNCHER_TOKEN='请替换为足够长的随机字符串' \
  -v pico-claw-data:/var/data \
  ghcr.io/jbtt-2025/pico-claw-web:latest
```

公网部署时不建议直接暴露 `18790`，除非已经确认需要 Gateway 对外提供服务。

## 升级镜像

拉取最新镜像：

```bash
docker pull ghcr.io/jbtt-2025/pico-claw-web:latest
```

重建容器：

```bash
docker stop pico-claw-web
docker rm pico-claw-web

docker run -d \
  --name pico-claw-web \
  -p 18800:18800 \
  -e PORT=18800 \
  -e PICOCLAW_HOME=/var/data/picoclaw \
  -e PICOCLAW_LAUNCHER_TOKEN='请替换为足够长的随机字符串' \
  -v pico-claw-data:/var/data \
  ghcr.io/jbtt-2025/pico-claw-web:latest
```

## 安全建议

请务必设置固定的 `PICOCLAW_LAUNCHER_TOKEN`。

不要使用过短、常见或公开的 Token。

WebUI 暴露到公网时，建议只提供给可信用户访问。
