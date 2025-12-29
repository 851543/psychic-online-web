<template>
  <div class="course-list portal-content">
    <div class="workspace">
      <el-page-header @back="goToWorkRecordListView" content="批阅详情"></el-page-header>

      <!-- TODO: 样式调整 -->
      <!-- <div class="banner">
        <span class="primary-title">批阅详情</span>
      </div>-->

      <el-card class="overview-card" shadow="never">
        <div class="overview-title">概览</div>
        <el-row :gutter="16">
          <el-col :span="8">
            <div class="overview-item">
              <div class="overview-label">课程名称</div>
              <div class="overview-value" :title="workRecOverall.courseName">{{ workRecOverall.courseName || '-' }}</div>
            </div>
          </el-col>
          <el-col :span="8">
            <div class="overview-item">
              <div class="overview-label">课程包含作业数</div>
              <div class="overview-value">{{ workRecOverall.workNumber || 0 }}</div>
            </div>
          </el-col>
          <el-col :span="8">
            <div class="overview-item">
              <div class="overview-label">作业总数 / 待批阅数</div>
              <div class="overview-value">{{ workRecOverall.answerNumber || 0 }} / {{ workRecOverall.tobeReviewed || 0 }}</div>
            </div>
          </el-col>
        </el-row>
      </el-card>

      <!-- 数据列表-->
      <el-tabs v-model="recGroupIndex" @tab-click="handleClickRecGroupTap">
        <el-tab-pane
          v-for="(item, index) in (workRecOverall.recGroupDTOList || [])"
          :key="index"
          :label="item.teachplanName"
          :name="index.toString()"
        >
          <el-table
            class="dataList"
            :data="workRecordList"
            stripe
            size="small"
            border
            style="width: 100%"
            :header-cell-style="{ textAlign: 'center' }"
          >
            <el-table-column prop="username" label="用户名" align="center"></el-table-column>

            <el-table-column label="提交时间" align="center">
              <template slot-scope="scope">{{ scope.row.createDate | dateTimeFormat }}</template>
            </el-table-column>

            <el-table-column prop="correctComment" label="评语" align="center"></el-table-column>

            <el-table-column label="状态" align="center">
              <template slot-scope="scope">
                <el-tag :type="getCourseWorkStatusTagType(scope.row.status)" size="mini">{{ getCourseWorkStatus(scope.row.status) || '-' }}</el-tag>
              </template>
            </el-table-column>

            <el-table-column label="操作" align="center">
              <template slot-scope="scope">
                <el-button
                  type="text"
                  size="mini"
                  :disabled="scope.row.status !== '306002'"
                  @click="handleOpenWorkRecordDialog(scope.row)"
                >批阅</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </div>

    <!-- 上传资料对话框 -->
    <work-record-correction-dialog
      :dialogVisible.sync="dialogVisible"
      :question="question"
      :answer="answer"
      :workRecord="workRecord"
      @refreshList="loadOverall"
    ></work-record-correction-dialog>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator'
import WorkRecordCorrectionDialog from './components/work-record-correction-dialog.vue'
import { IKVData } from '@/api/types'
import { COURSE_WORK_STATUS } from '@/api/constants'
import {
  IWorkRecOverallDTO,
  IWorkRecGroupDTO,
  IWorkRecordDTO
} from '@/entity/work-record-page-list'
import { getWorkRecordPageList, defaultWorkRecord } from '@/api/work-record'
import { getBaseInfo, getOutline } from '@/api/courses'
import { ICourseOutlineTreeNode } from '@/entity/course-add-outline'
import { getCourseWorkList } from '@/api/works'

@Component({
  components: {
    WorkRecordCorrectionDialog
  }
})
export default class WorkRecordOverall extends Vue {
  // 批阅状态列表
  private courseWorkStatus: IKVData[] = COURSE_WORK_STATUS
  // 课程Id
  private courseId: number = 0
  // 作业批阅详情
  private workRecOverall: IWorkRecOverallDTO = {}
  // 课程计划索引
  private recGroupIndex: string = '0'
  // 作业提交记录
  private workRecordList: IWorkRecordDTO[] | undefined = []
  // 作业批阅对话框
  private dialogVisible: boolean = false
  // 单条作业
  private workRecord: IWorkRecordDTO = Object.assign({}, defaultWorkRecord)
  // 题目
  private question: string | undefined = ''
  // 学生作业详情
  private answer: string | undefined = ''

  // 计算属性
  getCourseWorkStatus(status: string) {
    let item = this.courseWorkStatus.find((value: IKVData) => {
      return status == value.code
    })
    return !item ? '' : item.desc
  }

  private getCourseWorkStatusTagType(status: string) {
    if (status === '306002') {
      return 'warning'
    }
    if (status === '306003') {
      return 'success'
    }
    if (status === '306001') {
      return 'info'
    }
    return 'info'
  }

  /**
   * 生命周期钩子
   */
  created() {
    let q: any = (this.$route && this.$route.query) ? (this.$route.query as any) : {}
    let courseId: any = (q && typeof q.courseId !== 'undefined') ? q.courseId : q.courseWorkId
    this.courseId = parseInt(courseId)
    if (isNaN(this.courseId as any)) {
      this.courseId = 0
    }
    this.loadOverall()
  }

  /**
   * 作业批阅详情
   */
  private async loadOverall() {
    if (!this.courseId) {
      this.workRecOverall = { recGroupDTOList: [] }
      this.workRecordList = []
      return
    }

    const [recordsRes, courseInfo, outline, courseWorkList] = await Promise.all([
      getWorkRecordPageList({ pageNo: 1, pageSize: 10000 }, {}),
      getBaseInfo(this.courseId),
      getOutline(this.courseId),
      getCourseWorkList(this.courseId).catch(() => [])
    ])

    const pageRoot: any = recordsRes && (recordsRes as any).data ? (recordsRes as any).data : recordsRes
    const rawItems: any[] = pageRoot && pageRoot.items ? pageRoot.items : []
    const courseRecords = (rawItems || []).filter((r: any) => r && String(r.courseId || '') === String(this.courseId))

    const { teachplanNameMap, teachplanWorkMap, workNumber, teachplanWorkOrder } = this.buildTeachplanMaps(outline, courseWorkList)

    const recordDtoList: IWorkRecordDTO[] = courseRecords.map((r: any) => {
      const tpId = r.teachplanId
      const tpKey = tpId !== undefined && tpId !== null ? String(tpId) : ''
      const tpName = teachplanNameMap[tpKey] || ''
      const workInfo: any = tpKey && teachplanWorkMap[tpKey] ? teachplanWorkMap[tpKey] : null
      const q = (workInfo && (workInfo.question || workInfo.title)) ? String(workInfo.question || workInfo.title) : ''
      return {
        workRecordId: r.id || r.workRecordId,
        coursePubId: r.coursePubId || 0,
        teachplanId: tpId || 0,
        teachplanName: tpName,
        workId: r.workId || 0,
        username: r.username,
        status: r.status,
        createDate: r.submitDate || r.createDate,
        correctionDate: r.correctionDate,
        correctComment: r.correctComment,
        answer: r.answer,
        question: q
      }
    })

    const groupMap: { [key: string]: IWorkRecordDTO[] } = {}
    recordDtoList.forEach((r) => {
      const key = r && r.teachplanId ? String(r.teachplanId) : '0'
      if (!groupMap[key]) {
        groupMap[key] = []
      }
      groupMap[key].push(r)
    })

    const orderedTeachplanIds: string[] = []
    ;(teachplanWorkOrder || []).forEach((id) => {
      if (orderedTeachplanIds.indexOf(id) < 0) {
        orderedTeachplanIds.push(id)
      }
    })
    Object.keys(groupMap).forEach((id) => {
      if (orderedTeachplanIds.indexOf(id) < 0) {
        orderedTeachplanIds.push(id)
      }
    })

    const recGroupDTOList: IWorkRecGroupDTO[] = orderedTeachplanIds.map((tpId) => {
      return {
        coursePubId: 0,
        teachplanId: parseInt(tpId, 10),
        teachplanName: teachplanNameMap[tpId] || tpId,
        workRecordList: groupMap[tpId] || []
      }
    })

    let tobeReviewed = 0
    let answerNumber = 0
    let commitedTime = ''
    let reviewedTime = ''
    const userSet: any = {}
    recordDtoList.forEach((r) => {
      if (!r) return
      answerNumber++
      if (r.status === '306002') {
        tobeReviewed++
      }
      if (r.username) {
        userSet[String(r.username)] = true
      }
      if (r.createDate && (!commitedTime || String(r.createDate) > String(commitedTime))) {
        commitedTime = String(r.createDate)
      }
      if (r.correctionDate && (!reviewedTime || String(r.correctionDate) > String(reviewedTime))) {
        reviewedTime = String(r.correctionDate)
      }
    })

    this.workRecOverall = {
      courseName: (courseInfo && (courseInfo as any).name) ? String((courseInfo as any).name) : '',
      workNumber,
      answerNumber,
      tobeReviewed,
      totalUsers: Object.keys(userSet).length,
      commitedTime,
      reviewedTime,
      recGroupDTOList
    }

    this.recGroupIndex = '0'
    if (this.workRecOverall.recGroupDTOList && this.workRecOverall.recGroupDTOList.length > 0) {
      this.workRecordList = this.workRecOverall.recGroupDTOList[0].workRecordList
    } else {
      this.workRecordList = []
    }
  }

  private buildTeachplanMaps(outline: any, courseWorkList: any) {
    const teachplanNameMap: { [key: string]: string } = {}
    const teachplanWorkMap: { [key: string]: any } = {}
    const teachplanWorkOrder: string[] = []
    const workTeachplanSet: any = {}

    const traverse = (nodes: ICourseOutlineTreeNode[]) => {
      if (!nodes || !Array.isArray(nodes)) return
      nodes.forEach((n: any) => {
        const id = n && (n.teachPlanId || n.teachplanId || n.id)
        const key = id !== undefined && id !== null ? String(id) : ''
        if (key) {
          teachplanNameMap[key] = n.pname || n.teachplanName || ''
          const w = n.work || n.workDTO || n.workDto
          if (w) {
            teachplanWorkMap[key] = w
            if (!workTeachplanSet[key]) {
              workTeachplanSet[key] = true
              teachplanWorkOrder.push(key)
            }
          }
        }
        const children = n.teachPlanTreeNodes || n.teachplanTreeNodes
        if (children && Array.isArray(children) && children.length > 0) {
          traverse(children)
        }
      })
    }

    let roots: any[] = []
    if (Array.isArray(outline)) {
      roots = outline
    } else if (outline && outline.teachPlanTreeNodes) {
      roots = outline.teachPlanTreeNodes
    } else if (outline) {
      roots = [outline]
    }
    traverse(roots as any)

    const list: any[] = Array.isArray(courseWorkList) ? courseWorkList : []
    list.forEach((it: any) => {
      if (!it) return
      const tpId = it.teachplanId || it.teachPlanId || it.teachplan_id || it.teach_plan_id || it.chapterId || it.chapter_id
      const key = tpId !== undefined && tpId !== null ? String(tpId) : ''
      if (!key) return
      if (!teachplanNameMap[key]) {
        teachplanNameMap[key] = it.teachplanName || it.teachPlanName || it.teachplan_name || it.teach_plan_name || it.pname || ''
      }
      if (!teachplanWorkMap[key]) {
        teachplanWorkMap[key] = {
          title: it.workTitle || it.workName || it.title || '',
          question: it.question || ''
        }
      }
      if (!workTeachplanSet[key]) {
        workTeachplanSet[key] = true
        teachplanWorkOrder.push(key)
      }
    })

    const workNumber = Object.keys(workTeachplanSet).length

    return { teachplanNameMap, teachplanWorkMap, workNumber, teachplanWorkOrder }
  }

  /**
   * 跳转到作业批改页面
   */
  private goToWorkRecordListView() {
    this.$router.go(-1)
  }

  /**
   * 点击Tap切换课程计划
   */
  private handleClickRecGroupTap(tab: any, event: any) {
    let index: number = parseInt(this.recGroupIndex)
    if (this.workRecOverall.recGroupDTOList) {
      this.workRecordList = this.workRecOverall.recGroupDTOList[
        index
      ].workRecordList
    }
  }

  /**
   * 打开作业批阅对话框
   */
  private handleOpenWorkRecordDialog(row: IWorkRecordDTO) {
    this.question = row.question
    this.answer = row.answer

    this.workRecord.coursePubId = row.coursePubId
    this.workRecord.teachplanId = row.teachplanId
    this.workRecord.teachplanName = row.teachplanName
    this.workRecord.workId = row.workId
    this.workRecord.workRecordId = row.workRecordId

    this.dialogVisible = true
  }
}
</script>

<style lang="scss" scoped>
.course-list {
  .overview-card {
    margin-top: 16px;
    margin-bottom: 8px;
    border-radius: 8px;
  }

  .overview-title {
    font-size: 14px;
    font-weight: 600;
    color: #303133;
    margin-bottom: 10px;
  }

  .overview-item {
    padding: 12px;
    border-radius: 8px;
    background: #f6f8fb;
    border: 1px solid #ebeef5;
  }

  .overview-label {
    font-size: 12px;
    color: #909399;
    margin-bottom: 6px;
  }

  .overview-value {
    font-size: 16px;
    font-weight: 600;
    color: #303133;
    line-height: 1.2;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .nav-bar {
    margin-top: 16px;
  }

  .workspace .banner .btn-add {
    float: right;
  }

  .searcher {
    margin-top: 16px;

    div {
      width: 218px;
      margin-right: 10px;
    }
  }

  .dataList {
    margin-top: 10px;
    border-radius: 8px;
    overflow: hidden;
  }

  .dataList-pagination {
    text-align: center;
    width: 100%;
  }
}
</style>
