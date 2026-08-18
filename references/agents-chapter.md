<!-- memoZ:start v9 -->
## 项目记忆体系

项目记忆集中在 `.memoZ/`（SOUL / design / decision / impl / ARCHITECTURE / PROGRESS），AGENTS.md 是唯一留在项目根的文件。注意：`.memoZ` 是点目录，全局搜索时需带上隐藏文件（如 `rg --hidden`）。

### 冷启动阅读顺序
1. `.memoZ/SOUL.md`（要做什么产品、边界在哪）
2. `.memoZ/ARCHITECTURE.md`（骨架地图）
3. `.memoZ/PROGRESS.md`（进行到哪一步）
4. `.memoZ/design/`（产品长什么样，按需打开对应主题的设计文档）
5. `.memoZ/decision/INDEX.md`（当初怎么拍板的，按需打开具体 ADR）
6. 涉及改动时读对应的 `.memoZ/impl/` 条目
（`.memoZ/decision/archive/` 是冷存储，除非翻历史否则不读。文档与代码冲突时以代码为准，发现漂移随手修正对应条目。）

### 文档维护规则
均为事件触发：时机一出现就执行，不攒、不等"会话结束"（agent 感知不到那个时刻）。按组件分述；当场漏掉的，由最后的收口回看兜底。

**`.memoZ/PROGRESS.md`（每次任务收口，必做）**
- 准备向用户汇报完成前 → 覆写刷新快照：保留未解决坑、摘除已完成已提交项、未合并项标"待合并"

**`.memoZ/impl/`（改代码时伴随）**
- 改了某代码模块的职责/接口/数据流 → 同步更新 `.memoZ/impl/<module>.md`

**`.memoZ/design/`（设计定了或变了，最易漏）**
- 抽象层的设计定了或变了 → 原地更新 `.memoZ/design/<主题>.md`（活文档只留当前有效设计，不留历史；为什么这么定的历史在 `.memoZ/decision/`）
- 归属判据：模块重划、目录重构后仍成立的进 design/；跟着模块分工失效重写的进 impl/

**`.memoZ/decision/`（对话中捕捉，最易漏）**
- 对话中出现拍板时刻（"就用 X 吧""这个不做了""A 和 B 选定 A"、推翻之前的做法）→ 当场起草 ADR（状态"草稿（待核对）"）请用户核对，通过后改"已采纳"并登记 `.memoZ/decision/INDEX.md`
- 新决策取代旧决策 → 旧 ADR 状态改为"已被 ADR-XXXX 取代"，更新索引
- ADR 主题从 `.memoZ/decision/INDEX.md` 主题词表中选一个；登记新主题前先扫词表找近义，复用优先
- 合并触发条件满足（同主题 ≥3 条取代链 / 总数 >20 / 里程碑节点）→ 执行合并归档

**`.memoZ/ARCHITECTURE.md`（结构变化时，最易漏）**
- 新增/删除目录、改了程序/构建/测试入口 → 同步更新（保持一页以内）

**`.memoZ/SOUL.md`（罕见，改了就是大事）**
- 产品定位、目标用户或边界变化 → 更新 `.memoZ/SOUL.md`
- 拿不准一个特性该不该做 → 对照 `.memoZ/SOUL.md` 的边界，对不上就先问

**收口回看（每次任务收口时执行，专兜上面的易漏项）**
- 先拿证据，不凭记忆：`git status` + `git diff --name-only` 拿到本次改动的实际文件清单（本任务中已提交的部分看 `git show --name-only`）——压缩之后"记得改了什么"不可靠，以 git 为准
- 对照清单逐条问：拍板了没起草 ADR？设计变了没原地更新 design/？建了目录/改了入口没同步 ARCHITECTURE.md？改了模块没同步 impl/？漏了当场补上
- 顺带一项：`.memoZ/.last-audit` 超过 30 天或不存在 → 建议用户做一次记忆体检（不自动跑）

不确定的信息不要写进文档，宁可留空；行号、计数这类一次改动就过期的值不要写（写接口名，不写"文件:行"）。
<!-- memoZ:end -->
