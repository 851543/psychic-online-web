-- ============================================
-- 作业管理和作业批改系统 MySQL 表结构
-- ============================================

-- 1. 作业表 (work) - 存储作业基本信息
DROP TABLE IF EXISTS `work`;
CREATE TABLE `work` (
  `work_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '作业ID',
  `title` VARCHAR(255) NOT NULL COMMENT '作业标题',
  `question` TEXT NOT NULL COMMENT '作业内容/要求',
  `status` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '状态: 1-使用态, 0-删除态',
  `username` VARCHAR(100) DEFAULT NULL COMMENT '创建人',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `change_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`work_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='作业表';

-- 2. 课程作业关联表 (course_work) - 作业与课程的关联关系
DROP TABLE IF EXISTS `course_work`;
CREATE TABLE `course_work` (
  `course_work_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '课程作业ID',
  `course_pub_id` BIGINT(20) NOT NULL COMMENT '课程发布ID',
  `work_id` BIGINT(20) NOT NULL COMMENT '作业ID',
  `teachplan_id` BIGINT(20) NOT NULL COMMENT '课程计划ID(章节)',
  `company_id` BIGINT(20) DEFAULT NULL COMMENT '机构ID',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`course_work_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程作业关联表';

-- 3. 作业提交记录表 (work_record) - 学生提交的作业记录
DROP TABLE IF EXISTS `work_record`;
CREATE TABLE `work_record` (
  `work_record_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '作业记录ID',
  `work_id` BIGINT(20) NOT NULL COMMENT '作业ID',
  `course_pub_id` BIGINT(20) NOT NULL COMMENT '课程发布ID',
  `teachplan_id` BIGINT(20) NOT NULL COMMENT '课程计划ID',
  `teachplan_name` VARCHAR(255) DEFAULT NULL COMMENT '课程计划名称',
  `username` VARCHAR(100) NOT NULL COMMENT '提交人(学生用户名)',
  `answer` TEXT COMMENT '完成内容/答案',
  `type` VARCHAR(50) DEFAULT 'text' COMMENT '类型: text-文字, file-文件等',
  `status` VARCHAR(20) DEFAULT '306002' COMMENT '状态: 306001-待提交, 306002-待批阅, 306003-已批阅(参考字典表306)',
  `correct_comment` TEXT COMMENT '评语',
  `correction_date` DATETIME DEFAULT NULL COMMENT '批改时间',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '提交时间',
  PRIMARY KEY (`work_record_id`),
  KEY `idx_work_id` (`work_id`),
  KEY `idx_course_pub_id` (`course_pub_id`),
  KEY `idx_username` (`username`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='作业提交记录表';

-- 4. 作业文件表 (work_file) - 存储作业相关的文件（可选，如果需要文件上传功能）
DROP TABLE IF EXISTS `work_file`;
CREATE TABLE `work_file` (
  `file_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '文件ID',
  `work_record_id` BIGINT(20) NOT NULL COMMENT '作业记录ID',
  `file_name` VARCHAR(255) NOT NULL COMMENT '文件名',
  `file_path` VARCHAR(500) NOT NULL COMMENT '文件路径',
  `file_size` BIGINT(20) DEFAULT NULL COMMENT '文件大小(字节)',
  `file_type` VARCHAR(50) DEFAULT NULL COMMENT '文件类型',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  PRIMARY KEY (`file_id`),
  KEY `idx_work_record_id` (`work_record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='作业文件表';

-- ============================================
-- 索引说明
-- ============================================
-- 1. work表: 按状态和创建时间查询
-- 2. course_work表: 按课程、作业、章节查询
-- 3. work_record表: 按作业、课程、学生、状态查询
-- 4. work_file表: 按作业记录查询文件

-- ============================================
-- 常用查询示例
-- ============================================

-- 查询作业列表（带绑定课程信息）
-- SELECT w.*, GROUP_CONCAT(cw.course_pub_id) as bind_courses
-- FROM work w
-- LEFT JOIN course_work cw ON w.work_id = cw.work_id
-- WHERE w.status = 1
-- GROUP BY w.work_id;

-- 查询待批阅作业数量
-- SELECT COUNT(*) as tobe_reviewed
-- FROM work_record
-- WHERE status = '306002';

-- 查询课程作业提交统计
-- SELECT 
--   cw.course_work_id,
--   cw.course_pub_id,
--   COUNT(DISTINCT wr.username) as total_users,
--   COUNT(wr.work_record_id) as total_answers,
--   SUM(CASE WHEN wr.status = '306002' THEN 1 ELSE 0 END) as tobe_reviewed
-- FROM course_work cw
-- LEFT JOIN work_record wr ON cw.work_id = wr.work_id AND cw.course_pub_id = wr.course_pub_id
-- GROUP BY cw.course_work_id;

