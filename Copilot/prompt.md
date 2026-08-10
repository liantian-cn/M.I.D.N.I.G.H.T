现在要开始开发Copilot，第3.0阶段，实现HTTP输出。


本次任务：
- 不涉及解码部分
- 涉及增强GUI部分
- 主要涉及HTTP部分


## 先定义src目录下的结构

类似Terminal

main.py -- 入口
copilot/ -- 程序包
copilot/application.py -- 程序构造文件，类似@Terminal / terminal/application.py
copilot/ui/ -- ui目录，本次改善
copilot/capture/ -- 截图相关的目录
copilot/workers/ -- worker实现
copilot/decoder/ -- 解码图片，对应Terminal的pixelcalc目录，本次不改变。
copilot/httpd/ -- 对外接口，本次负责实现。

整体而言，和@Terminal相似。

## 项目整体逻辑

### 项目包含3个进程

主线程 -> GUI进程 （已经实现，本次改善）
CaptureWorker -> 截图进程 （已经实现，本次不变）
DecoderWorker -> 图像解析进程 (已经实现部分，本次不变)
HttpdWorker -> Httpd进程 (本次负责实现)

### 项目整体业务逻辑

- MainWindows中包含一些变量
  - self.martix_raw, 矩阵的np.array
  - self.martix_data , 是python dict。
  - 其他按需生成。

## 本次要实现的如下

实现内置的http服务器，对外提供json服务，返回json格式的self.martix_data

要求：
- 使用python内置http server实现。
- 任意url路由到相同的函数，相同状态下，返回相同内容。
- 不管get还是post，返回相同内容。
- 忽略一切get/post的请求体。
- 添加CORS头，允许跨域访问
- 用一个worker（QThread）形式执行
- 绑定0.0.0.0端口
- 默认端口在ui上已经设置。

本人之前的相似项目，使用过类似技术，供参考：
https://github.com/liantian-cn/EZWowX2/tree/main/EZPixelDumperX2
https://github.com/liantian-cn/EZWowX2/tree/main/EZBridgeX2

但是区别有
从主线程拿到的self.martix_data是python结构体，其中包含datetime等对象。解码代码都放入copilot/httpd/目录下。