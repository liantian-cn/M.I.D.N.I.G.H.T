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

### DejaVu

1. 安装DejaVu到游戏的插件路径。
2. 自定义字体可能需要游戏内`/reload`一次生效。
3. 由于技能书的bug，建议每次进入副本都`/reload`一次。

### Terminal

#### 依赖环境安装

如果你能看到github这个说明，我默认你有能力下载到下面的所有东西。

- 安装并下载python 3.12。 [官网](https://www.python.org/downloads/release/python-31210/)
- 安装uv。[官网](https://github.com/astral-sh/uv)
- 安装vscode。[官网](https://code.visualstudio.com/)
- 使用vscode打开`Terminal`目录。
- Ctrl + Shift + ` 打开终端。
- `uv sync`完成依赖安装。
- 执行`clear ; uv run .\main.py`运行程序。


## 基础逻辑

1. 游戏的屏幕右上角，会有一个`DejaVu`插件绘制的`M.A.T.R.I.X区域`。区域内由4x4和8x8的像素区域构成。
2. `Terminal`会读取这个区域。
3. 游戏逻辑由`Terminal`解析并执行。
4. `DejaVu`负责按键绑定。
5. `DejaVu`提供了一套完整的设置逻辑，游戏内设置菜单的设置结果会映射到`M.A.T.R.I.X区域`。

## 进阶逻辑

访问[repo wiki](https://github.com/liantian-cn/M.I.D.N.I.G.H.T/wiki)会缓慢更新。

## 意见建议

访问[repo discussions](https://github.com/liantian-cn/M.I.D.N.I.G.H.T/discussions)

## 当前repo专精支持情况

- **血DK** 比较OK，可以用在13层及以下的大米，需要自行开冰刃和吸血鬼、符文剑简易手动开或爆发模式。
- **熊德**：相对OK，可以用在13层及以下的大米，需要自行提前开爆发、本能。
- **奶德**：制作中。

### 爆发宏
```
/burst x.x
```
在x.x秒内处于爆发状态。
血DK的符文剑会开启。熊的化身会开启。奶德会预铺5人双回春。

### 延迟宏
```
/delay x.x
```
在x.x秒内处于暂停状态。
0.4秒就可以有效插入技能了。

   

