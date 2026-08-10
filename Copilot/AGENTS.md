# Copilot 工作指引

## 基本要求

- 永远不要读取、检查或编辑 `prompt.md` 的内容，也不要在意它的工作区状态；如果它已有修改，提交其他实施文件时必须将该修改原样一并提交。
- `AGENTS.md` 只存放智能体工作流程规则。产品与技术事实必须写入 `.context`。
- 每次工作前必须先阅读 [`.context/README.md`](.context/README.md)，再按其中规定的顺序读取与任务有关的规格文档。
- 涉及解码器实现或 review 时，必须同时读取 `PhantomProject` 当时的当前源码，以其源码核对上游定义。
- 不得把从 `PhantomProject` 当前源码查得的易变布局值、业务字段清单或协议细节复制为本仓库的固定规则；仅可在实现适配器时使用，并保持 `.context` 所定义的本地契约稳定。
- 发现 `.context` 与上游当前源码不一致时，不得自行改写产品决定；应停止相关实施并报告冲突，等待规格更新。
- 当用户的明确指令和 `.context`不一致时，询问用户，当用户确认后，把修改 `.context`加入计划。


## references 目录

- `references\PhantomProject`：当前项目的插件端、编码端、前端。
- `references\Terminal`：当前项目的上代产品。
- `references` 目录只读，需要经常更新到最新版本。
