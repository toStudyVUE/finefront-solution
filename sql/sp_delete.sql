-- 通用删除存储过程
-- 参数：p_table 表名, p_id 主键ID
-- 返回：JSON结果，包含 success, message, affected_rows

DROP PROCEDURE IF EXISTS sp_delete;

DELIMITER //

CREATE PROCEDURE sp_delete(
    IN p_table VARCHAR(100),
    IN p_id BIGINT
)
BEGIN
    DECLARE v_sql TEXT;
    DECLARE v_affected INT DEFAULT 0;
    DECLARE v_success TINYINT DEFAULT 1;
    DECLARE v_message VARCHAR(200) DEFAULT '删除成功';
    DECLARE v_error_msg TEXT;

    -- 异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        SELECT JSON_OBJECT(
            'success', FALSE,
            'message', CONCAT('删除失败: ', v_error_msg),
            'affected_rows', 0
        ) AS result;
    END;

    -- 构建并执行SQL（固定以id为条件）
    SET v_sql = CONCAT('DELETE FROM ', p_table, ' WHERE id = ', p_id);

    SET @sql = v_sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET v_affected = ROW_COUNT();

    -- 返回结果集
    SELECT JSON_OBJECT(
        'success', v_success,
        'message', v_message,
        'affected_rows', v_affected
    ) AS result;
END //

DELIMITER ;
