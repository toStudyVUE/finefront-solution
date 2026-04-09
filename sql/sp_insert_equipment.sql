-- 设备新增存储过程
-- 参数：p_asset_no 资产编号, p_name 设备名称, p_type 设备类型, p_status 状态, p_location 存放地点, p_remark 备注
-- 返回：JSON结果，包含 success, message, id

DROP PROCEDURE IF EXISTS sp_insert_equipment;

DELIMITER $$

CREATE PROCEDURE sp_insert_equipment(
    IN p_asset_no VARCHAR(50),
    IN p_name VARCHAR(100),
    IN p_type VARCHAR(50),
    IN p_status VARCHAR(20),
    IN p_location VARCHAR(100),
    IN p_remark VARCHAR(500)
)
BEGIN
    DECLARE v_new_id BIGINT;
    DECLARE v_error_msg TEXT;

    -- 异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        SELECT JSON_OBJECT(
            'success', FALSE,
            'message', CONCAT('新增失败: ', v_error_msg),
            'id', NULL
        ) AS result;
    END;

    INSERT INTO equipment (asset_no, name, type, status, location, remark, created_at, updated_at)
    VALUES (p_asset_no, p_name, p_type, p_status, p_location, p_remark, NOW(), NOW());

    SET v_new_id = LAST_INSERT_ID();

    SELECT JSON_OBJECT('success', TRUE, 'message', '新增成功', 'id', v_new_id) as result;
END$$

DELIMITER ;
