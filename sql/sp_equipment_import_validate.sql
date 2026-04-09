-- 设备导入校验存储过程
-- 校验规则：
-- 1. 资产编号不能为空
-- 2. 资产编号不能与数据库中已有数据重复
-- 3. 资产编号在导入批次内不能重复

DROP PROCEDURE IF EXISTS sp_equipment_import_validate;

DELIMITER //

CREATE PROCEDURE sp_equipment_import_validate(
    IN p_import_id VARCHAR(36)
)
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_valid INT DEFAULT 0;
    DECLARE v_error INT DEFAULT 0;

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

    -- 统计结果
    SELECT COUNT(*) INTO v_total
    FROM temp_import WHERE import_id = p_import_id;

    SELECT
        SUM(CASE WHEN is_valid = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN is_valid = 0 THEN 1 ELSE 0 END)
    INTO v_valid, v_error
    FROM temp_import
    WHERE import_id = p_import_id;

    -- 返回结果
    SELECT JSON_OBJECT(
        'success', IF(v_error = 0, TRUE, FALSE),
        'total', v_total,
        'valid_count', v_valid,
        'error_count', v_error
    ) AS result;
END //

DELIMITER ;
