-- ============================================
-- 课程评价管理系统 MySQL 表结构
-- ============================================

-- 1. 课程评价表 (course_comment) - 存储课程评价基本信息
DROP TABLE IF EXISTS `course_comment`;
CREATE TABLE `course_comment` (
  `comment_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '评价ID',
  `target_id` BIGINT(20) NOT NULL COMMENT '评论对象ID(课程ID)',
  `target_name` VARCHAR(255) DEFAULT NULL COMMENT '评论对象名称(课程名称)',
  `target_type` VARCHAR(50) DEFAULT 'course' COMMENT '评论对象类型: course-课程',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `user_name` VARCHAR(100) DEFAULT NULL COMMENT '用户名',
  `nick_name` VARCHAR(100) DEFAULT NULL COMMENT '用户昵称',
  `user_head` VARCHAR(500) DEFAULT NULL COMMENT '用户头像URL',
  `star_rank` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '星级评分: 0-5',
  `comment_text` TEXT NOT NULL COMMENT '评价内容',
  `come_from` VARCHAR(255) DEFAULT NULL COMMENT '来源(课程名称)',
  `belong_to` BIGINT(20) DEFAULT NULL COMMENT '所属ID',
  `praise_num` INT(11) DEFAULT 0 COMMENT '点赞数量',
  `forbid_reply` TINYINT(1) DEFAULT 0 COMMENT '是否禁止回复: 1-禁止, 0-允许',
  `comment_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '评价时间',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `change_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程评价表';

-- 2. 课程评价回复表 (course_comment_reply) - 存储评价的回复信息
DROP TABLE IF EXISTS `course_comment_reply`;
CREATE TABLE `course_comment_reply` (
  `reply_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '回复ID',
  `comment_id` BIGINT(20) NOT NULL COMMENT '评价ID',
  `parent_id` BIGINT(20) DEFAULT NULL COMMENT '父回复ID(支持多级回复)',
  `user_id` BIGINT(20) NOT NULL COMMENT '回复人用户ID',
  `user_name` VARCHAR(100) DEFAULT NULL COMMENT '回复人用户名',
  `nick_name` VARCHAR(100) DEFAULT NULL COMMENT '回复人昵称',
  `reply_text` TEXT NOT NULL COMMENT '回复内容',
  `praise_num` INT(11) DEFAULT 0 COMMENT '点赞数量',
  `forbid_reply` TINYINT(1) DEFAULT 0 COMMENT '是否禁止回复: 1-禁止, 0-允许',
  `reply_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '回复时间',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `change_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`reply_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程评价回复表';

-- ============================================
-- 索引说明
-- ============================================
-- 1. course_comment表:
--    - idx_target_id: 按课程ID查询评价列表
--    - idx_user_id: 按用户ID查询用户评价
--    - idx_star_rank: 按评分等级筛选(好评/中评/差评)
--    - idx_status: 按状态筛选
--    - idx_comment_date: 按评价时间排序
--
-- 2. course_comment_reply表:
--    - idx_comment_id: 按评价ID查询回复列表
--    - idx_parent_id: 支持多级回复查询
--    - idx_user_id: 按用户ID查询回复
--    - idx_status: 按状态筛选
--    - idx_reply_date: 按回复时间排序

-- ============================================
-- 常用查询示例
-- ============================================

-- 查询课程评价列表(带回复数量)
-- SELECT 
--   cc.*,
--   COUNT(DISTINCT ccr.reply_id) as reply_count
-- FROM course_comment cc
-- LEFT JOIN course_comment_reply ccr ON cc.comment_id = ccr.comment_id AND ccr.status = 1
-- WHERE cc.target_id = ? AND cc.status = 1
-- GROUP BY cc.comment_id
-- ORDER BY cc.comment_date DESC;

-- 查询评价详情及所有回复
-- SELECT 
--   cc.*,
--   ccr.reply_id,
--   ccr.parent_id,
--   ccr.user_id as reply_user_id,
--   ccr.user_name as reply_user_name,
--   ccr.nick_name as reply_nick_name,
--   ccr.reply_text,
--   ccr.reply_date,
--   ccr.praise_num as reply_praise_num
-- FROM course_comment cc
-- LEFT JOIN course_comment_reply ccr ON cc.comment_id = ccr.comment_id AND ccr.status = 1
-- WHERE cc.comment_id = ? AND cc.status = 1
-- ORDER BY ccr.reply_date ASC;

-- 按评分等级统计评价数量
-- SELECT 
--   star_rank,
--   CASE 
--     WHEN star_rank >= 4 THEN '好评'
--     WHEN star_rank = 3 THEN '中评'
--     WHEN star_rank <= 2 THEN '差评'
--   END as level_name,
--   COUNT(*) as count
-- FROM course_comment
-- WHERE target_id = ? AND status = 1
-- GROUP BY star_rank;

-- 查询待回复的评价(有评价但无回复)
-- SELECT cc.*
-- FROM course_comment cc
-- LEFT JOIN course_comment_reply ccr ON cc.comment_id = ccr.comment_id AND ccr.status = 1
-- WHERE cc.status = 1 AND ccr.reply_id IS NULL
-- ORDER BY cc.comment_date DESC;












