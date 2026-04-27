# 事件与 UI 框架速记

## 事件系统

WoW 插件依然是标准的事件驱动模型: 注册事件、收到回调、更新状态、刷新显示。基础思路没变, 但 12.x 更强调“少轮询, 多事件”。

### 建议做法

- 优先用更具体的事件, 不要什么都靠 `OnUpdate`
- 不用的事件及时注销
- 高频事件做节流或批处理
- 如果系统提供按单位过滤的回调或更细粒度事件, 优先用它

### 事件代码组织建议

- 一个入口 frame 统一注册事件
- 事件只负责分发, 不直接堆业务
- 真正逻辑下沉到模块函数
- UI 刷新尽量和数据采集解耦

### DejaVu 事件块硬规则

- 活动事件统一写成“事件用途注释 -> `RegisterEvent` / `RegisterUnitEvent` -> `function eventFrame:事件名()`”
- 注册必须在消费函数前, 不要先写一大段消费函数, 最后再集中注册
- 每条注册语句前都要有用途注释, 直接说明这个事件是干什么的、会刷新什么
- 事件 frame 一律命名为 `eventFrame`
- 单 frame 文件里, `eventFrame` 要放在 `After(2, function()` 后尽快创建
- `DejaVu_Party` 这类循环建 frame 的文件里, `eventFrame` 要放在 `for ... do` 开始后立即创建
- `eventFrame:SetScript("OnEvent", ...)` 必须放在 `After` 容器末尾; 循环建 frame 的情况则放在每次循环末尾
- 只整理事件结构时, 不顺手改事件业务逻辑

### 单 frame 模式

- 适用于一个文件只建一个事件 frame 的情况
- 推荐直接参考 `DejaVu/DejaVu_Spell/Charge.lua` 和 `DejaVu/DejaVu_Spell/Cooldown.lua`
- 先建 `eventFrame`, 再建 cell / controller / updater, 然后按事件块顺序写注册和消费, 最后放事件路由器

### 队友循环模式

- 适用于 `DejaVu_Party` 里 `for partyIndex = 1, 4 do` 这种每个槽位各建一个事件 frame 的情况
- 进入循环后先建 `eventFrame`, 再准备 `UNIT_KEY`、坐标、controller、cell 等局部状态
- 每个槽位自己的事件块都要独立满足“注释 -> 注册 -> 消费”顺序
- `HookScript("OnUpdate", ...)` 等循环内逻辑写完后, 最后再放该槽位的 `OnEvent` 路由器

## UI 框架重点

### 1. 继续尊重模板和层级

本地资料里反复强调的几个点:

- 模板继承要清楚
- `parentKey` 比滥用全局命名更稳
- Mixin 适合做组合, 不要把所有东西塞一个巨表里
- 数据和显示分层, 别让控件自己变成业务数据库

### 2. 现代控件优先

新代码优先考虑:

- Layout Frame
- ScrollBox
- Frame Pooling
- Data Provider
- Blizzard Settings 体系

只有在必须兼容旧写法时, 再回头用老方案。

### 3. Secret-aware UI

12.x 写 UI 最大的变化是: **很多值你能显示, 但不一定能在 Lua 里先算再显示。**

所以要优先采用:

- 原生状态条
- 原生冷却控件
- 让引擎自己处理 duration / curve
- 直接显示, 而不是先加工

## 常见 UI 组织方式

### Frame / Widget 层

- 容器 Frame 负责布局
- 具体 Widget 负责显示
- 复杂列表用池化复用
- 只在必要时才创建新对象

### Mixin 层

- 放通用行为: 初始化、刷新、选中态、提示、绑定数据
- 避免把模块状态散落到匿名闭包里

### 数据层

- UI 不直接信任原始 API 返回值
- 先做一层“可显示数据”整理
- 如果是 secret 风险数据, 尽量只保留可直接透传的形态

## 事件和 UI 的组合建议

- 事件只改模型或缓存
- 刷新统一收口到 `Refresh` / `Update` 这一层
- 高频变化用脏标记, 而不是每次全量重画
- 遇到复杂列表, 优先做增量刷新

## 推荐的更新分层经验

推荐把刷新拆成三层:

- 事件更新: 列表变化、技能变化、最大值变化
- 标准频率更新: 冷却进度、施法进度、Aura 剩余时间
- 低频更新: 职业、角色、距离、已知状态

DejaVu 也应该尽量按这个思路拆, 避免一个刷新函数包打天下。

## 对 DejaVu 的具体提醒

- `DejaVu_Matrix` 以及 `DejaVu_Player` / `DejaVu_Party` / `DejaVu_Enemy` / `DejaVu_Spell` / `DejaVu_Aura` 里的显示逻辑, 尽量不要自己做秘密值计算
- `DejaVu_Panel` 更适合放设置与开关, 不要塞战斗决策
- 当前专精目录放在职业模块下, 例如 `DejaVu_DeathKnight/Blood`、`DejaVu_Druid/Guardian`、`DejaVu_Druid/Restoration`、`DejaVu_Priest/Discipline`; 这些目录更适合做职业专精接线层, 不适合埋很深的 UI 细节
