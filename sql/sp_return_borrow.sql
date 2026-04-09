DROP PROCEDURE IF EXISTS sp_return_borrow;

DELIMITER $$

CREATE PROCEDURE sp_return_borrow(
    IN p_borrow_id BIGINT,
    IN p_actual_return_date DATE
)
BEGIN
    DECLARE v_equipment_id BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT JSON_OBJECT('success', FALSE, 'message', '归还操作失败') as result;
    END;

    -- 获取设备ID
    SELECT equipment_id INTO v_equipment_id FROM borrow_record WHERE id = p_borrow_id;

    -- 更新借用记录
    UPDATE borrow_record
    SET actual_return_date = p_actual_return_date,
        status = '已归还',
        updated_at = NOW()
    WHERE id = p_borrow_id;

    -- 更新设备状态
    UPDATE equipment SET status = '可用', updated_at = NOW() WHERE id = v_equipment_id;

    -- 返回结果
    SELECT JSON_OBJECT('success', TRUE, 'message', '归还成功') as result;
END$$

DELIMITER ;
