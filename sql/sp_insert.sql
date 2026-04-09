-- 通用插入存储过程
-- 参数：p_table 表名, p_fields 字段JSON数组, p_values 值JSON数组
-- 返回：JSON结果，包含 success, message, affected_rows, id

DROP PROCEDURE IF EXISTS sp_insert;

DELIMITER //

CREATE PROCEDURE sp_insert(
    IN p_table VARCHAR(100),
    IN p_fields JSON,
    IN p_values JSON
)
BEGIN
    DECLARE v_sql TEXT;
    DECLARE v_fields_str TEXT;
    DECLARE v_values_str TEXT;
    DECLARE v_field VARCHAR(100);
    DECLARE v_value TEXT;
    DECLARE i INT DEFAULT 0;
    DECLARE v_count INT;
    DECLARE v_affected INT DEFAULT 0;
    DECLARE v_success TINYINT DEFAULT 1;
    DECLARE v_message VARCHAR(200) DEFAULT '插入成功';
    DECLARE v_new_id BIGINT;
    DECLARE v_error_msg TEXT;

    -- 异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        SELECT JSON_OBJECT(
            'success', FALSE,
            'message', CONCAT('插入失败: ', v_error_msg),
            'affected_rows', 0,
            'id', NULL
        ) AS result;
    END;

    -- 获取字段数量
    SET v_count = JSON_LENGTH(p_fields);

    -- 构建字段列表和值列表（不含id，自增）
    SET v_fields_str = '';
    SET v_values_str = '';

    WHILE i < v_count DO
        SET v_field = JSON_UNQUOTE(JSON_EXTRACT(p_fields, CONCAT('$[', i, ']')));
        SET v_value = JSON_UNQUOTE(JSON_EXTRACT(p_values, CONCAT('$[', i, ']')));

        IF i > 0 THEN
            SET v_fields_str = CONCAT(v_fields_str, ',');
            SET v_values_str = CONCAT(v_values_str, ',');
        END IF;

        SET v_fields_str = CONCAT(v_fields_str, v_field);

        -- 处理NULL值
        IF v_value IS NULL OR v_value = 'null' THEN
            SET v_values_str = CONCAT(v_values_str, 'NULL');
        ELSE
            SET v_values_str = CONCAT(v_values_str, CHAR(39), v_value, CHAR(39));
        END IF;

        SET i = i + 1;
    END WHILE;

    -- 构建并执行SQL
    SET v_sql = CONCAT('INSERT INTO ', p_table, '(', v_fields_str, ') VALUES (', v_values_str, ')');

    SET @sql = v_sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- 获取自增ID
    SET v_new_id = LAST_INSERT_ID();
    SET v_affected = ROW_COUNT();

    -- 返回结果集
    SELECT JSON_OBJECT(
        'success', v_success,
        'message', v_message,
        'affected_rows', v_affected,
        'id', v_new_id
    ) AS result;
END //

DELIMITER ;
