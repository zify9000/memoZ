# memoZ

面向 AI agent 的项目记忆文档结构：为项目搭建一套对抗上下文重置的长期记忆体系，初始化时拉出框架，开发过程中由 agent 伴随维护。

## 解决的问题

AI agent 的上下文会被压缩和重置，磁盘文档是它唯一的长期记忆。本 skill 在项目中建立七个各司其职的文件，构成一条完整的追问链：

**要做什么产品（SOUL）→ 产品长什么样（design）→ 为什么是这个样子（decision）→ 产品的内部细节（impl）→ 骨架是什么（ARCHITECTURE）→ 现在进行到哪（PROGRESS）→ 怎么维护这套体系（AGENTS）**

```
.memoZ/           # 项目记忆层：六个文件收敛在这一个点目录里
  SOUL.md        # 要做什么产品（最稳定，人写，项目的定位与初心）
  design/        # 产品长什么样（按架构/功能组织的设计文档，活文档、原地更新）
  decision/      # 为什么是这个样子（ADR 决策记录，agent 起草、人核对）
    INDEX.md     # 决策索引，冷启动先读它
    archive/     # 被合并取代的旧 ADR（冷存储）
  impl/          # 产品的内部细节（模块级实现说明）
  ARCHITECTURE.md  # 骨架（一页地图）
  PROGRESS.md    # 进行到哪一步（每次任务收口更新）
AGENTS.md        # "项目记忆体系"章节，由 sync 脚本机械写入（留在项目根）
```

核心原则：**稳定的、代码推不出来的信息才值得写成文档；代码能回答的问题，让 agent 去问代码。**

## 仓库结构

```
SKILL.md                        # 完整方法论（模板、流程、体检流程、反模式）
references/agents-chapter.md    # AGENTS.md 章节的标准副本（唯一事实源，含版本号）
scripts/sync.sh                 # 章节安装/同步/校验脚本（Linux / macOS）
scripts/sync.ps1                # 同上，Windows PowerShell 版
scripts/check.sh                # .memoZ/ 内容层机器校验（Linux / macOS）
scripts/check.ps1               # 同上，Windows PowerShell 版
```
