package com.xuecheng.model.po;

import lombok.Data;
import java.util.Date;

/**
 * 课程评价表
 */
@Data
public class CourseComment {
    
    /**
     * 评价ID
     */
    private Long commentId;
    
    /**
     * 评论对象ID(课程ID)
     */
    private Long targetId;
    
    /**
     * 评论对象名称(课程名称)
     */
    private String targetName;
    
    /**
     * 评论对象类型: course-课程
     */
    private String targetType;
    
    /**
     * 用户ID
     */
    private Long userId;
    
    /**
     * 用户名
     */
    private String userName;
    
    /**
     * 用户昵称
     */
    private String nickName;
    
    /**
     * 用户头像URL
     */
    private String userHead;
    
    /**
     * 星级评分: 0-5
     */
    private Integer starRank;
    
    /**
     * 评价内容
     */
    private String commentText;
    
    /**
     * 来源(课程名称)
     */
    private String comeFrom;
    
    /**
     * 所属ID
     */
    private Long belongTo;
    
    /**
     * 点赞数量
     */
    private Integer praiseNum;
    
    /**
     * 是否禁止回复: 1-禁止, 0-允许
     */
    private Integer forbidReply;
    
    /**
     * 评价时间
     */
    private Date commentDate;
    
    /**
     * 创建时间
     */
    private Date createDate;
    
    /**
     * 修改时间
     */
    private Date changeDate;
}












