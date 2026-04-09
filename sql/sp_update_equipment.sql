-- 设备更新存储过程
-- 参数：p_id 设备ID, p_asset_no 资产编号, p_name 设备名称, p_type 设备类型, p_status 状态, p_location 存放地点, p_remark 备注
-- 返回：JSON结果，包含 success, message
-- 逻辑：如果设备有借用中的记录，不允许将状态改为非"借出"

DROP PROCEDURE IF EXISTS sp_update_equipment;

DELIMITER $$

CREATE PROCEDURE sp_update_equipment(
    IN p_id BIGINT,
    IN p_asset_no VARCHAR(50),
    IN p_name VARCHAR(100),
    IN p_type VARCHAR(50),
    IN p_status VARCHAR(20),
    IN p_location VARCHAR(100),
    IN p_remark VARCHAR(500)
)
BEGIN
    DECLARE v_old_status VARCHAR(20);
    DECLARE v_has_borrow INT DEFAULT 0;
    DECLARE v_error_msg TEXT;

    -- 异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        SELECT JSON_OBJECT(
            'success', FALSE,
            'message', CONCAT('更新失败: ', v_error_msg)
        ) AS result;
    END;

    -- 检查是否有借用中的记录
    SELECT COUNT(*) INTO v_has_borrow
    FROM borrow_record
    WHERE equipment_id = p_id AND status = '借用中';

    -- 如果有借用中的记录，不允许修改状态
    IF v_has_borrow > 0 AND p_status != '借出' THEN
        SELECT JSON_OBJECT('success', FALSE, 'message', '该设备有借用中的记录，无法修改状态') as result;
    ELSE
        UPDATE equipment
        SET asset_no = p_asset_no,
            name = p_name,
            type = p_type,
            status = p_status,
            location = p_location,
            remark = p_remark,
            updated_at = NOW()
        WHERE id = p_id;

        SELECT JSON_OBJECT('success', TRUE, 'message', '更新成功') as result;
    END IF;
END$$

DELIMITER ;
