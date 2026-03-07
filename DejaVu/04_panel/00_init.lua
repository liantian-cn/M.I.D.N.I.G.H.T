--[[
文件定位：
  DejaVu 面板初始化模块，负责建立面板表、颜色表与示例设置行。

功能说明：
  1) 创建 addonTable.Panel 作为面板模块入口
  2) 定义面板使用的颜色表（与 EZPanel 外观一致）
  3) 提供 Rows 容器并写入三个示例设置项

状态：
  waiting_real_test（等待真实测试）
]]
local addonName, addonTable = ... -- 插件名称与共享表
local CreateColor = CreateColor

addonTable.Panel = {} -- 面板模块主表


addonTable.Panel.COLOR = {                                                          -- 面板配色表
    Black           = CreateColor(0 / 255, 0 / 255, 0 / 255, 1),                    -- 纯黑
    WindowBg        = CreateColor(30 / 255, 30 / 255, 30 / 255, 1),                 -- 窗口背景色
    WindowText      = CreateColor(0 / 255, 0 / 255, 0 / 255, 1),                    -- 窗口文字色（备用）
    WindowBorder    = CreateColor(83 / 255, 88 / 255, 91 / 255, 1),                 -- 窗口边框色
    Base            = CreateColor(255 / 255, 255 / 255, 255 / 255, 1),              -- 基础白
    ButtonBorder    = CreateColor(52 / 255, 52 / 255, 52 / 255, 1),                 -- 按钮边框色
    ButtonHighlight = CreateColor(86 / 255, 86 / 255, 86 / 255, 1),                 -- 按钮悬停高亮
    ButtonMouseUp   = CreateColor(43 / 255, 43 / 255, 43 / 255, 1),                 -- 按钮正常底色
    ButtonMouseDown = CreateColor(37 / 255, 37 / 255, 37 / 255, 1),                 -- 按钮按下底色
    SliderLeft      = CreateColor(73 / 255, 179 / 255, 234 / 255, 1),               -- 滑块已填充色
    SliderRight     = CreateColor(159 / 255, 159 / 255, 159 / 255, 1),              -- 滑块未填充色
    RowHover        = CreateColor(50 / 255, 50 / 255, 50 / 255, 1),                 -- 行悬停色
    Text            = CreateColor(230 / 255, 230 / 255, 230 / 255, 1),              -- 文本颜色
    DropdownBg      = CreateColor(34 / 255, 34 / 255, 34 / 255, 1),                 -- 下拉列表背景色
}                                                                                   -- COLOR 结束

addonTable.Panel.Font = "Interface\\Addons\\" .. addonName .. "\\fonts\\DejaVu.ttf" -- 自定义字体路径
addonTable.Panel.Rows = {}                                                          -- 面板行配置容器（在加载期写入，在第二帧构建 UI）
addonTable.Panel.DefaultApplied = {}                                                -- 记录已 set_default 的 key，确保只执行一次
