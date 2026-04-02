# weather-service

![Go](https://img.shields.io/badge/go-%2300ADD8.svg?style=flat&logo=go&logoColor=white)
![Gin](https://img.shields.io/badge/gin-%230081cf.svg?style=flat)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=flat&logo=mysql&logoColor=white)

**weather-service** 是“小天气 (Small Weather)”应用的后端服务。它基于 Go 语言和 Gin 框架开发，提供天气数据代理、用户认证、城市管理以及云存储 STS 凭证发放等核心功能。

## 🌟 主要功能

- 🌦️ **天气数据代理**：对和风天气 (QWeather) API 进行高级封装与代理，统一处理 API Key 和参数。
- 🔐 **用户身份认证**：
  - 基于 JWT (JSON Web Token) 的无状态认证。
  - 注册与找回密码时，通过 SMTP 发送 6 位数字验证码。
- 🏙️ **用户数据管理**：
  - **城市管理**：支持用户保存并同步多个城市。
  - **个性化设置**：同步用户的拟物化光影参数、语言及外观模式。
- ☁️ **云存储集成**：集成腾讯云 COS，为移动端上传头像动态发放 STS (临时密钥)，确保安全。
- 🕒 **自动化任务**：内置定时器，自动清理过期的邮箱验证码。

## 🛠️ 技术栈

- **Golang**: v1.26.1
- **Web Framework**: [Gin Gonic](https://github.com/gin-gonic/gin)
- **Database**: MySQL (使用 `github.com/go-sql-driver/mysql`)
- **Authentication**: JWT
- **Email**: 标准 SMTP 处理
- **Cloud SDK**: [Tencent Cloud COS Go SDK](https://github.com/tencentyun/qcloud-cos-sts-sdk)

## 📁 目录结构

```text
weather-service/
├── handlers/           # 业务逻辑 (Auth, Weather, City, Mailer等)
├── middleware/         # 中间件 (Auth 校验、请求日志)
├── logs/               # 服务器运行日志
├── main.go             # 服务入口与路由配置
├── db.sql              # 数据库初始化脚本
└── .env (需创建)        # 环境配置文件
```

## 🚀 部署与运行

### 1. 数据库准备
使用 `db.sql` 在您的 MySQL 实例中创建数据库及表结构。

# 本地环境配置 (需创建 .env 文件并参考以下配置)

# MySQL 连接配置
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_password
MYSQL_DB=weather_db

# 认证安全配置
JWT_SECRET=your_jwt_secret_key  # 必填，用于加密 Token

# SMTP 邮件服务配置 (注册/重置密码验证码)
SMTP_HOST=smtp.exmail.qq.com
SMTP_PORT=465
SMTP_USERNAME=your_email@example.com
SMTP_PASSWORD=your_smtp_password
SMTP_FROM_EMAIL=your_email@example.com
SMTP_FROM_NAME=小天气

# 腾讯云 COS 配置 (用户头像上传)
COS_SECRET_ID=your_cos_id
COS_SECRET_KEY=your_cos_key
COS_BUCKET=your_cos_bucket_name
COS_REGION=your_cos_region
COS_APPID=your_cos_appid
COS_BASE_PREFIX=your_cos_base_prefix (e.g. flwoerweather/avatar)

# 和风天气 API Key (数据接口)
QWEATHER_KEY=your_qweather_key

### 3. 运行服务
```bash
go mod download
go run main.go
```
服务默认运行在 `http://localhost:3001`。

## 🔗 接口文档 (API Endpoints)

所有接口的基础路径为 `/api`。

### 🔓 认证接口 (Auth)
用于处理用户登录、注册及找回密码。

| 方法 | 路径 | 说明 |
| :--- | :--- | :--- |
| `POST` | `/auth/login` | 用户登录 (Email + Password) |
| `POST` | `/auth/register/send-code` | 发送注册验证码 |
| `POST` | `/auth/register` | 用户注册 (含验证码校验) |
| `POST` | `/auth/reset-password/send-code` | 发送重置密码验证码 |
| `POST` | `/auth/reset-password/verify-code` | 校验重置密码验证码 |
| `POST` | `/auth/reset-password` | 重置密码 |
| `POST` | `/auth/logout` | 退出登录 (需要 Auth) |

### 🔒 用户接口 (User - 需要 Auth)
所有接口需在 Header 中携带 `Authorization: Bearer <token>`。

| 方法 | 路径 | 说明 |
| :--- | :--- | :--- |
| `GET` | `/user/profile` | 获取用户信息 |
| `PUT` | `/user/profile` | 更新用户信息 (昵称/头像 URL) |
| `GET` | `/user/avatar/sts` | 获取腾讯云 COS 临时上传凭证 |
| `GET` | `/user/cities` | 获取用户保存的城市列表 |
| `POST` | `/user/cities` | 添加城市到用户列表 |
| `DELETE` | `/user/cities/:id` | 从列表中删除指定城市 |
| `GET` | `/user/settings` | 获取用户个性化设置 (光影/语言等) |
| `POST` | `/user/settings` | 保存/更新用户个性化设置 |

### ☁️ 天气代理接口 (Weather)
代理至和风天气，统一处理 Key 校验。

| 方法 | 路径 | 说明 |
| :--- | :--- | :--- |
| `GET` | `/weather/geo/lookup` | 城市搜索 (关键字搜索) |
| `GET` | `/weather/geo/top` | 热门城市列表查询 |
| `GET` | `/weather/now` | 获取实时天气数据 |
| `GET` | `/weather/24h` | 获取逐小时天气预报 |
| `GET` | `/weather/7d` | 获取未来 7 天天气预报 |

---
*由 [Pencil Gallery](https://github.com/pencil-gallery) 团队开发与维护*
