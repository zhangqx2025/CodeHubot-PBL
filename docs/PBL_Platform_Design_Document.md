# CodeHubot 跨学科项目式学习 (PBL) 平台设计文档

**版本**: v2.1  
**日期**: 2025-12-05  
**状态**: 正式版  
**文档维护**: 产品与技术团队  
**更新说明**: 
- 移除 IoT 服务相关内容
- 明确数据库使用 CodeHubot 主系统的 MySQL 数据库（复用）

---

## 目录

1. [项目概述](#1-项目概述)
2. [系统架构设计](#2-系统架构设计)
3. [功能模块设计](#3-功能模块设计)
4. [学习模式与路径](#4-学习模式与路径)
5. [数据模型设计](#5-数据模型设计)
6. [API 接口设计](#6-api-接口设计)
7. [交互与体验设计](#7-交互与体验设计)
8. [技术与非功能需求](#8-技术与非功能需求)
9. [部署与运维](#9-部署与运维)
10. [扩展性设计](#10-扩展性设计)

---

## 1. 项目概述

### 1.1 背景与愿景

CodeHubot PBL 平台旨在为 K-12（6-15岁）阶段的学生提供一个沉浸式、跨学科的项目式学习环境。平台结合了人工智能（AI）和编程教育，通过"做中学"（Learning by Doing）的教育理念，培养学生的创新思维、团队协作能力和复杂问题解决能力。

**核心教育理念**：
- **项目驱动**：以真实场景项目为载体，激发学习兴趣
- **跨学科融合**：整合信息技术、物理、数学、语文等多学科知识
- **能力培养**：重点训练学生自主思考、问题分析和实践验证能力
- **AI 赋能**：利用 AI 技术提供个性化学习支持和智能评估

### 1.2 目标用户

#### 1.2.1 学生 (6-15岁)
- **特征**：好奇心强，喜欢探索，需要趣味化和可视化的学习体验
- **使用场景**：课后学习、团队协作、项目实践
- **核心需求**：
  - 清晰的学习路径和进度反馈
  - 即时的问题解答和指导
  - 有趣的互动和成就感激励
  - 便捷的团队协作工具

#### 1.2.2 教师
- **特征**：需要高效的教学管理工具和评估体系
- **使用场景**：课程编排、进度监控、作业批改、学生评估
- **核心需求**：
  - 可视化的课程编排工具
  - 实时的学生学习数据监控
  - 高效的作业批改和反馈机制
  - 多维度学生能力评估

#### 1.2.3 学校管理员
- **特征**：需要全局视角的数据分析和系统管理
- **使用场景**：账号管理、数据统计、系统配置
- **核心需求**：
  - 批量账号管理和权限控制
  - 全校教学数据大屏展示
  - 系统配置和维护

### 1.3 核心价值

- **真实场景驱动**：课程基于真实的工业或生活场景（如智能家居、智慧农业）
- **AI 赋能**：集成 AI 智能体（Agent）作为助教，提供个性化辅导和实时反馈
- **双平台驱动**：结合成熟的 **Coze 智能体创作平台**（学习基础 AI 技能）与 **CodeHubot 自研平台**（进行 AI 应用实战），实现技能到应用的闭环
- **全流程管理**：覆盖从组队、选题、探究、制作到展示评价的学习全周期
- **跨学科融合**：一个项目融合多个学科知识，培养综合能力

---

## 2. 系统架构设计

### 2.1 整体架构

平台采用**前后端分离的微服务架构**，确保高可用性、可扩展性和安全性。

```
┌─────────────────────────────────────────────────────────┐
│                     接入层 (Access Layer)                 │
│  Web端(PC/平板)  │  移动端(H5)  │  小程序(未来)          │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                   应用层 (Application Layer)              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ 学生端   │  │ 教师端   │  │ 管理端   │            │
│  │ Portal   │  │ Portal   │  │ Console  │            │
│  └──────────┘  └──────────┘  └──────────┘            │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                   服务层 (Service Layer)                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │课程服务  │  │项目服务  │  │ AI服务   │            │
│  └──────────┘  └──────────┘  └──────────┘            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │用户服务  │  │评估服务  │  │通知服务  │            │
│  └──────────┘  └──────────┘  └──────────┘            │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                   数据层 (Data Layer)                     │
│  MySQL  │  MongoDB  │  Redis  │  OSS/MinIO            │
└─────────────────────────────────────────────────────────┘
```

### 2.2 逻辑架构

#### 2.2.1 接入层
- **Web 端**：PC/平板，响应式设计，支持 1920x1080 及以上分辨率
- **移动端**：H5 适配，支持 375px 及以上宽度
- **小程序**：未来扩展，支持微信小程序

#### 2.2.2 应用层

**学生端功能模块**：
- 学习仪表盘（Dashboard）
- 沉浸式单元学习（Unit Learning）
- 项目与协作（Project & Collaboration）
- 任务管理（Task Management）
- 学习进度（Learning Progress）
- 个人中心（User Profile）

**教师端功能模块**：
- 课程编排（Course Authoring）
- 班级管理（Class Management）
- 进度监控（Progress Monitoring）
- 作业批改（Assignment Grading）
- 数据分析（Data Analytics）

**管理端功能模块**：
- 机构管理（Organization Management）
- 用户管理（User Management）
- 权限控制（Permission Control）
- 数据大屏（Data Dashboard）

#### 2.2.3 服务层

**课程服务 (Course Service)**：
- 课程内容管理（CRUD）
- 资源管理（视频、文档、链接）
- 学习路径控制（单元解锁逻辑）
- 学习进度追踪

**项目服务 (Project Service)**：
- 团队管理（创建、加入、退出）
- 任务看板（Kanban Board）
- 作品提交与版本管理
- 项目进度统计

**AI 服务 (AI Service)**：
- **智能助教**：
  - 基于 RAG 技术的问答系统
  - 上下文感知的对话管理
  - 学习建议生成
  - 代码检查与反馈
- **Coze 集成**：
  - 引导学生使用 Coze 平台
  - 智能体创建指导
  - 平台操作演示

**用户服务 (User Service)**：
- 用户认证与授权（JWT Token）
- 用户信息管理
- 权限管理（RBAC）
- 学习统计计算

**评估服务 (Assessment Service)**：
- 作业自动评分（基于规则）
- 过程评价数据收集
- 多维度能力评估
- 学习报告生成

#### 2.2.4 数据层

**数据库说明**：
- **MySQL**：**复用 CodeHubot 主系统的 MySQL 数据库**
  - PBL 系统与 CodeHubot 主系统共享同一个 MySQL 数据库实例
  - 复用表：`aiot_core_users`、`aiot_schools`、`aiot_classes`、`aiot_course_groups`、`aiot_group_members`
  - 新增表：所有 PBL 专用表以 `pbl_` 前缀开头
  - 存储结构化数据（用户、课程、项目、任务等）

**其他存储服务**：
- **MongoDB**：存储非结构化数据（学习日志、AI 对话记录等）
- **Redis**：缓存热点数据（用户会话、课程列表、统计数据）
- **阿里云视频点播 (VOD)**：视频文件存储和播放服务
- **OSS/MinIO**：文件存储（文档、图片、代码文件）

### 2.3 技术栈选型

#### 2.3.1 前端技术栈
- **框架**：Vue 3 + Composition API
- **UI 组件库**：Element Plus
- **路由**：Vue Router 4
- **状态管理**：Pinia
- **构建工具**：Vite
- **HTTP 客户端**：Axios
- **图表库**：ECharts（用于数据可视化）
- **Markdown 渲染**：MarkdownIt

#### 2.3.2 后端技术栈（推荐）
- **语言**：Python 3.10+ 或 Node.js 18+
- **框架**：FastAPI / Django REST Framework 或 NestJS
- **ORM**：SQLAlchemy / TypeORM
- **消息队列**：RabbitMQ / Redis Streams（用于异步任务处理）
- **WebSocket**：用于实时通信（AI 对话流式输出、通知推送）

#### 2.3.3 基础设施
- **容器化**：Docker + Docker Compose
- **反向代理**：Nginx
- **CI/CD**：GitHub Actions / GitLab CI
- **监控**：Prometheus + Grafana
- **日志**：ELK Stack（可选）

---

## 3. 功能模块设计

### 3.1 学生端 (Student Portal)

#### 3.1.0 导航菜单结构
学生端采用左侧固定导航菜单的设计，核心功能模块规划如下：
1. **学习首页 (Dashboard)**：学生登录后的控制台，聚合核心数据、当前进度和最新通知。
2. **项目列表 (Projects)**：展示所有可选课程项目，支持筛选与搜索，是开启新学习的入口。
3. **任务列表 (Tasks)**：具体的任务管理中心，清晰展示待办事项并提供沉浸式学习入口。
4. **学习进度 (Progress)**：多维度的数据化反馈，包含图表分析、能力雷达图和成就系统。
5. **个人信息 (Profile)**：个人账户设置、成长档案与安全管理。

#### 3.1.1 学习仪表盘 (Dashboard)

**功能描述**：
学生登录后的首页，展示学习概况、最新通知、待办任务和进度统计。

**核心功能**：
- **欢迎横幅**：
  - 个性化问候（如"欢迎回来，小明！"）
  - 学习统计数据卡片（已完成项目数、进行中项目数、总学习时长）
- **我的学习进度**：
  - 当前进行中的项目列表
  - 每个项目显示：项目图标、标题、描述、进度条、剩余天数
  - "继续学习"按钮，点击跳转到项目详情或最近学习的单元
- **为你推荐**：
  - 推荐项目卡片网格布局
  - 每个卡片显示：项目分类、难度标签、标题、描述、时长、团队规模、技能点
  - "开始项目"和"了解更多"按钮
  - 支持"查看更多项目"跳转
- **最新通知**：
  - 系统通知、项目通知、团队消息
  - 未读消息数量提示

**设计要点**：
- 采用卡片式布局，视觉层次清晰
- 支持深色/浅色主题切换
- 响应式设计，适配不同屏幕尺寸
- 数据实时更新（WebSocket 或轮询）

#### 3.1.2 沉浸式单元学习 (Immersive Unit Learning)

**功能描述**：
基于 `UnitLearning.vue` 实现的**三分屏布局**，提供沉浸式学习体验。

**布局结构**：

```
┌─────────────────────────────────────────────────────────┐
│  单元导航栏：返回课程 | 单元标题 | 上一单元 | 下一单元    │
└─────────────────────────────────────────────────────────┘
┌──────────────┬──────────────┬──────────────┐
│  左侧面板    │  中间面板     │  右侧面板    │
│  资源导航    │  实践任务区   │  AI智能助手  │
│              │              │              │
│  [Tab切换]   │  任务详情     │  对话窗口    │
│  - 学习导引  │  任务要求     │  快捷提问    │
│  - 视频教程  │  状态控制     │  输入框      │
│  - 学习文档  │              │              │
│  - 任务列表  │              │              │
└──────────────┴──────────────┴──────────────┘
```

**左侧：资源导航 (Resources Panel)**

- **Tab 切换**：
  - 🗺️ 学习导引（Guide）：展示单元学习路径、分阶段学习步骤、学习建议
  - 📹 视频教程（Videos）：视频列表，卡片式展示
  - 📄 学习文档（Docs）：文档列表，支持 Markdown 渲染
  - 🎯 任务列表（Tasks）：任务列表，显示任务状态和元信息

- **视频播放功能**：
  - 点击视频卡片 → 弹出模态框播放
  - 内置 HTML5 视频播放器，支持播放进度记录
  - **防下载保护**：
    - 禁用右键菜单
    - 禁用常见下载快捷键（Ctrl+S, F12, Ctrl+U 等）
    - 禁用拖拽
    - 禁用选择文本
  - 支持全屏播放模式
  - 播放进度自动保存到本地存储，下次继续播放

- **文档阅读功能**：
  - 点击文档卡片 → 弹出模态框阅读
  - Markdown 内容实时渲染，支持代码高亮
  - 支持全屏阅读模式
  - 阅读时长统计（用于学习分析）

**中间：实践任务区 (Practice Zone)**

- **任务详情展示**：
  - 任务标题、描述、难度、预计时长、类型
  - 任务要求列表（Requirements）
  - 任务状态标签（待开始/进行中/已完成/阻塞/待审核/暂停/已取消）

- **状态流转机制**：
  ```
  待开始 (Pending)
    ↓ [开始任务]
  进行中 (In Progress)
    ↓ [提交审核] 或 [遇到问题]
  待审核 (Review) / 阻塞 (Blocked)
    ↓ [审核通过] / [解决问题]
  已完成 (Completed)
  ```

- **状态控制**：
  - 下拉选择框切换任务状态
  - 状态变更时触发 AI 助手提示（如"恭喜完成任务，继续加油！"）
  - 状态变更自动保存到本地存储，并同步到服务器

- **空状态提示**：
  - 未选择任务时显示引导提示
  - 提供"查看任务列表"快捷按钮

**右侧：AI 智能助手 (AI Tutor Panel)**

- **即时对话功能**：
  - 对话消息列表，支持滚动查看历史
  - 用户消息右对齐，AI 消息左对齐
  - 支持流式打字机效果（逐字显示）
  - 消息时间戳显示

- **快捷提问**：
  - 根据当前单元内容推荐问题
  - 常见问题按钮（如"这个单元的重点是什么？"、"如何完成当前任务？"）
  - 点击快捷问题自动填充到输入框并发送

- **功能菜单**：
  - 导出对话记录（TXT 格式）
  - 清空对话历史
  - 切换主题（浅色/深色）

- **AI 能力**：
  - 解释概念：基于当前学习内容解释专业术语
  - 检查代码：分析学生提交的代码，提供改进建议
  - 提供思路：遇到问题时提供解决思路（而非直接答案）
  - 学习建议：根据学习进度提供个性化建议

**学习导引功能**：

- **学习路径展示**：
  - 总学习时长、学习模式描述
  - 分阶段学习步骤（如"第一阶段：基础概念与平台入门"）
  - 每个阶段包含：视频、文档、任务的组合
  - 点击资源项可直接打开对应内容

- **学习建议**：
  - 学习顺序建议
  - 时间安排建议
  - 注意事项提醒

#### 3.1.3 项目与协作 (Project & Collaboration)

**项目列表页面**：
- 项目卡片网格布局
- 项目筛选（按状态、难度、分类）
- 项目搜索功能
- "开始项目"和"查看详情"操作

**项目详情页面**：
- 项目基本信息（标题、描述、难度、时长、团队规模）
- 项目进度概览（总体进度、已完成任务数/总任务数）
- 项目成员列表
- 项目资源（文档、视频、代码仓库链接）

**任务看板 (Kanban Board)**：
- 类似 Trello 的拖拽式任务板
- 任务列：待开始、进行中、待审核、已完成
- 任务卡片显示：标题、描述、负责人、截止日期、优先级
- 支持拖拽任务卡片改变状态
- 点击卡片查看任务详情

**团队空间 (Team Workspace)**：
- **协作工具与空间**：
  - **成员管理**：展示成员列表及角色（项目经理、算法工程师、前端工程师、测试工程师等），支持权限管理。
  - **任务看板 (Kanban)**：类似 Trello 的拖拽式看板，团队成员协作管理任务状态（待开始 -> 进行中 -> 待审核 -> 已完成），实时同步进度。
  - **文件共享中心**：团队专属的云存储区域，用于上传文档、代码、素材，支持版本管理和评论。
  - **团队即时通讯**：内置聊天室，支持 @成员提醒和文件一键分享，保留沟通记录。
- **数据与评价关联**：
  - 系统自动分析团队协作频次（消息数、文件共享数），作为"协作能力"过程评价的数据支撑。
  - 数据库底层复用 `aiot_course_groups` 表，确保数据一致性。
- **功能详情**：
  - **成员管理**：
    - 成员列表（头像、姓名、角色）
    - 角色分配（项目经理、算法工程师、前端工程师、测试工程师等）
    - 成员权限管理
  - **文件共享**：
    - 团队专属文件上传区
    - 文件分类（文档、代码、图片、视频）
    - 文件版本管理
    - 文件评论功能
  - **团队聊天**：
    - 实时消息交流
    - 支持@成员提醒
    - 文件分享

#### 3.1.4 任务列表 (Task List)

**任务列表页面**：
- 项目信息头部（项目标题、描述、总体进度）
- 任务筛选（按状态、类型）
- 任务搜索功能
- 任务卡片列表：
  - 任务状态图标（完成✓、进行中⏳、未开始⏰）
  - 任务标题、描述
  - 任务元信息（类型、难度、预计时长）
  - 任务进度条（进行中的任务）
  - 学习资源标签（视频、文档）
  - "进入学习"按钮（跳转到单元学习页面）

**任务详情页面**：
- 任务基本信息
- 任务要求列表
- 学习资源链接
- 提交区域（文本输入、文件上传）
- 提交历史记录
- 教师评语和分数

#### 3.1.5 学习进度 (Learning Progress)

**进度概览**：
- 总体进度卡片：
  - 圆形进度环（可视化进度百分比）
  - 已完成任务数/总任务数
  - 总学习时长
- 本周学习卡片：
  - 本周学习天数/7
  - 本周学习时长
  - 本周完成任务数
  - 本周进度条
- 学习成就卡片：
  - 成就列表（图标、名称、描述）
  - 已解锁/未解锁状态

**详细进度分析**：
- 时间筛选（本周/本月/全部）
- 学习时长趋势图（柱状图）
- 任务完成情况（饼图）
- 学习热力图（日历视图）
- 能力雷达图（多维度能力评估）

**单元进度详情**：
- 单元列表，显示每个单元的完成状态
- 点击单元查看该单元的详细进度

#### 3.1.6 个人中心 (User Profile)

**基础信息**：
- 头像上传（支持裁剪）
- 昵称修改
- 班级信息显示
- 学号显示（不可修改）

**成长档案**：
- 学习统计：
  - 总学习时长（小时）
  - 已完成项目数
  - 完成任务数
  - 获得成就数
- 能力雷达图：
  - 多维度能力评估（编程能力、协作能力、创新能力、问题解决能力等）
- 荣誉勋章墙：
  - 完成特定课程或挑战解锁的勋章
  - 勋章展示（图标、名称、获得时间）

**账号安全**：
- 密码修改（首次登录强制修改）
- 登录历史记录
- 登录设备管理（查看登录设备，支持远程登出）

### 3.2 教师端 (Teacher Portal)

#### 3.2.1 课程编排 (Course Authoring)

**课程管理**：
- 课程列表（我创建的课程、学校课程库）
- 课程创建/编辑：
  - 基本信息（标题、描述、封面图、难度、时长）
  - 课程设置（是否公开、是否需要审核）

**单元管理**：
- 单元列表（拖拽排序）
- 单元创建/编辑：
  - 基本信息（标题、描述、顺序）
  - 单元状态（锁定/解锁）
  - 学习导引配置（JSON 格式）

**资源管理**：
- 资源上传：
  - **视频上传**：使用阿里云视频点播服务（VOD）
    - 支持格式：MP4, WebM, AVI, MOV 等
    - 上传后自动转码，生成多种清晰度（标清、高清、超清）
    - 自动生成视频封面图
    - 支持视频加密和防盗链
    - 视频播放使用阿里云播放器 SDK
  - 文档上传（支持格式：Markdown, PDF, DOCX）
  - 链接添加
- 资源编辑：
  - 资源标题、描述
  - 资源关联（视频关联文档、文档关联任务）
  - 资源删除

**任务配置**：
- 任务创建/编辑：
  - 基本信息（标题、描述、类型、难度、预计时长）
  - 任务要求列表（多行文本输入）
  - 任务前置条件（完成哪些任务后才能开始）
  - 评分标准配置
- 任务模板：
  - 预设任务模板（分析类、编程类、设计类、部署类）
  - 快速创建任务

**资源库**：
- 共享的教学素材库
- 素材分类（视频、文档、图片、代码示例）
- 素材搜索和筛选
- 素材复用（一键添加到课程）

#### 3.2.2 班级与团队管理

**学生管理**：
- 学生列表（表格展示）：
  - 学号、姓名、班级、状态（正常/禁用）
  - 学习统计（完成项目数、学习时长）
- 批量操作：
  - 批量导入学生（Excel 模板）
  - 批量生成账号（用户名=学号，密码=身份证后六位）
  - 批量重置密码
  - 批量分配班级
- 学生详情：
  - 查看学生学习进度
  - 查看学生提交的作业
  - 查看学生学习日志

**团队管理**：
- 团队列表：
  - 团队名称、成员数、项目数、创建时间
- 团队详情：
  - 成员列表（角色、加入时间）
  - 团队项目列表
  - 团队活跃度统计
- 团队操作：
  - 创建团队（手动分配成员）
  - 解散团队
  - 调整团队成员

**进度监控**：
- 班级进度概览：
  - 总体完成率
  - 平均学习时长
  - 任务完成分布（饼图）
- 学生进度列表：
  - 学生姓名、完成进度、学习时长、最后活跃时间
  - 进度热力图（颜色深浅表示完成度）
- 预警功能：
  - 识别"滞后"学生（进度低于平均值一定比例）
  - 自动发送提醒通知

#### 3.2.3 评估与反馈

**作业批改**：
- 待批改作业列表：
  - 学生姓名、任务名称、提交时间、状态（待批改/已批改）
- 作业详情：
  - 学生提交内容（文本、文件、代码）
  - 在线预览（代码高亮、图片查看、视频播放）
  - 评分输入（分数、评语）
  - 提交批改结果
- 批量批改：
  - 快速评分（预设评分模板）
  - 批量添加评语

**过程评价**：
- AI 辅助分析：
  - 学生活跃度分析（登录频率、学习时长、任务完成率）
  - 协作频次分析（团队消息数、文件共享次数）
  - 代码提交质量分析（代码行数、提交频率、代码复杂度）
- 多维度评估：
  - 能力维度（编程能力、协作能力、创新能力、问题解决能力）
  - 雷达图可视化
- 学习报告生成：
  - 自动生成学生学习报告（PDF 格式）
  - 包含：学习进度、能力评估、学习建议

### 3.3 管理端 (Admin Console)

#### 3.3.1 机构管理

**学校信息配置**：
- 学校基本信息（名称、地址、联系方式）
- 学校 Logo 上传
- 学期/学年设置：
  - 学期开始/结束时间
  - 学期名称（如"2024-2025学年第一学期"）

**课程库管理**：
- 全校课程库（所有教师创建的课程）
- 课程审核（审核通过后才能公开）
- 课程分类管理

#### 3.3.2 用户管理

**用户列表**：
- 用户信息（姓名、角色、班级、状态）
- 用户搜索和筛选
- 批量操作（批量禁用、批量删除）

**账号管理**：
- 账号生成规则配置
- 批量生成账号
- 账号导入/导出

**权限管理 (RBAC)**：
- 角色定义（学生、教师、教务、管理员）
- 权限配置（功能权限、数据权限）
- 用户角色分配

#### 3.3.3 数据大屏

**全校数据概览**：
- 实时数据（当前在线人数、今日活跃用户数）
- 学习统计（总学习时长、完成项目数、完成任务数）
- 课程统计（课程总数、活跃课程数、热门课程排行）

**可视化图表**：
- 学习活跃度趋势（折线图）
- 课程完成率（柱状图）
- 学生能力分布（雷达图）
- 区域分布（地图热力图，如果有多校区）

**数据导出**：
- 支持导出 Excel、PDF 格式
- 自定义报表生成

---

## 4. 学习模式与路径

### 4.1 PBL 核心流程

遵循标准的项目式学习五步法：

#### 4.1.1 提出驱动性问题 (Driving Question)

**示例**："如何用 AI 打造更节能、更智能的家？"

**设计要点**：
- 问题要真实、有意义
- 问题要开放，没有唯一答案
- 问题要能激发学生兴趣
- 问题要能整合多个学科知识

#### 4.1.2 组建团队 (Team Building)

**团队规模**：3-4 人

**角色分配**：
- **项目经理**：负责项目规划、进度管理、团队协调
- **算法工程师**：负责智能体开发、逻辑设计、API 集成
- **前端工程师**：负责界面设计、用户体验优化
- **测试工程师**（可选）：负责功能测试、性能测试

**团队契约**：
- 明确团队目标
- 制定协作规则
- 分配任务和责任
- 建立沟通机制

#### 4.1.3 探究与技能学习 (Inquiry & Skill Building)

**学习路径**：
- **基础阶段**：掌握核心概念和基础技能
- **进阶阶段**：深入学习高级功能和系统集成
- **综合阶段**：项目整合和优化

**学习方式**：
- 观看视频教程
- 阅读学习文档
- 完成实践任务
- AI 助教答疑
- 团队讨论

**学习资源**：
- 视频教程：系统化的知识点讲解
- 学习文档：深入的理论知识补充
- 实践任务：动手操作巩固学习
- AI 智能助手：随时解答疑问

#### 4.1.4 制定方案与实施 (Planning & Implementation)

**方案设计**：
- 需求分析
- 系统架构设计
- 功能模块划分
- 技术选型

**任务分解**：
- 使用看板工具分解任务
- 分配任务给团队成员
- 设置任务优先级和截止时间
- 跟踪任务进度

**开发实施**：
- 使用平台工具进行开发
- 测试和调试
- 迭代优化

#### 4.1.5 展示与反馈 (Presentation & Critique)

**项目展示**：
- 项目演示（功能演示视频）
- 项目路演（PPT 展示）
- 代码和文档提交

**评价反馈**：
- 教师评价（功能完整性、代码质量、创新性）
- 同学互评（学习其他团队的项目）
- 自我反思（总结学习收获和不足）

---

## 5. 数据模型设计

### 5.1 数据库设计原则

#### 5.1.1 表命名规范

- **复用表**：直接使用 CodeHubot 系统现有的表（无前缀）
- **PBL 专用表**：所有 PBL 系统新增的表均以 `pbl_` 前缀开头

#### 5.1.2 复用表说明

PBL 系统复用 CodeHubot 系统的以下核心表，**不创建新表**：

1. **`aiot_core_users`** - 用户信息表
   - 包含：用户基本信息、角色、学校、班级、小组关联
   - PBL 系统直接使用，通过 `role` 字段区分学生/教师/管理员

2. **`aiot_schools`** - 学校信息表
   - 包含：学校基本信息、联系方式、授权信息
   - PBL 系统直接使用，用于多租户隔离

3. **`aiot_classes`** - 班级信息表
   - 包含：班级名称、年级、班主任、学期信息
   - PBL 系统直接使用，学生通过 `class_id` 关联班级

4. **`aiot_course_groups`** - 课程小组表（用于 PBL 项目团队）
   - 包含：小组名称、组长、成员数、所属课程
   - PBL 系统直接使用，作为项目团队的基础

5. **`aiot_group_members`** - 小组成员表
   - 包含：学生与小组的关联关系
   - PBL 系统直接使用，管理团队成员

**注意**：PBL 系统通过外键关联这些复用表，确保数据一致性。

### 5.2 PBL 系统核心表结构

所有 PBL 系统新增的表均以 `pbl_` 前缀开头，如下所示：

```
pbl_courses (PBL课程表)
  ├── id (主键)
  ├── uuid (UUID，唯一标识)
  ├── title (标题)
  ├── description (描述)
  ├── cover_image (封面图URL)
  ├── duration (时长，如"8周")
  ├── difficulty (难度：beginner/intermediate/advanced)
  ├── status (状态：draft/published/archived)
  ├── creator_id (外键 → aiot_core_users.id，创建者)
  ├── school_id (外键 → aiot_schools.id，所属学校)
  └── created_at, updated_at

pbl_units (PBL单元表)
  ├── id (主键)
  ├── uuid (UUID，唯一标识)
  ├── course_id (外键 → pbl_courses.id)
  ├── title (标题)
  ├── description (描述)
  ├── order (顺序，整数)
  ├── status (状态：locked/available/completed)
  ├── learning_guide (JSON，学习导引配置)
  └── created_at, updated_at

pbl_resources (PBL资源表)
  ├── id (主键)
  ├── uuid (UUID，唯一标识)
  ├── unit_id (外键 → pbl_units.id)
  ├── type (类型：video/document/link)
  ├── title (标题)
  ├── description (描述)
  ├── url (资源URL)
  ├── content (内容，Markdown格式，用于文档)
  ├── duration (时长，用于视频，单位：分钟)
  ├── order (顺序)
  ├── video_id (阿里云视频ID，仅视频类型)
  ├── video_cover_url (视频封面图URL，仅视频类型)
  └── created_at, updated_at

pbl_tasks (PBL任务表)
  ├── id (主键)
  ├── uuid (UUID，唯一标识)
  ├── unit_id (外键 → pbl_units.id)
  ├── title (标题)
  ├── description (描述)
  ├── type (类型：analysis/coding/design/deployment)
  ├── difficulty (难度：easy/medium/hard)
  ├── estimated_time (预计时长，如"20分钟")
  ├── requirements (JSON数组，任务要求列表)
  ├── prerequisites (JSON数组，前置任务ID列表)
  └── created_at, updated_at

pbl_projects (PBL项目表)
  ├── id (主键)
  ├── uuid (UUID，唯一标识)
  ├── group_id (外键 → aiot_course_groups.id，关联课程小组)
  ├── course_id (外键 → pbl_courses.id)
  ├── title (标题)
  ├── description (描述)
  ├── status (状态：planning/in-progress/review/completed)
  ├── progress (进度，0-100)
  ├── repo_url (代码仓库URL)
  └── created_at, updated_at

pbl_task_progress (PBL任务进度表)
  ├── id (主键)
  ├── task_id (外键 → pbl_tasks.id)
  ├── user_id (外键 → aiot_core_users.id)
  ├── status (状态：pending/in-progress/blocked/review/completed)
  ├── progress (进度，0-100)
  ├── submission (JSON，提交内容)
  ├── score (分数，0-100)
  ├── feedback (评语)
  ├── graded_by (外键 → aiot_core_users.id，批改人)
  ├── graded_at (批改时间)
  └── created_at, updated_at

pbl_ai_conversations (PBL AI对话记录表)
  ├── id (主键)
  ├── uuid (UUID，唯一标识)
  ├── user_id (外键 → aiot_core_users.id)
  ├── unit_id (外键 → pbl_units.id，可选，关联学习单元)
  ├── task_id (外键 → pbl_tasks.id，可选，关联任务)
  ├── messages (JSON数组，对话消息列表)
  └── created_at, updated_at

pbl_learning_logs (PBL学习日志表)
  ├── id (主键)
  ├── user_id (外键 → aiot_core_users.id)
  ├── resource_id (外键 → pbl_resources.id)
  ├── action_type (操作类型：view/complete/download)
  ├── duration (学习时长，秒)
  ├── progress (进度，0-100，用于视频播放进度)
  └── created_at

pbl_achievements (PBL成就表)
  ├── id (主键)
  ├── uuid (UUID，唯一标识)
  ├── name (成就名称)
  ├── description (成就描述)
  ├── icon (图标URL)
  ├── condition (JSON，解锁条件)
  └── created_at, updated_at

pbl_user_achievements (PBL用户成就关联表)
  ├── id (主键)
  ├── user_id (外键 → aiot_core_users.id)
  ├── achievement_id (外键 → pbl_achievements.id)
  ├── unlocked_at (解锁时间)
  └── created_at
```

### 5.3 数据字典

#### 5.3.1 复用表说明

**`aiot_core_users`** - 用户信息表（复用）
- PBL 系统直接使用，通过 `role` 字段区分学生/教师/管理员
- 通过 `class_id` 关联班级，通过 `group_id` 关联小组

**`aiot_schools`** - 学校信息表（复用）
- PBL 系统直接使用，用于多租户数据隔离

**`aiot_classes`** - 班级信息表（复用）
- PBL 系统直接使用，学生通过 `class_id` 关联班级

**`aiot_course_groups`** - 课程小组表（复用，作为项目团队）
- PBL 系统直接使用，作为项目团队的基础
- 通过 `course_id` 关联课程（在 PBL 中关联 `pbl_courses`）

**`aiot_group_members`** - 小组成员表（复用）
- PBL 系统直接使用，管理团队成员

#### 5.3.2 PBL 核心表结构

**`pbl_courses`** - PBL 课程表

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT | 课程ID | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | UUID，唯一标识 | UNIQUE, NOT NULL |
| title | VARCHAR(200) | 课程标题 | NOT NULL |
| description | TEXT | 课程描述 | |
| cover_image | VARCHAR(255) | 封面图URL | |
| duration | VARCHAR(50) | 时长 | 如"8周" |
| difficulty | ENUM | 难度 | 'beginner', 'intermediate', 'advanced' |
| status | ENUM | 状态 | 'draft', 'published', 'archived' |
| creator_id | INT | 创建者ID | FOREIGN KEY → aiot_core_users.id |
| school_id | INT | 所属学校ID | FOREIGN KEY → aiot_schools.id |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | ON UPDATE CURRENT_TIMESTAMP |

**`pbl_units`** - PBL 单元表

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT | 单元ID | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | UUID，唯一标识 | UNIQUE, NOT NULL |
| course_id | BIGINT | 课程ID | FOREIGN KEY → pbl_courses.id, NOT NULL |
| title | VARCHAR(200) | 单元标题 | NOT NULL |
| description | TEXT | 单元描述 | |
| order | INT | 顺序 | NOT NULL |
| status | ENUM | 状态 | 'locked', 'available', 'completed' |
| learning_guide | JSON | 学习导引配置 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | ON UPDATE CURRENT_TIMESTAMP |

**`pbl_resources`** - PBL 资源表

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT | 资源ID | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | UUID，唯一标识 | UNIQUE, NOT NULL |
| unit_id | BIGINT | 单元ID | FOREIGN KEY → pbl_units.id, NOT NULL |
| type | ENUM | 资源类型 | 'video', 'document', 'link' |
| title | VARCHAR(200) | 资源标题 | NOT NULL |
| description | TEXT | 资源描述 | |
| url | VARCHAR(500) | 资源URL | |
| content | LONGTEXT | 内容（Markdown格式，用于文档） | |
| duration | INT | 时长（分钟，用于视频） | |
| order | INT | 顺序 | |
| video_id | VARCHAR(100) | 阿里云视频ID（仅视频类型） | |
| video_cover_url | VARCHAR(255) | 视频封面图URL（仅视频类型） | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | ON UPDATE CURRENT_TIMESTAMP |

**`pbl_tasks`** - PBL 任务表

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT | 任务ID | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | UUID，唯一标识 | UNIQUE, NOT NULL |
| unit_id | BIGINT | 单元ID | FOREIGN KEY → pbl_units.id, NOT NULL |
| title | VARCHAR(200) | 任务标题 | NOT NULL |
| description | TEXT | 任务描述 | |
| type | ENUM | 任务类型 | 'analysis', 'coding', 'design', 'deployment' |
| difficulty | ENUM | 难度 | 'easy', 'medium', 'hard' |
| estimated_time | VARCHAR(50) | 预计时长 | 如"20分钟" |
| requirements | JSON | 任务要求列表 | |
| prerequisites | JSON | 前置任务ID列表 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | ON UPDATE CURRENT_TIMESTAMP |

**`pbl_projects`** - PBL 项目表

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT | 项目ID | PRIMARY KEY, AUTO_INCREMENT |
| uuid | VARCHAR(36) | UUID，唯一标识 | UNIQUE, NOT NULL |
| group_id | INT | 团队ID（关联课程小组） | FOREIGN KEY → aiot_course_groups.id |
| course_id | BIGINT | 课程ID | FOREIGN KEY → pbl_courses.id |
| title | VARCHAR(200) | 项目标题 | NOT NULL |
| description | TEXT | 项目描述 | |
| status | ENUM | 状态 | 'planning', 'in-progress', 'review', 'completed' |
| progress | INT | 进度 | 0-100 |
| repo_url | VARCHAR(500) | 代码仓库URL | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | ON UPDATE CURRENT_TIMESTAMP |

**`pbl_task_progress`** - PBL 任务进度表

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | BIGINT | 进度ID | PRIMARY KEY, AUTO_INCREMENT |
| task_id | BIGINT | 任务ID | FOREIGN KEY → pbl_tasks.id, NOT NULL |
| user_id | INT | 用户ID | FOREIGN KEY → aiot_core_users.id, NOT NULL |
| status | ENUM | 状态 | 'pending', 'in-progress', 'blocked', 'review', 'completed' |
| progress | INT | 进度 | 0-100 |
| submission | JSON | 提交内容 | |
| score | INT | 分数 | 0-100 |
| feedback | TEXT | 评语 | |
| graded_by | INT | 批改人ID | FOREIGN KEY → aiot_core_users.id |
| graded_at | TIMESTAMP | 批改时间 | |
| created_at | TIMESTAMP | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | 更新时间 | ON UPDATE CURRENT_TIMESTAMP |
| UNIQUE KEY | (task_id, user_id) | 任务-用户唯一索引 | |

### 5.4 视频服务集成

#### 5.4.1 阿里云视频点播服务 (VOD)

**服务说明**：
- PBL 平台使用阿里云视频点播服务（VOD）存储和管理所有学习视频
- 支持视频上传、转码、播放、加密等完整功能

**核心功能**：
1. **视频上传**：
   - 教师端上传视频文件到阿里云 OSS
   - 自动触发 VOD 转码任务
   - 生成多种清晰度（标清 480p、高清 720p、超清 1080p）
   - 自动生成视频封面图

2. **视频存储**：
   - 视频文件存储在阿里云 OSS
   - 视频元数据存储在 `pbl_resources` 表
   - `video_id` 字段存储阿里云视频 ID
   - `video_cover_url` 字段存储封面图 URL

3. **视频播放**：
   - 前端使用阿里云播放器 SDK（Aliplayer）
   - 支持 HLS、DASH 等流媒体协议
   - 支持清晰度切换、倍速播放、字幕等功能
   - 支持播放进度记录和断点续播

4. **视频安全**：
   - 支持视频加密（HLS 加密）
   - 支持防盗链（Referer 白名单、时间戳签名）
   - 支持播放权限控制（仅登录用户可播放）

**API 集成**：
- 使用阿里云 VOD SDK 进行视频上传和管理
- 使用阿里云播放器 SDK 进行视频播放
- 视频播放地址通过后端 API 获取（带签名，防止直接访问）

### 5.5 数据同步机制

#### 5.3.1 本地存储 (LocalStorage)

**用途**：
- 存储用户 Token（访问令牌、刷新令牌）
- 存储任务进度（临时保存，防止数据丢失）
- 存储用户偏好设置（主题、语言等）

**同步策略**：
- 任务进度变更时立即保存到本地存储
- 页面加载时从本地存储恢复任务进度
- 网络恢复后自动同步到服务器

#### 5.3.2 服务器同步

**同步时机**：
- 任务状态变更时
- 视频播放进度更新时（每 30 秒）
- 文档阅读时长更新时（每 60 秒）
- 用户主动触发同步

**冲突处理**：
- 采用"最后写入获胜"策略
- 如果服务器数据更新，则覆盖本地数据

---

## 6. API 接口设计

### 6.1 接口规范

#### 6.1.1 基础规范

- **协议**：HTTPS
- **数据格式**：JSON
- **字符编码**：UTF-8
- **API 版本**：v1
- **基础路径**：`/api/v1`

#### 6.1.2 认证方式

- **JWT Token**：在请求头中携带 `Authorization: Bearer <token>`
- **Token 刷新**：使用 Refresh Token 刷新 Access Token
- **Token 过期**：返回 401，前端自动跳转到登录页

#### 6.1.3 响应格式

**成功响应**：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    // 响应数据
  }
}
```

**错误响应**：
```json
{
  "code": 400,
  "message": "错误描述",
  "error": {
    "type": "ValidationError",
    "details": [
      {
        "field": "username",
        "message": "用户名不能为空"
      }
    ]
  }
}
```

### 6.2 核心接口列表

#### 6.2.1 认证接口 (Auth)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/auth/login` | 用户登录 | `{username, password}` | `{access_token, refresh_token, user}` |
| POST | `/auth/student-login` | 学生学号登录 | `{student_id, school_code, password}` | `{access_token, refresh_token, user}` |
| POST | `/auth/refresh` | 刷新Token | `{refresh_token}` | `{access_token, refresh_token}` |
| POST | `/auth/logout` | 退出登录 | - | `{message}` |
| GET | `/auth/me` | 获取当前用户信息 | - | `{user}` |

#### 6.2.2 课程接口 (Courses)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/courses` | 获取课程列表 | `?page=1&size=20&status=published` | `{courses[], total, page, size}` |
| GET | `/courses/:id` | 获取课程详情 | - | `{course}` |
| GET | `/courses/:id/units` | 获取课程单元列表 | - | `{units[]}` |
| GET | `/courses/:id/progress` | 获取课程学习进度 | - | `{progress, completed_units, total_units}` |

#### 6.2.3 单元接口 (Units)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/units/:id` | 获取单元详情 | - | `{unit}` |
| GET | `/units/:id/resources` | 获取单元资源列表 | - | `{resources[]}` |
| GET | `/units/:id/tasks` | 获取单元任务列表 | - | `{tasks[]}` |
| POST | `/units/:id/unlock` | 解锁单元 | - | `{message}` |

#### 6.2.4 任务接口 (Tasks)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/tasks/:id` | 获取任务详情 | - | `{task}` |
| GET | `/tasks/:id/progress` | 获取任务进度 | - | `{progress}` |
| PUT | `/tasks/:id/progress` | 更新任务进度 | `{status, progress, submission}` | `{progress}` |
| POST | `/tasks/:id/submit` | 提交任务 | `{submission}` | `{message}` |

#### 6.2.5 项目接口 (Projects)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/projects` | 获取项目列表 | `?status=in-progress` | `{projects[]}` |
| GET | `/projects/:id` | 获取项目详情 | - | `{project}` |
| POST | `/projects` | 创建项目 | `{title, description, course_id}` | `{project}` |
| PUT | `/projects/:id` | 更新项目 | `{title, description, status}` | `{project}` |
| GET | `/projects/:id/tasks` | 获取项目任务列表 | - | `{tasks[]}` |
| GET | `/projects/:id/progress` | 获取项目进度 | - | `{progress}` |

#### 6.2.6 团队接口 (Teams)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/teams` | 获取团队列表 | - | `{teams[]}` |
| GET | `/teams/:id` | 获取团队详情 | - | `{team, members[]}` |
| POST | `/teams` | 创建团队 | `{name, project_id}` | `{team}` |
| POST | `/teams/:id/members` | 添加团队成员 | `{user_id}` | `{message}` |
| DELETE | `/teams/:id/members/:user_id` | 移除团队成员 | - | `{message}` |

#### 6.2.7 AI 接口 (AI)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/ai/chat` | AI对话 | `{message, unit_id?, context?}` | `{response}` (流式) |
| GET | `/ai/conversations` | 获取对话历史 | `?unit_id=xxx` | `{conversations[]}` |
| DELETE | `/ai/conversations/:id` | 删除对话记录 | - | `{message}` |


### 6.3 接口示例

#### 6.3.1 学生登录

**请求**：
```http
POST /api/v1/auth/student-login
Content-Type: application/json

{
  "student_id": "20240001",
  "school_code": "SCHOOL001",
  "password": "123456"
}
```

**响应**：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600,
    "user": {
      "id": 1,
      "username": "20240001",
      "full_name": "张三",
      "role": "student",
      "class": {
        "id": 1,
        "name": "五年级2班"
      }
    }
  }
}
```

#### 6.3.2 获取课程单元列表

**请求**：
```http
GET /api/v1/courses/smart-home-agent-system/units
Authorization: Bearer <token>
```

**响应**：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "units": [
      {
        "id": "unit-1",
        "title": "智能体基础与扣子平台入门",
        "description": "学习智能体的基本概念...",
        "order": 1,
        "status": "available",
        "progress": 65
      },
      {
        "id": "unit-2",
        "title": "智能体高级功能",
        "order": 2,
        "status": "locked",
        "progress": 0
      }
    ]
  }
}
```

#### 6.3.3 AI 对话（流式响应）

**请求**：
```http
POST /api/v1/ai/chat
Authorization: Bearer <token>
Content-Type: application/json

{
  "message": "这个单元的重点是什么？",
  "unit_id": "unit-1",
  "context": {
    "current_task": "t1-1",
    "learning_stage": "video-watching"
  }
}
```

**响应**（流式）：
```
data: {"type": "chunk", "content": "这个单元的重点是"}

data: {"type": "chunk", "content": "掌握智能体的"}

data: {"type": "chunk", "content": "基本概念和"}

data: {"type": "chunk", "content": "Coze平台的使用方法。"}

data: {"type": "done", "conversation_id": "conv-123"}
```

---

## 7. 交互与体验设计

### 7.1 设计原则

#### 7.1.1 趣味性 (Gamification)
- **动态效果**：使用动画增强交互反馈（按钮点击、页面切换、进度更新）
- **视觉反馈**：任务完成时的庆祝动画、成就解锁提示
- **进度可视化**：圆形进度环、进度条、学习热力图
- **成就系统**：勋章墙、排行榜（可选，避免过度竞争）

#### 7.1.2 沉浸感 (Immersion)
- **全屏体验**：视频和文档支持全屏模式，减少干扰
- **无缝切换**：视频、文档、任务之间的切换流畅自然
- **上下文保持**：切换页面时保持学习上下文（当前单元、当前任务）

#### 7.1.3 即时反馈 (Instant Feedback)
- **操作反馈**：按钮点击、表单提交立即显示加载状态
- **AI 响应**：AI 对话支持流式输出，模拟真实对话感
- **状态同步**：任务状态变更实时更新到界面
- **消息推送**：系统通知、团队消息实时推送

#### 7.1.4 防作弊机制 (Integrity)
- **视频保护**：
  - 禁用右键菜单
  - 禁用常见下载快捷键
  - 禁用拖拽
  - 可选：禁用快进（确保完整观看）
- **文档保护**：
  - 复制粘贴限制（可选）
  - 阅读时长监测（用于学习分析）
- **任务提交**：
  - 提交时间记录
  - 提交内容版本管理
  - 代码相似度检测（可选）

### 7.2 关键交互流程

#### 7.2.1 开始学习流程

```
用户登录
  ↓
进入学习仪表盘
  ↓
点击"继续学习"或选择项目
  ↓
进入项目详情页
  ↓
点击"开始学习"或选择单元
  ↓
进入单元学习页面（三分屏布局）
  ↓
左侧：选择学习资源（视频/文档/任务）
  ↓
中间：查看任务详情，更新任务状态
  ↓
右侧：与AI助手对话，获取帮助
```

#### 7.2.2 视频学习流程

```
点击视频卡片
  ↓
弹出视频播放模态框
  ↓
自动播放视频
  ↓
记录播放进度（每30秒保存一次）
  ↓
视频播放结束
  ↓
自动标记为"已观看"
  ↓
更新学习进度
```

#### 7.2.3 任务完成流程

```
在任务列表中选择任务
  ↓
查看任务详情和要求
  ↓
点击"开始任务"或手动切换状态为"进行中"
  ↓
完成任务（编写代码、上传文件等）
  ↓
切换状态为"待审核"或"已完成"
  ↓
AI助手发送鼓励消息
  ↓
同步进度到服务器
```

#### 7.2.4 AI 对话流程

```
点击AI助手面板
  ↓
查看欢迎消息和快捷问题
  ↓
输入问题或点击快捷问题
  ↓
发送消息（显示用户消息）
  ↓
AI思考中（显示打字动画）
  ↓
AI回复（流式输出，逐字显示）
  ↓
可以继续对话或导出记录
```

### 7.3 响应式设计

#### 7.3.1 断点定义

- **移动端**：< 768px
- **平板端**：768px - 1024px
- **桌面端**：> 1024px

#### 7.3.2 布局适配

**移动端**：
- 三分屏布局改为单列堆叠
- 视频和文档模态框全屏显示
- 导航栏折叠为汉堡菜单
- 任务卡片简化显示

**平板端**：
- 三分屏布局改为两列（资源+任务，AI助手独立一行）
- 保持大部分桌面端功能

**桌面端**：
- 完整的三分屏布局
- 所有功能完整展示

### 7.4 错误处理与用户提示

#### 7.4.1 错误类型

- **网络错误**：显示"网络连接失败，请检查网络设置"
- **认证错误**：自动跳转到登录页
- **权限错误**：显示"您没有权限执行此操作"
- **数据错误**：显示"数据加载失败，请刷新重试"
- **服务器错误**：显示"服务器错误，请稍后重试"

#### 7.4.2 提示方式

- **成功提示**：绿色 Toast 消息（如"任务状态已更新"）
- **错误提示**：红色 Toast 消息（如"操作失败，请重试"）
- **警告提示**：黄色 Toast 消息（如"您有未保存的更改"）
- **信息提示**：蓝色 Toast 消息（如"新消息已到达"）

---

## 8. 技术与非功能需求

### 8.1 性能指标

#### 8.1.1 页面加载性能

- **首屏加载时间**：< 2 秒（SPA + 路由懒加载）
- **资源加载时间**：< 3 秒（图片、视频懒加载）
- **接口响应时间**：< 1 秒（90% 的请求）

#### 8.1.2 并发性能

- **单班级并发**：支持 50+ 学生同时在线操作
- **视频播放**：支持 20+ 学生同时观看视频（CDN 加速）
- **数据库连接池**：最小 10，最大 100

#### 8.1.3 实时通信性能

- **WebSocket 连接**：支持 100+ 用户同时在线
- **消息推送延迟**：< 200ms

### 8.2 安全性

#### 8.2.1 认证与授权

- **密码加密**：使用 bcrypt 加密存储（成本因子 12）
- **Token 管理**：
  - Access Token 有效期：1 小时
  - Refresh Token 有效期：7 天
  - Token 存储在 HttpOnly Cookie 或内存中（避免 XSS）
- **权限控制**：基于角色的访问控制（RBAC）

#### 8.2.2 数据安全

- **传输加密**：全站 HTTPS（TLS 1.2+）
- **数据加密**：敏感数据（密码、个人信息）加密存储
- **SQL 注入防护**：使用参数化查询
- **XSS 防护**：输入输出转义，CSP 策略
- **CSRF 防护**：使用 CSRF Token

#### 8.2.3 内容安全

- **AI 内容过滤**：AI 对话内容经过敏感受词过滤
- **文件上传安全**：
  - 文件类型白名单
  - 文件大小限制（单个文件 < 10MB）
  - 病毒扫描（可选）

### 8.3 可用性

#### 8.3.1 系统可用性

- **目标可用性**：99.5%（月度）
- **故障恢复时间**：< 30 分钟
- **数据备份**：每日自动备份，保留 30 天

#### 8.3.2 浏览器兼容性

- **Chrome**：80+
- **Firefox**：75+
- **Safari**：13+
- **Edge**：80+

### 8.4 可维护性

#### 8.4.1 代码规范

- **前端**：遵循 Vue 3 官方风格指南
- **后端**：遵循 PEP 8（Python）或 ESLint（Node.js）
- **Git 提交**：使用 Conventional Commits 规范

#### 8.4.2 文档要求

- **API 文档**：使用 Swagger/OpenAPI 生成
- **代码注释**：关键函数和类必须有注释
- **变更日志**：记录每个版本的变更内容

---

## 9. 部署与运维

### 9.1 部署架构

#### 9.1.1 容器化部署

**Docker Compose 配置**：
```yaml
version: '3.8'
services:
  frontend:
    build: ./frontend
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
  
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/pbl
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
  
  db:
    image: postgres:14
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=pbl
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
  
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
```

#### 9.1.2 生产环境部署

**服务器要求**：
- **CPU**：4 核+
- **内存**：8GB+
- **存储**：100GB+ SSD
- **网络**：100Mbps+

**部署步骤**：
1. 克隆代码仓库
2. 配置环境变量（`.env` 文件）
3. 构建 Docker 镜像
4. 启动服务（`docker-compose up -d`）
5. 运行数据库迁移
6. 配置 Nginx 反向代理
7. 配置 SSL 证书（Let's Encrypt）

### 9.2 监控与日志

#### 9.2.1 监控指标

- **系统指标**：CPU、内存、磁盘、网络使用率
- **应用指标**：请求数、响应时间、错误率
- **业务指标**：在线用户数、学习时长、任务完成数

#### 9.2.2 日志管理

- **日志级别**：DEBUG、INFO、WARNING、ERROR
- **日志存储**：文件 + ELK Stack（可选）
- **日志保留**：30 天

### 9.3 备份与恢复

#### 9.3.1 数据备份

- **数据库备份**：每日自动备份，保留 30 天
- **文件备份**：每日增量备份，保留 7 天
- **备份存储**：本地 + 云存储（OSS）

#### 9.3.2 灾难恢复

- **恢复时间目标 (RTO)**：< 4 小时
- **恢复点目标 (RPO)**：< 24 小时
- **恢复流程**：文档化，定期演练

---

## 10. 扩展性设计

### 10.1 功能扩展

#### 10.1.1 多语言支持

- **国际化框架**：Vue I18n
- **支持语言**：中文（简体）、英文（未来）
- **语言切换**：用户设置中切换

#### 10.1.2 小程序支持

- **技术选型**：uni-app 或 Taro
- **功能范围**：查看学习进度、接收通知、简单任务操作

#### 10.1.3 LTI 集成

- **标准支持**：Learning Tools Interoperability (LTI) 1.3
- **应用场景**：与学校现有 LMS（如 Canvas、Blackboard）集成

### 10.2 技术扩展

#### 10.2.1 微服务拆分

当前架构已为微服务做好准备，未来可按需拆分：
- 课程服务独立部署
- AI 服务独立部署（支持横向扩展）
- 项目服务独立部署（支持高并发）

#### 10.2.2 缓存策略

- **Redis 缓存**：
  - 课程列表（TTL: 1 小时）
  - 用户信息（TTL: 30 分钟）
  - 统计数据（TTL: 5 分钟）

#### 10.2.3 CDN 加速

- **静态资源**：图片、视频、文档通过 CDN 分发
- **CDN 提供商**：阿里云 OSS + CDN 或腾讯云 COS + CDN

### 10.3 业务扩展

#### 10.3.1 多租户支持

- **租户隔离**：数据库级别隔离（每个学校独立数据库）或数据级别隔离（tenant_id 字段）
- **配置隔离**：每个租户可自定义 Logo、主题色、功能模块

#### 10.3.2 课程市场

- **课程发布**：教师可发布课程到课程市场
- **课程购买**：学校可购买其他学校或机构开发的课程
- **收益分成**：课程创作者可获得收益分成

---

## 附录

### A. 术语表

- **PBL**：Project-Based Learning，项目式学习
- **RAG**：Retrieval-Augmented Generation，检索增强生成
- **MQTT**：Message Queuing Telemetry Transport，消息队列遥测传输协议
- **JWT**：JSON Web Token，JSON 网络令牌
- **RBAC**：Role-Based Access Control，基于角色的访问控制

### B. 参考资源

- [Vue 3 官方文档](https://vuejs.org/)
- [Element Plus 组件库](https://element-plus.org/)
- [Coze 平台文档](https://www.coze.cn/docs)
- [PBL 教育理论](https://www.pblworks.org/)

### C. 版本历史

| 版本 | 日期 | 作者 | 说明 |
|------|------|------|------|
| v1.0 | 2025-12-05 | 产品团队 | 初始版本 |
| v1.1 | 2025-12-05 | 技术团队 | 补充功能细节 |
| v2.0 | 2025-12-05 | 产品+技术团队 | 完善版，增加 API 设计、部署运维等章节 |
| v2.1 | 2025-12-05 | 产品+技术团队 | 移除 IoT 服务，明确数据库复用 CodeHubot 主系统 |

---

**文档结束**
