-- 批量导入存储过程
-- 参数：p_import_id 导入批次ID, p_biz_type 业务类型, p_data_json 数据JSON数组, p_start_row 起始行号
-- 返回：JSON结果，包含 status, import_id, count, message
-- 业务类型：equipment - 设备导入

DROP PROCEDURE IF EXISTS sp_batch_import;

DELIMITER $$

CREATE PROCEDURE sp_batch_import(
    IN p_import_id VARCHAR(36),
    IN p_biz_type VARCHAR(50),
    IN p_data_json TEXT,
    IN p_start_row INT
)
sp_main: BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE data_count INT DEFAULT 0;
    DECLARE row_json JSON;
    DECLARE v_result VARCHAR(500);

    -- 异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT JSON_OBJECT(
            'status', 'FAIL',
            'message', '数据库执行错误',
            'import_id', p_import_id
        ) as result;
    END;

    -- 参数校验
    IF p_data_json IS NULL OR JSON_TYPE(p_data_json) != 'ARRAY' THEN
        SELECT JSON_OBJECT(
            'status', 'FAIL',
            'message', '参数p_data_json必须是有效的JSON数组',
            'import_id', p_import_id
        ) as result;
        LEAVE sp_main;
    END IF;

    -- 获取数据数量
    SET data_count = JSON_LENGTH(p_data_json);

    -- 空数据处理
    IF data_count = 0 THEN
        SELECT JSON_OBJECT(
            'status', 'SUCCESS',
            'import_id', p_import_id,
            'count', 0,
            'message', '无数据需要导入'
        ) as result;
        LEAVE sp_main;
    END IF;

    -- 设备导入
    IF p_biz_type = 'equipment' THEN
        -- 遍历数据并写入临时表
        WHILE i < data_count DO
            SET row_json = JSON_EXTRACT(p_data_json, CONCAT('$[', i, ']'));

            INSERT INTO temp_import (
                import_id, row_no,
                str_01, str_02, str_03, str_04, str_05,
                str_06, str_07, str_08, str_09, str_10,
                num_01, num_02, num_03, num_04, num_05,
                txt_01, txt_02, txt_03, txt_04
            ) VALUES (
                p_import_id, i + p_start_row,
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."资产编号"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."设备名称"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."设备类型"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."品牌"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."规格型号"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."SN码"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."存放地点"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."使用部门"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."使用人"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."资产状态"')),
                JSON_EXTRACT(row_json, '$."数量"'),
                JSON_EXTRACT(row_json, '$."单价(元)"'),
                JSON_EXTRACT(row_json, '$."总价(元)"'),
                JSON_EXTRACT(row_json, '$."使用年限(年)"'),
                JSON_EXTRACT(row_json, '$."折旧后价值(元)"'),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."资产来源"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."供应商"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."购置日期"')),
                JSON_UNQUOTE(JSON_EXTRACT(row_json, '$."备注"'))
            );

            SET i = i + 1;
        END WHILE;

        SELECT JSON_OBJECT(
            'status', 'SUCCESS',
            'import_id', p_import_id,
            'count', data_count
        ) as result;
    ELSE
        SELECT JSON_OBJECT(
            'status', 'FAIL',
            'message', CONCAT('未知的业务类型: ', p_biz_type),
            'import_id', p_import_id
        ) as result;
    END IF;
END$$

DELIMITER ;
