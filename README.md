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

## 安装

- 下载[QClaw](https://qclaw.qq.com/)
- 发送指令`请根据 https://github.com/liantian-cn/M.I.D.N.I.G.H.T/blob/main/INSTALL.md 为我安装MIDNIGHT`

## 进阶逻辑

访问[repo wiki](https://github.com/liantian-cn/M.I.D.N.I.G.H.T/wiki)会缓慢更新。

## 意见建议

[Discord](https://discord.gg/9z7Ubbabpg)

## 本repo提供的专精

这些专精是我玩的专精，对应的循环和插件设置端已经写好。
我说3000分毕业的休闲玩家。

| 专精 | 完成度 | 说明 | 天赋 |
| --- | --- | --- | --- |
| 血DK | 99% <br/> 网易大神统计dps在85%+ | 大号274、3100分 <br/> 需要手动开符文剑、吸血鬼、冰刃。符文剑使用/delay 宏。| 死亡使者、无吞噬 |
| 熊 | 99% <br/> 网易大神统计dps在85%+ | 中号272，2800分，<br/>化身手动开。<br/>选保持一层铁鬃 | 利爪 |
| 奶德 | 90% | 小号268，集合石只混10C次数。 | 猫奶 |

- 目前熊T和血DK还是下水道难兄难弟，还是需要有点副本理解才能玩的。
- 减伤要预判提前开才有意义，虽然脚本帮你开树皮，但是脚本帮你开就离死不远了。

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

```
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
