# 前端Token刷新调用说明

## 概述

后端已优化token刷新机制，现在token中包含了用户类型信息（`user_role`），确保刷新操作的安全性。前端无需修改现有的token存储和发送逻辑，但需要注意正确调用对应的刷新接口。

## 刷新接口

### 管理员Token刷新

**接口地址**：`POST /api/admin/auth/refresh`

**适用于**：
- 平台管理员（platform_admin）
- 学校管理员（school_admin）
- 教师（teacher）

**请求示例**：
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**成功响应**：
```json
{
  "code": 200,
  "message": "令牌刷新成功",
  "data": {
    "access_token": "新的access_token",
    "refresh_token": "新的refresh_token",
    "token_type": "bearer"
  }
}
```

### 学生Token刷新

**接口地址**：`POST /api/student/auth/refresh`

**适用于**：
- 学生（student）

**请求示例**：
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**成功响应**：
```json
{
  "code": 200,
  "message": "令牌刷新成功",
  "data": {
    "access_token": "新的access_token",
    "refresh_token": "新的refresh_token",
    "token_type": "bearer"
  }
}
```

## 前端实现建议

### 1. 区分用户类型

在用户登录时，前端应该记住用户类型（从登录响应中获取），以便知道应该调用哪个刷新接口：

```javascript
// 登录时保存用户类型
const loginResponse = await api.login(credentials);
localStorage.setItem('access_token', loginResponse.data.access_token);
localStorage.setItem('refresh_token', loginResponse.data.refresh_token);
localStorage.setItem('user_role', loginResponse.data.user.role || loginResponse.data.admin.role);
```

### 2. 根据用户类型调用对应的刷新接口

```javascript
async function refreshToken() {
  const refreshToken = localStorage.getItem('refresh_token');
  const userRole = localStorage.getItem('user_role');
  
  // 根据用户角色选择刷新接口
  let refreshUrl;
  if (['platform_admin', 'school_admin', 'teacher'].includes(userRole)) {
    refreshUrl = '/api/admin/auth/refresh';
  } else if (userRole === 'student') {
    refreshUrl = '/api/student/auth/refresh';
  } else {
    throw new Error('未知的用户类型');
  }
  
  try {
    const response = await fetch(refreshUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ refresh_token: refreshToken })
    });
    
    const result = await response.json();
    
    if (result.code === 200) {
      // 保存新的token
      localStorage.setItem('access_token', result.data.access_token);
      localStorage.setItem('refresh_token', result.data.refresh_token);
      return result.data.access_token;
    } else {
      // 刷新失败，跳转到登录页
      handleTokenRefreshError();
      return null;
    }
  } catch (error) {
    console.error('Token刷新失败:', error);
    handleTokenRefreshError();
    return null;
  }
}

function handleTokenRefreshError() {
  // 清除本地存储
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  localStorage.removeItem('user_role');
  
  // 跳转到登录页
  window.location.href = '/login';
}
```

### 3. 拦截器自动刷新（推荐）

使用axios拦截器自动处理token刷新：

```javascript
// axios请求拦截器
axios.interceptors.request.use(
  config => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  error => {
    return Promise.reject(error);
  }
);

// axios响应拦截器
axios.interceptors.response.use(
  response => response,
  async error => {
    const originalRequest = error.config;
    
    // 如果是401错误且还没有重试过
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const newAccessToken = await refreshToken();
        if (newAccessToken) {
          // 使用新token重试原始请求
          originalRequest.headers['Authorization'] = `Bearer ${newAccessToken}`;
          return axios(originalRequest);
        }
      } catch (refreshError) {
        // 刷新失败，清除token并跳转登录
        handleTokenRefreshError();
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);
```

## 错误处理

### 可能的错误响应

1. **无效的刷新令牌或已过期**
```json
{
  "code": 401,
  "message": "无效的刷新令牌或已过期"
}
```

2. **无效的用户类型**（使用了错误的刷新接口）
```json
{
  "code": 401,
  "message": "无效的用户类型"
}
```

3. **用户角色不匹配**
```json
{
  "code": 401,
  "message": "用户角色不匹配"
}
```

4. **账户已被禁用**
```json
{
  "code": 403,
  "message": "账户已被禁用"
}
```

### 错误处理建议

- **401错误**：清除本地token，跳转到登录页
- **403错误**：显示账户已被禁用的提示，跳转到登录页
- **网络错误**：提示用户检查网络连接

## 迁移指南

### 旧版本token处理

如果用户使用的是旧版本的token（不包含`user_role`字段），刷新时会失败。前端应该：

1. 捕获刷新失败的错误
2. 清除本地存储的token
3. 引导用户重新登录

```javascript
async function refreshToken() {
  // ... 刷新逻辑 ...
  
  if (!response.ok) {
    // 刷新失败，可能是旧token，清除并重新登录
    console.log('Token刷新失败，请重新登录');
    handleTokenRefreshError();
    return null;
  }
  
  // ... 后续处理 ...
}
```

## 测试建议

1. 测试管理员用户的token刷新
2. 测试学生用户的token刷新
3. 测试使用错误接口刷新token（应该失败）
4. 测试access token过期后自动刷新
5. 测试refresh token过期后的处理
6. 测试网络错误时的降级处理

## 注意事项

1. **保持用户类型信息**：前端需要持久化保存用户类型信息（如存储在localStorage），以便知道应该调用哪个刷新接口
2. **及时更新token**：刷新成功后，要同时更新access_token和refresh_token
3. **安全存储**：token应该安全存储，避免XSS攻击
4. **防止并发刷新**：如果多个请求同时触发刷新，应该使用锁机制避免重复刷新
