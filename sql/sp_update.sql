-- 通用更新存储过程
-- 参数：p_table 表名, p_fields 字段JSON数组, p_values 值JSON数组, p_id 主键ID
-- 返回：JSON结果，包含 success, message, affected_rows

DROP PROCEDURE IF EXISTS sp_update;

DELIMITER //

CREATE PROCEDURE sp_update(
    IN p_table VARCHAR(100),
    IN p_fields JSON,
    IN p_values JSON,
    IN p_id BIGINT
)
BEGIN
    DECLARE v_sql TEXT;
    DECLARE v_set_str TEXT;
    DECLARE v_field VARCHAR(100);
    DECLARE v_value TEXT;
    DECLARE i INT DEFAULT 0;
    DECLARE v_count INT;
    DECLARE v_affected INT DEFAULT 0;
    DECLARE v_success TINYINT DEFAULT 1;
    DECLARE v_message VARCHAR(200) DEFAULT '更新成功';
    DECLARE v_error_msg TEXT;

    -- 异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        SELECT JSON_OBJECT(
            'success', FALSE,
            'message', CONCAT('更新失败: ', v_error_msg),
            'affected_rows', 0
        ) AS result;
    END;

    -- 获取字段数量
    SET v_count = JSON_LENGTH(p_fields);

    -- 构建SET子句
    SET v_set_str = '';
    WHILE i < v_count DO
        SET v_field = JSON_UNQUOTE(JSON_EXTRACT(p_fields, CONCAT('$[', i, ']')));
        SET v_value = JSON_UNQUOTE(JSON_EXTRACT(p_values, CONCAT('$[', i, ']')));

        IF i > 0 THEN
            SET v_set_str = CONCAT(v_set_str, ',');
        END IF;

        -- 处理NULL值
        IF v_value IS NULL OR v_value = 'null' THEN
            SET v_set_str = CONCAT(v_set_str, v_field, '=NULL');
        ELSE
            SET v_set_str = CONCAT(v_set_str, v_field, '=', CHAR(39), v_value, CHAR(39));
        END IF;

        SET i = i + 1;
    END WHILE;

    -- 构建并执行SQL（固定以id为条件）
    SET v_sql = CONCAT('UPDATE ', p_table, ' SET ', v_set_str, ' WHERE id = ', p_id);

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
