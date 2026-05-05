# M.I.D.N.I.G.H.T

Private Matrix of Infinite Death Nightfall Iteration Generation Host Terminal

- 这个repo是`DejaVu`和`Terminal`两个模块的整合。维持MIT开源。`AGENTS.md`、`.vscode`等和项目本身无关的文件，做了删除。

## 基本介绍

本项目是[EZWowX2](https://github.com/liantian-cn/EZWowX2)项目的后续新坑，有诸多优势。

- 作者还在维护、更多的手写代码：为了去掉AI屎山，本项目代码手写量>95%，作者维护意愿更强。
- 使用兼容性更好的GDI截图：优化了算法，在Ryzen 9700X下能实现100fps。性能测试见`notes`目录。
- 游戏内设置：动态变量设置由游戏内插件完成。
- 循环热加载：在ide里编辑代码，保存后，rotation会自动重载。

## 截图

### DejaVu

![DejaVu.png](https://github.com/user-attachments/assets/23188976-473f-48fc-9b74-72ce0002f29f)

### Terminal

![Terminal.png](https://github.com/user-attachments/assets/a6bb4d44-ac5f-4af1-b51d-a0ccbea0f89b)

## 意见建议

[Discord](https://discord.gg/9z7Ubbabpg)

## 本repo提供的专精

这些专精是我玩的专精，对应的循环和插件设置端已经写好。
目前是3000分毕业的休闲玩家。血DK和熊应该都可以完成这个任务。

### 血DK

- 完成度：`99%`
- 需要手动开符文剑、吸血鬼、冰刃。符文剑使用/delay 宏

### 熊

- 完成度：`95%`
- 化身手动开。选保持一层铁鬃
- 差5%是因为没适配5.7号的更新。

### 奶德

- 完成度：`90%`
- 化身手动开。选保持一层铁鬃
- 差5%是因为没适配5.7号的更新。

### 戒律牧

- 完成度：`100%`
- 天赋：`CAQA4VPTJ8eQb8/qEm8PyGu4yADsYYWmZMmZmhZbGzMzYMzAAAAAAAAAAYMzyMYmZGmxMjBTzEDwMLYIMmlBYMYBAAGzMGDmBYmxEM`
- 终极苦修宏

```ini
#showtooltip 终极苦修
/cast [@player,nochanneling] 终极苦修
/delay 2

```

- 福音宏

```ini
#showtooltip 福音
/cast [@player,nochanneling]  福音
/delay 1
```

戒律牧目前足够一周到3400，纯集合石上分。

![戒律.png](https://github.com/user-attachments/assets/18f08227-ce39-4ea7-a176-b38fbde6d299)

## 开发属于自己的循环

1. 插件端参考 `DejaVu\DejaVu_DruidRestoration`、`DejaVu\DejaVu_DruidGuardian`、`DejaVu\DejaVu_DeathKnightBlood`，在游戏内枚举需要检测的技能、充能技能。再SPEC区域增加需要检测的特色职业属性。添加宏绑定。增加设置项。
2. Python端参考`Terminal\terminal\rotation`
3. 使用AI编程工具，使用Skill 'write_rotation'
4. 当前repo使用`codex`开发。`AGENTS.md`和相关设置及上下文，在`codex`中确定生效。

## 全局配置

### 爆发宏

```lua
/burst x.x
```

在x.x秒内处于爆发状态。
血DK的符文剑会开启。熊的化身会开启。奶德会预铺5人双回春。

### 延迟宏

```lua
/delay x.x
```

在x.x秒内处于暂停状态。
0.4秒就可以有效插入技能了。

### 打断黑名单

T不断小条

```text
1254669
1258436
1248327
1262510
468962
1262526
```

节点尾王： `1257613`
熊不断执政老2：`248831`

## 排错思路

1. 先备份Interface和WTF目录，然后清空。
2. 进入游戏，输入 /console cvar_default
3. 安装插件
4. 进入游戏后，输入/dump GetScreenHeight()
5. 1080p下应该显示768、440p和2160p下，应该显示1200。
6. 右键桌面属性，关闭HDR。

## 版权

### 本项目基于MIT协议

- 允许任意分发、改造、重命名、转卖，都不介意。

### 但

有条件的、有能力的用户，应该开源版本。

- 使用官网python是最安全的。
- 当前项目会检测是否使用官网python,逻辑在`Terminal\terminal\__init__.py`
- 项目提供AGENTS.md和`.context`上下文，AI开发很方便。

## 安装

- 下载[QClaw](https://qclaw.qq.com/)
- 发送指令`请根据 https://github.com/liantian-cn/M.I.D.N.I.G.H.T/blob/main/INSTALL.md 为我安装MIDNIGHT`
