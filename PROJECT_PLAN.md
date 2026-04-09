# 设备借用管理示例项目开发计划

> 版本：2.1
> 更新时间：2026-04-09
> 状态：**已完成**

## 项目概述

**业务场景**：员工借用公司设备（笔记本、投影仪等），记录借出和归还。

**数据模型**：
```
equipment（设备表）
├── id BIGINT AUTO_INCREMENT
├── asset_no VARCHAR(50)       -- 资产编号
├── name VARCHAR(100)          -- 设备名称
├── type VARCHAR(50)           -- 设备类型
├── status VARCHAR(20)         -- 状态：可用/借出/维修
├── location VARCHAR(100)      -- 存放地点
├── remark VARCHAR(500)        -- 备注
├── created_at DATETIME
└── updated_at DATETIME

borrow_record（借用记录表）
├── id BIGINT AUTO_INCREMENT
├── borrow_no VARCHAR(50)      -- 借用单号
├── user_id VARCHAR(50)        -- 借用人ID
├── user_name VARCHAR(50)      -- 借用人姓名
├── dept_name VARCHAR(100)     -- 部门
├── equipment_id BIGINT        -- 设备ID
├── equipment_name VARCHAR(100)-- 设备名称
├── borrow_date DATE           -- 借用日期
├── expected_return_date DATE  -- 预计归还日期
├── actual_return_date DATE    -- 实际归还日期
├── status VARCHAR(20)         -- 状态：借用中/已归还/已逾期
├── remark VARCHAR(500)        -- 备注
├── created_at DATETIME
└── updated_at DATETIME
```

**覆盖场景**：
| 场景 | 类型 | 说明 |
|------|------|------|
| 设备列表 | 列表查询 | 分页、排序、筛选 |
| 设备新增 | 单条新增 | 弹窗表单 |
| 设备编辑 | 单条更新 | 弹窗表单 |
| 设备删除 | 单条删除 | 确认弹窗 |
| 批量导入设备 | 批量导入 | Excel导入临时表 |
| 借用申请 | 单条新增 | 弹窗表单 |
| 归还操作 | 单条更新 | 状态变更 |
| 设备选择器 | 字典查询 | 弹窗选择后回填 |

---

## 目录结构

```
reportlets/
├── api/                              # 公共代理模板目录
│   └── api_agent.cpt                 # 外部API代理（全局唯一）
│
└── jiangcheng/borrow/                # 业务模块目录
    ├── data/                         # 数据层模板
    │   └── borrow_data.cpt           # 数据层（查询、增删改、批量导入）
    │
    └── pages/                        # 展示层模板（挂菜单）
        ├── borrow_list.cpt           # 列表页
        ├── borrow_apply.cpt          # 借用申请弹窗
        ├── borrow_return.cpt         # 归还操作弹窗
        ├── equipment_form.cpt        # 设备表单弹窗（新增/编辑）
        ├── equipment_selector.cpt    # 设备选择器弹窗
        ├── equipment_batch.cpt       # 批量导入页面
        └── api_scheduler.cpt         # API调度中心（待开发）
```

---

## 接口分工（ARCHITECTURE.md 2.0）

| 接口 | 模板 | 适用场景 |
|------|------|----------|
| `/api/data` | 专用数据层 `borrow_data.cpt` | **全部数据库操作**（查询、增删改、批量导入） |
| `/api/report` | 通用代理 `api_agent.cpt` | **全部外部API** |

---

## 分阶段开发计划

### 第一阶段：基础设施 ✅ 已完成

| 步骤 | 内容 | 状态 |
|------|------|------|
| 1.1 | 创建数据库表（equipment、borrow_record、temp_import） | ✅ |
| 1.2 | 创建通用增删改存储过程（sp_insert/update/delete） | ✅ |
| 1.3 | 创建设备专用存储过程（sp_insert_equipment、sp_update_equipment） | ✅ |
| 1.4 | 创建借用相关存储过程（sp_borrow_equipment、sp_return_borrow） | ✅ |
| 1.5 | 创建批量导入存储过程（sp_batch_import、sp_equipment_import_validate、sp_equipment_import_commit） | ✅ |
| 1.6 | 创建目录结构 | ✅ |

**产出文件**：
```
finefront-solution/sql/
├── sp_insert.sql
├── sp_update.sql
├── sp_delete.sql
├── sp_insert_equipment.sql
├── sp_update_equipment.sql
├── sp_borrow_equipment.sql
├── sp_return_borrow.sql
├── sp_batch_import.sql
├── sp_equipment_import_validate.sql
└── sp_equipment_import_commit.sql
```

---

### 第二阶段：公共模板 ✅ 已完成

| 步骤 | 内容 | 状态 |
|------|------|------|
| 2.1 | 开发 api_agent.cpt | ✅ |
| 2.2 | 验证公共模板 | ✅ |

**产出文件**：
```
reportlets/api/
└── api_agent.cpt              # 外部API代理
```

---

### 第三阶段：数据层模板 ✅ 已完成

| 步骤 | 内容 | 状态 |
|------|------|------|
| 3.1 | 开发 borrow_data.cpt | ✅ |
| 3.2 | 合并批量导入数据集 | ✅ |
| 3.3 | 验证数据层模板 | ✅ |

**borrow_data.cpt 数据集清单**：

| 分类 | 数据集 | 功能 |
|------|--------|------|
| 设备查询 | equipment_qry | 设备列表查询 |
| | equipment_total | 设备总数 |
| | equipment_stats | 设备统计 |
| | equipment_by_id | 单设备查询 |
| | equipment_available | 可借用设备（选择器） |
| 借用查询 | borrow_qry | 借用记录列表 |
| | borrow_total | 借用记录总数 |
| | borrow_stats | 借用统计 |
| | borrow_by_id | 单条借用查询 |
| 字典 | dict_type | 设备类型字典 |
| | dict_equipment_status | 设备状态字典 |
| | dict_borrow_status | 借用状态字典 |
| 设备写入 | insert_equipment | 新增设备 |
| | update_equipment | 更新设备 |
| | sp_delete | 通用删除 |
| 借用写入 | insert_borrow | 新增借用记录 |
| | sp_return_borrow | 归还设备 |
| 批量导入 | batch_insert | 批量写入临时表 |
| | validate | 校验导入数据 |
| | commit | 提交到业务表 |
| | errors | 查询错误记录 |
| | stats | 导入统计 |

---

### 第四阶段：展示模板 ✅ 已完成

| 步骤 | 内容 | 状态 |
|------|------|------|
| 4.1 | borrow_list.cpt - 列表页 | ✅ |
| 4.2 | equipment_selector.cpt - 设备选择器 | ✅ |
| 4.3 | borrow_apply.cpt - 借用申请弹窗 | ✅ |
| 4.4 | borrow_return.cpt - 归还操作弹窗 | ✅ |
| 4.5 | equipment_batch.cpt - 批量导入页面 | ✅ |
| 4.6 | equipment_form.cpt - 设备表单弹窗 | ✅ |

#### 功能清单

| 模板 | 功能 | 状态 |
|------|------|------|
| borrow_list.cpt | Tab切换、筛选、排序、分页 | ✅ |
| equipment_form.cpt | 新增/编辑设备表单 | ✅ |
| equipment_selector.cpt | 设备选择器弹窗 | ✅ |
| borrow_apply.cpt | 借用申请表单 | ✅ |
| borrow_return.cpt | 归还操作弹窗 | ✅ |
| equipment_batch.cpt | Excel批量导入 | ✅ |

---

### 第五阶段：集成验证 ✅ 已完成

| 步骤 | 内容 | 状态 |
|------|------|------|
| 5.1 | 列表页集成测试 | ✅ |
| 5.2 | 借用→归还完整流程测试 | ✅ |
| 5.3 | 批量导入流程测试 | ✅ |
| 5.4 | 新增/编辑设备测试 | ✅ |

**测试结论**：全部功能通过验收。

---

### 第六阶段：架构重构 ✅ 已完成（2026-04-07）

| 步骤 | 内容 | 状态 |
|------|------|------|
| 6.1 | 合并 equipment_batch_data.cpt 到 borrow_data.cpt | ✅ |
| 6.2 | 删除废弃模板 db_agent_common_db.cpt | ✅ |
| 6.3 | 更新 equipment_batch.cpt 调用路径 | ✅ |
| 6.4 | 补全SQL脚本（sp_insert_equipment、sp_update_equipment、sp_batch_import） | ✅ |
| 6.5 | 更新项目计划文档 | ✅ |

**重构产出**：
- 合并后 `borrow_data.cpt` 包含全部数据集（设备、借用、批量导入）
- 删除冗余模板文件
- 完整SQL脚本可直接执行创建存储过程

---

## 关键技术点

### 1. 路径动态获取

```javascript
// 获取当前模板目录
var currentReport = FR.remoteEvaluate("=reportName");
var currentDir = currentReport.substring(0, currentReport.lastIndexOf('/') + 1);

// 获取 API 基础路径
var servletUrl = FR.remoteEvaluate("=servletURL");
var apiBase = servletUrl.substring(0, servletUrl.indexOf('/view/report'));

// 拼接模板路径
function getTemplatePath(filename) {
    if (filename.startsWith('api/')) {
        return filename;  // 公共模板
    }
    return currentDir + filename;  // 同目录模板
}
```

### 2. 批量导入临时表清理

**方案**：凌晨定时 TRUNCATE

```bash
# crontab 配置
0 3 * * * mysql -h localhost -P 13306 -u finereport -p'Fr@2026Pwd' -e "TRUNCATE TABLE common_db.temp_import;"
```

### 3. 存储过程参数约定

**通用增删改**：
| 存储过程 | 参数 | 说明 |
|----------|------|------|
| sp_insert | p_table, p_fields, p_values | 返回 LAST_INSERT_ID() |
| sp_update | p_table, p_fields, p_values, p_id | 固定以 id 为条件 |
| sp_delete | p_table, p_id | 固定以 id 为条件 |

**设备专用**：
| 存储过程 | 参数 | 说明 |
|----------|------|------|
| sp_insert_equipment | 资产编号、名称、类型、状态、位置、备注 | 新增设备 |
| sp_update_equipment | id、资产编号、名称、类型、状态、位置、备注 | 更新设备（有借用记录时限制状态修改） |

**借用相关**：
| 存储过程 | 参数 | 说明 |
|----------|------|------|
| sp_borrow_equipment | 借用人信息、设备ID、日期等 | 新增借用记录并更新设备状态 |
| sp_return_borrow | 借用记录ID、实际归还日期 | 归还设备并恢复设备状态 |

**批量导入**：
| 存储过程 | 参数 | 说明 |
|----------|------|------|
| sp_batch_import | p_import_id, p_biz_type, p_data_json, p_start_row | 写入临时表 |
| sp_equipment_import_validate | p_import_id | 校验数据 |
| sp_equipment_import_commit | p_import_id, p_mode | 提交（VALID_ONLY/CANCEL） |

---

## Bug修复记录

### 2026-04-07 集成验证期间修复

| Bug编号 | 问题描述 | 修复方案 |
|---------|----------|----------|
| BUG-001 | 批量导入Excel字段映射错误 | 更新fieldMapping配置 |
| BUG-001-R | 批量导入数据未写入数据库 | 存储过程添加COLLATE解决字符集冲突 |
| BUG-002 | 归还弹窗加载失败 | 兼容多种API响应格式 |
| BUG-002-R | 归还弹窗JS错误 | 删除无效DOM操作代码 |

---

## 项目完成状态

**状态**：✅ 已完成

**完成时间**：2026-04-07

**验收结论**：全部功能测试通过，架构重构完成，可交付使用。

---

## 第七阶段：外部API调度案例 ✅ 已完成

### 功能定位

作为**调度外部API的参考案例**，展示如何在帆软加壳方案中调用外部HTTP接口。

### 设计目标

| 目标 | 说明 |
|------|------|
| 演示代理模板使用 | 通过 `api_agent.cpt` 调用外部API |
| 覆盖常见场景 | 标准请求、错误处理、认证、超时等 |
| 业务场景参考 | 可作为调用明道云API、第三方接口的模板 |

### 页面设计

```
API调度中心
├── 接口列表（左侧）
│   ├── 创建用户（标准JSON请求）
│   ├── 批量同步（数组请求）
│   ├── Token认证（Header认证）
│   ├── 错误处理（HTTP/业务错误）
│   └── ...
│
├── 请求配置（右上）
│   ├── 接口URL
│   ├── 请求方法
│   ├── 请求头
│   └── 请求体（JSON编辑器）
│
└── 响应结果（右下）
    ├── 状态码
    ├── 响应时间
    └── 响应内容
```

### Mock服务

本地Mock服务提供测试接口：

| 服务 | 地址 | 说明 |
|------|------|------|
| Mock Server | http://localhost:3200 | 13个测试接口 |
| 文档 | mock-server/API_AGENT_TEST.md | 接口详情 |

### 产出文件

```
reportlets/jiangcheng/borrow/pages/
└── api_scheduler.cpt    # API调度中心页面
```

### 开发状态

| 步骤 | 内容 | 状态 |
|------|------|------|
| 7.1 | 规划功能设计 | ✅ |
| 7.2 | 开发 api_scheduler.cpt | ✅ |
| 7.3 | 集成测试 | ✅ |

---

## 第八阶段：展示层模板说明标注 ✅ 已完成（2026-04-09）

### 背景

展示层cpt的HTML内容会覆盖单元格显示，因此在单元格添加说明不影响前端页面，但打开设计器可快速识别模板用途。

### 方案

在展示层模板合并区域（如A1:D2）添加功能说明，格式：
```
【页面类型】功能描述
数据层：xxx_data.cpt
```

### 已标注模板

| 模板 | 说明 |
|------|------|
| borrow_list.cpt | 【借用管理】Tab切换+分页+筛选+增删改查 |
| borrow_apply.cpt | 【借用申请】设备借用申请表单，含设备选择器 |
| borrow_return.cpt | 【设备归还】加载借用记录，提交归还 |
| equipment_form.cpt | 【设备表单】新增/编辑设备信息，URL参数id区分模式 |
| equipment_selector.cpt | 【设备选择器】搜索可借用设备，点击回填父页面 |
| equipment_batch.cpt | 【批量导入】Excel上传→解析预览→校验→确认导入 |
| api_scheduler.cpt | 【API调度中心】接口测试+请求配置+响应展示 |

### 开发状态

| 步骤 | 内容 | 状态 |
|------|------|------|
| 8.1 | 确定标注规范 | ✅ |
| 8.2 | 为全部展示层模板添加说明 | 待执行 |

---

## 附录：SQL脚本清单

sql目录下共10个存储过程脚本，与数据库已创建的存储过程一一对应：

| 脚本 | 说明 |
|------|------|
| sp_insert.sql | 通用插入（表名+字段+值） |
| sp_update.sql | 通用更新（表名+字段+值+条件） |
| sp_delete.sql | 通用删除（表名+ID） |
| sp_insert_equipment.sql | 设备新增（含业务逻辑） |
| sp_update_equipment.sql | 设备更新（含状态校验） |
| sp_borrow_equipment.sql | 借用申请（设备状态联动） |
| sp_return_borrow.sql | 归还设备（恢复设备状态） |
| sp_batch_import.sql | 批量写入临时表 |
| sp_equipment_import_validate.sql | 导入数据校验 |
| sp_equipment_import_commit.sql | 导入数据提交/取消 |
