# Mission Book

Mission Book 是一个以人的长期成长为核心的 AI 辅助规划、执行、验证与反思系统。

仓库处于重新实现阶段：既有示例代码已清理，`lib/` 回到 Flutter 模板入口。产品与领域规格已经定稿，见 [docs/README.md](docs/README.md)。

## 核心闭环

```text
创建 Goal / 导入 GoalNode 大纲
→ 手动创建 Mission
→ Today
→ Start / Pause / Resume / Extend / End
→ Evidence Draft → Finalize Formal Evidence
→ Result（智能评价暂未接入，不显示模拟结果）
```

## 运行

```powershell
flutter run -d windows
```

或运行其他已经配置好的 Flutter 设备：

```powershell
flutter devices
flutter run -d <device-id>
```

## 文档

学习式开发从 [开发执行计划](docs/开发执行计划.md) 开始；它把完整规格拆成可以逐步实现和验收的小阶段。

| 文档 | 内容 |
|---|---|
| [索引](docs/v1.0/索引.md) | 阅读顺序与文档约定 |
| [产品纲领](docs/v1.0/产品纲领.md) | 为什么做 |
| [领域模型](docs/v1.0/领域模型.md) | 术语与生命周期（术语唯一来源） |
| [数据模型](docs/v1.0/数据模型.md) | 要保存的事实 |
| [本地应用规格](docs/v1.0/本地应用规格.md) | 这一版做什么 |
| [界面与交互](docs/v1.0/界面与交互.md) | 页面与交互链 |
| [数据落地与平台](docs/v1.0/数据落地与平台.md) | 存储、导入协议与平台约束 |
| [未来方向](docs/v1.0/未来方向.md) | 当前不实现的能力 |

外部 AI 可以按《数据落地与平台》中的 Goal Outline 协议生成大纲，用户预览确认后导入；JSON 不是运行时业务数据源。

界面视觉与布局以 [docs/ui设计手册/](docs/ui设计手册/) 的设计稿为准。
