-- 用户偏好表
-- 用于存储用户引导状态、主题设置等偏好信息

CREATE TABLE IF NOT EXISTS user_preference (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL COMMENT '用户ID',
    pref_key VARCHAR(100) NOT NULL COMMENT '偏好键（如guide_borrow_list）',
    pref_value VARCHAR(500) COMMENT '偏好值',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_pref (user_id, pref_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户偏好表';

-- 功能ID命名规范：
-- guide_{模块}_{页面}
-- 例如：guide_borrow_list, guide_equipment_form
