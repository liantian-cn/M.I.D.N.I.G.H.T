--[[
文件定位：
  DejaVu 尺寸定义模块，约束Matrix锚点、偏移、缩放与网格对齐参数。

输入来源：
  由matrix_spec草案中的尺寸与坐标约定提供规范依据。

输出职责：
  对外提供统一的尺寸配置域，供矩阵模块计算位置。

生命周期/调用时机：
  在插件初始化早期加载，在矩阵模块初始化前可用。

约束与非目标：
  本阶段不实现动态布局算法，仅定义尺寸常量。

状态：
  draft
]]

local addon_name, addon_table = ...

addon_table = addon_table or {}
addon_table.__addon_name = addon_name

-- 确保Core命名空间存在
addon_table.Core = addon_table.Core or {}
addon_table.Core.Size = {}

local Size = addon_table.Core.Size

-- 基础像素尺寸
Size.CELL_PIXEL_SIZE = 4
Size.MEGA_CELL_PIXEL_SIZE = 8
Size.BADGE_SIZE = 2

-- 矩阵尺寸
Size.MATRIX_COLS = 32
Size.MATRIX_ROWS = 32

-- 锚点默认配置
Size.DEFAULT_ANCHOR = "CENTER"
Size.DEFAULT_X = 0
Size.DEFAULT_Y = 0

-- 缩放
Size.DEFAULT_SCALE = 1.0

-- 间距
Size.CELL_GAP = 1
