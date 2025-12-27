package com.xuecheng.model.po;

import lombok.Data;
import java.util.Date;

/**
 * 课程评价回复表
 */
@Data
public class CourseCommentReply {
    
    /**
     * 回复ID
     */
    private Long replyId;
    
    /**
     * 评价ID
     */
    private Long commentId;
    
    /**
     * 父回复ID(支持多级回复)
     */
    private Long parentId;
    
    /**
     * 回复人用户ID
     */
    private Long userId;
    
    /**
     * 回复人用户名
     */
    private String userName;
    
    /**
     * 回复人昵称
     */
    private String nickName;
    
    /**
     * 回复内容
     */
    private String replyText;
    
    /**
     * 点赞数量
     */
    private Integer praiseNum;
    
    /**
     * 是否禁止回复: 1-禁止, 0-允许
     */
    private Integer forbidReply;
    
    /**
     * 回复时间
     */
    private Date replyDate;
    
    /**
     * 创建时间
     */
    private Date createDate;
    
    /**
     * 修改时间
     */
    private Date changeDate;
}












