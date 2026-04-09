DROP PROCEDURE IF EXISTS sp_borrow_equipment;

DELIMITER $$

CREATE PROCEDURE sp_borrow_equipment(
    IN p_borrow_no VARCHAR(50),
    IN p_user_name VARCHAR(50),
    IN p_dept_name VARCHAR(100),
    IN p_equipment_id BIGINT,
    IN p_borrow_date DATE,
    IN p_expected_return DATE,
    IN p_remark VARCHAR(500)
)
BEGIN
    DECLARE v_equipment_name VARCHAR(100);

    -- 获取设备名称
    SELECT name INTO v_equipment_name FROM equipment WHERE id = p_equipment_id;

    -- 插入借用记录
    INSERT INTO borrow_record (borrow_no, user_name, dept_name, equipment_id, equipment_name, borrow_date, expected_return_date, status, remark)
    VALUES (p_borrow_no, p_user_name, p_dept_name, p_equipment_id, v_equipment_name, p_borrow_date, p_expected_return, '借用中', p_remark);

    -- 更新设备状态
    UPDATE equipment SET status = '借出' WHERE id = p_equipment_id;

    -- 返回结果
    SELECT JSON_OBJECT('success', TRUE, 'message', '借用申请成功') as result;
END$$

DELIMITER ;
