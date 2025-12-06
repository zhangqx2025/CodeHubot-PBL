# CodeHubot PBL 前端项目

基于 Vue 3 + Element Plus 的跨学科项目式学习平台前端应用。

## 技术栈

- **Vue 3** - 渐进式 JavaScript 框架
- **Element Plus** - Vue 3 UI 组件库
- **Vue Router 4** - 官方路由管理器
- **Pinia** - 状态管理库
- **Axios** - HTTP 客户端
- **Vite** - 构建工具

## 项目结构

```
frontend/
├── src/
│   ├── api/              # API 接口
│   │   ├── config.js     # API 配置
│   │   └── auth.js       # 认证相关 API
│   ├── components/       # 公共组件
│   │   └── ChatPanel.vue # AI 聊天面板
│   ├── router/           # 路由配置
│   │   └── index.js      # 路由定义和守卫
│   ├── store/            # 状态管理
│   │   └── auth.js       # 认证状态管理
│   ├── views/            # 页面组件
│   │   ├── Login.vue     # 登录页
│   │   ├── Layout.vue    # 布局组件
│   │   ├── Dashboard.vue # 学习首页
│   │   ├── Projects.vue  # 项目列表
│   │   ├── ProjectDetail.vue # 项目详情
│   │   ├── Tasks.vue     # 任务管理
│   │   ├── Progress.vue  # 学习进度
│   │   ├── UnitLearning.vue # 单元学习（三分屏布局）
│   │   └── Profile.vue   # 个人中心
│   ├── App.vue           # 根组件
│   ├── main.js           # 应用入口
│   └── style.css         # 全局样式
├── index.html            # HTML 模板
├── package.json          # 项目配置
├── vite.config.js        # Vite 配置
└── README.md             # 项目说明
```

## 安装和运行

### 安装依赖

```bash
npm install
```

### 开发模式

```bash
npm run dev
```

应用将在 `http://localhost:5173` 启动

### 构建生产版本

```bash
npm run build
```

### 预览生产构建

```bash
npm run preview
```

## 功能特性

### 1. 用户认证
- 学号登录（支持多租户）
- Token 自动刷新
- 路由守卫保护

### 2. 学习首页（Dashboard）
- 学习统计展示
- 我的学习进度
- 推荐项目

### 3. 项目管理
- 项目列表浏览
- 项目详情查看
- 课程结构展示

### 4. 任务管理
- 任务列表和筛选
- 任务状态管理
- 任务进度跟踪

### 5. 单元学习（核心功能）
- **三分屏布局**：
  - 左侧：学习资源（视频、文档、任务）
  - 中间：实践任务详情
  - 右侧：AI 学习助手
- 视频播放（模态框）
- 文档阅读（Markdown 渲染）
- 任务状态管理
- AI 智能问答

### 6. 学习进度
- 学习统计
- 课程进度
- 最近活动

### 7. 个人中心
- 基本信息管理
- 学习统计
- 账号安全

## 环境变量

创建 `.env` 文件配置 API 地址：

```env
VITE_API_BASE_URL=http://localhost:8000
```

## 开发说明

### API 配置

API 基础配置在 `src/api/config.js` 中，支持：
- 请求/响应拦截器
- Token 自动刷新
- 错误处理

### 状态管理

使用 Pinia 管理应用状态：
- `auth` store：用户认证和租户信息

### 路由配置

路由定义在 `src/router/index.js`，包含：
- 路由守卫（认证检查）
- 动态路由加载
- 页面标题设置

## 页面风格

参考 `student-frontend` 项目的设计风格：
- 现代化渐变背景
- 卡片式布局
- 流畅的动画效果
- 响应式设计

## 注意事项

1. 确保后端 API 服务已启动
2. 登录需要正确的学号和学校代码格式：`学号@学校代码`
3. 单元学习页面需要单元 ID 参数

## 待完善功能

- [ ] 视频播放器集成（阿里云 VOD）
- [ ] Markdown 文档渲染优化
- [ ] 实时通知功能
- [ ] 团队协作功能
- [ ] 文件上传功能

