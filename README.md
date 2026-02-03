# TokenTracker

一个 iOS 应用，用于监控多个 AI 提供方的用量与趋势，支持模块化扩展。

## 功能概览
- **开始页**：提供两个入口
  - Token 用量监控（已实现）
  - Docker 监控（占位，待实现）
- **用量监控**：总消耗折线图 + 各模型卡片 + 详情页
- **设置页**：添加/管理 API 配置（带真实验证）
- **数据留存**：每 60 秒记录一次，保存 7 天

## 运行环境
- iOS 14+
- Xcode（建议 14+）

## 如何运行
1. 打开 `TokenTracker.xcodeproj`
2. 选择模拟器或真机
3. `Cmd + R` 运行

## 配置说明
在「设置」页添加并保存配置，验证通过后首页会同步展示数据。

### DeepSeek
- 填写 `API Key`
- 通过 `GET /user/balance` 获取余额

### OpenAI
- 需要 **Admin API Key**
- 使用组织级 Usage 接口获取用量

### Qwen
- 使用监控接口（Prometheus HTTP API）
- 需要填写：
  - `AccessKey`
  - `AccessKeySecret`
  - `Monitoring API Base URL`

### Zhipu
- 暂未接入 usage 接口

## 数据与安全
- API Key 存储在 **Keychain**
- 预算等配置存储在 **UserDefaults**
- 用量历史存储在 **Application Support** 下的 JSON 文件

## 目录结构
- `TokenTracker/Views`：界面层
- `TokenTracker/ViewModels`：状态与业务逻辑
- `TokenTracker/Services`：API 调用、存储、配置
- `TokenTracker/Models`：数据模型

## 计划中的功能
- Docker 监控模块接入
- 更多提供方用量接口支持
