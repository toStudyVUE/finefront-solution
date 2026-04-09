-- 设备导入提交存储过程
-- 逻辑：
-- 1. CANCEL 模式：直接清理临时表数据
-- 2. VALID_ONLY 模式：重新校验 -> 迁移到业务表 -> 清理临时表

DROP PROCEDURE IF EXISTS sp_equipment_import_commit;

DELIMITER //

CREATE PROCEDURE sp_equipment_import_commit(
    IN p_import_id VARCHAR(36),
    IN p_mode VARCHAR(20)
)
BEGIN
    DECLARE v_valid_count INT DEFAULT 0;
    DECLARE v_insert_count INT DEFAULT 0;
    DECLARE v_error_msg VARCHAR(500);
    DECLARE v_success TINYINT DEFAULT 1;

    -- 异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        SELECT JSON_OBJECT(
            'success', FALSE,
            'message', CONCAT('导入失败: ', v_error_msg),
            'insert_count', 0
        ) AS result;
    END;

    -- CANCEL 模式：直接删除临时数据
    IF p_mode = 'CANCEL' THEN
        DELETE FROM temp_import WHERE import_id = p_import_id;
        SELECT JSON_OBJECT(
            'success', TRUE,
            'message', '已取消导入',
            'insert_count', 0
        ) AS result;
        -- 直接返回
    ELSE
        -- VALID_ONLY 模式：先重新校验

        -- 1. 资产编号为空
        UPDATE temp_import
        SET is_valid = 0, error_msg = '资产编号不能为空'
        WHERE import_id = p_import_id
        AND (str_01 IS NULL OR TRIM(str_01) = '')
        AND is_valid = 1;

        -- 2. 设备名称为空
        UPDATE temp_import
        SET is_valid = 0, error_msg = '设备名称不能为空'
        WHERE import_id = p_import_id
        AND (str_02 IS NULL OR TRIM(str_02) = '')
        AND is_valid = 1;

        -- 3. 资产编号与数据库已有数据重复
        UPDATE temp_import t
        SET is_valid = 0, error_msg = '资产编号已存在于系统中'
        WHERE t.import_id = p_import_id
        AND t.is_valid = 1
        AND EXISTS (
            SELECT 1 FROM equipment e WHERE e.asset_no = TRIM(t.str_01)
        );

        -- 4. 资产编号在导入批次内重复
        UPDATE temp_import t1
        SET is_valid = 0, error_msg = '资产编号在导入数据中重复'
        WHERE t1.import_id = p_import_id
        AND t1.is_valid = 1
        AND EXISTS (
            SELECT 1 FROM (
                SELECT TRIM(str_01) AS asset_no, MIN(row_no) AS first_row
                FROM temp_import
                WHERE import_id = p_import_id
                AND str_01 IS NOT NULL AND TRIM(str_01) != ''
                GROUP BY TRIM(str_01)
            ) t2
            WHERE t2.asset_no = TRIM(t1.str_01)
            AND t2.first_row < t1.row_no
        );

        -- 统计有效数据
        SELECT COUNT(*) INTO v_valid_count
        FROM temp_import
        WHERE import_id = p_import_id AND is_valid = 1;

        IF v_valid_count = 0 THEN
            -- 无有效数据，返回失败
            SELECT JSON_OBJECT(
                'success', FALSE,
                'message', '没有有效的导入数据',
                'insert_count', 0
            ) AS result;
        ELSE
            -- 迁移到业务表
            INSERT INTO equipment (asset_no, name, type, status, location, remark)
            SELECT
                TRIM(str_01),                          -- asset_no
                TRIM(str_02),                          -- name
                TRIM(str_03),                          -- type
                IFNULL(NULLIF(TRIM(str_10), ''), '可用'), -- status，默认可用
                TRIM(str_07),                          -- location
                TRIM(txt_04)                           -- remark
            FROM temp_import
            WHERE import_id = p_import_id AND is_valid = 1;

            SET v_insert_count = ROW_COUNT();

            -- 清理临时数据
            DELETE FROM temp_import WHERE import_id = p_import_id;

            -- 返回成功
            SELECT JSON_OBJECT(
                'success', TRUE,
                'message', '导入成功',
                'insert_count', v_insert_count
            ) AS result;
        END IF;
    END IF;
END //

DELIMITER ;
