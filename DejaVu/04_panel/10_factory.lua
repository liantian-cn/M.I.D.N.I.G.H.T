--[[
文件定位：
  DejaVu 面板工厂模块，根据 Rows 构建不同类型的设置行。

功能说明：
  1) 遍历 addonTable.Panel.Rows
  2) 按 type 分发到对应的 UI 构造函数

示例（来自 panel/init.lua）：
  slider_example:
    {
      type = "slider",
      key = "slider_example",
      name = "滑块示例",
      tooltip = "这只是一个例子, 最小值0, 最大值100, 步进5, 默认值20",
      min_value = 0,
      max_value = 100,
      step = 5,
      default_value = 20,
      bind_config = Config("slider_example_config")
    }

  combo_example:
    {
      type = "combo",
      key = "combo_example",
      name = "下拉框例子",
      tooltip = "这只是一个例子。",
      default_value = "zhangsan",
      options = {
        { k = "zhangsan", v = "张三" },
        { k = "lisi", v = "李四" }
      },
      bind_config = Config("combo_example_config")
    }

  spell_list_example:
    {
      type = "spell_list",
      key = "spell_list_example",
      name = "技能图标例子",
      tooltip = "这只是一个例子。 ",
      default_value = { [294929] = true, [5487] = true },
      bind_config = Config("spell_list_example_config")
    }

状态：
  waiting_real_test（等待真实测试）
]]

local addonName, addonTable = ...                        -- luacheck: ignore addonName
local InitUI = addonTable.UpdateFunc.InitUI              -- 初始化 UI 函数列表

local AddSliderRow = addonTable.Panel.AddSliderRow       -- 创建滑块行
local AddComboRow = addonTable.Panel.AddComboRow         -- 创建下拉行
local AddSpellListRow = addonTable.Panel.AddSpellListRow -- 创建技能列表行

local function CreatePanelRows()                         -- 构建所有设置行
    for rowIndex = 1, #addonTable.Panel.Rows do          -- 遍历 Rows
        local row_info = addonTable.Panel.Rows[rowIndex]
        if row_info.type == "slider" then                -- 滑块
            AddSliderRow(row_info)                       -- 创建滑块行
        elseif row_info.type == "combo" then             -- 下拉
            AddComboRow(row_info)                        -- 创建下拉行
        elseif row_info.type == "spell_list" then        -- 技能列表
            AddSpellListRow(row_info)                    -- 创建技能列表行
        end                                              -- 分支结束
    end                                                  -- Rows 遍历结束
end                                                      -- CreatePanelRows 结束

table.insert(InitUI, CreatePanelRows)                    -- 第二帧创建所有行
