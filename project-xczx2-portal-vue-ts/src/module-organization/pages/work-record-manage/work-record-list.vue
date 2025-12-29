<template>
  <div class="course-list portal-content">
    <div class="workspace">
      <div class="banner">
        <span class="primary-title">作业批改</span>
      </div>

      <!-- 搜索栏 -->
      <!-- <div class="searcher">
        <el-input
          class="el-input"
          placeholder="请输入课程名称"
          suffix-icon="el-icon-search"
          v-model="listQueryData.courseName"
        />
      </div> -->

      <!-- 数据列表 -->
      <el-table
        class="dataList"
        v-loading="listLoading"
        :data="listResult.items"
        border
        style="width: 100%"
        :header-cell-style="{ textAlign: 'center' }"
      >
        <el-table-column prop="courseName" label="课程名称" width="400" align="center"></el-table-column>

        <el-table-column prop="totalUsers" label="答题人数" align="center"></el-table-column>

        <el-table-column prop="tobeReviewed" label="待批阅数" align="center"></el-table-column>

        <el-table-column label="最后提交/最后批阅" align="center">
          <template slot-scope="scope">
            {{ scope.row.commitedTime | dateTimeFormat }}
            <br />
            {{ scope.row.reviewedTime | dateTimeFormat }}
          </template>
        </el-table-column>

        <el-table-column label="操作" align="center">
          <template slot-scope="scope">
            <el-button
              type="text"
              size="mini"
              @click="goToWorkRecordReadOverAllView(scope.row.courseWorkId)"
            >批阅</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 翻页控制 -->
      <div class="dataList-pagination">
        <Pagination
          v-show="listResult.counts > 0"
          :total="listResult.counts"
          :page.sync="listQuery.pageNo"
          :limit.sync="listQuery.pageSize"
          @pagination="getWorkRecordPageList"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Vue, Watch } from 'vue-property-decorator'
import Pagination from '@/components/pagination/index.vue'
import { IWorkRecordPageVO, ICourseWorkDTO } from '@/entity/work-record-page-list'
import { getWorkRecordPageList } from '@/api/work-record'
import { getBaseInfo } from '@/api/courses'

@Component({
  components: {
    Pagination
  }
})
export default class WorkRecordList extends Vue {
  // 是否载入中
  private listLoading: boolean = false
  private courseNameCache: { [key: string]: string } = {}
  // 请求参数Query
  private listQuery = {
    pageNo: 1,
    pageSize: 10
  }
  // 请求参数body
  private listQueryData = {
    courseName: ''
  }
  // 作业提交列表
  private listResult: IWorkRecordPageVO = {}

  /**
   * 作业提交列表
   */
  private async getWorkRecordPageList() {
    this.listLoading = true
    try {
      const res = await getWorkRecordPageList({ pageNo: 1, pageSize: 10000 }, {})
      const raw = this.normalizePageResult(res)
      const recordItems: any[] = (raw && (raw as any).items) ? ((raw as any).items as any[]) : []

      const courseAgg: { [key: string]: any } = {}
      recordItems.forEach((r: any) => {
        if (!r) return
        const courseId = r.courseId
        if (courseId === undefined || courseId === null || String(courseId) === '') return
        const key = String(courseId)
        if (!courseAgg[key]) {
          courseAgg[key] = {
            courseId,
            usernames: {},
            tobeReviewed: 0,
            commitedTime: '',
            reviewedTime: ''
          }
        }
        const agg = courseAgg[key]
        const username = r.username ? String(r.username) : ''
        if (username) {
          agg.usernames[username] = true
        }
        if (String(r.status || '') === '306002') {
          agg.tobeReviewed++
        }
        const submitTime = r.submitDate || r.createDate || r.changeDate || ''
        if (submitTime && (!agg.commitedTime || String(submitTime) > String(agg.commitedTime))) {
          agg.commitedTime = submitTime
        }
        const reviewTime = r.correctionDate || ''
        if (reviewTime && (!agg.reviewedTime || String(reviewTime) > String(agg.reviewedTime))) {
          agg.reviewedTime = reviewTime
        }
      })

      const courseIds = Object.keys(courseAgg)
      await Promise.all(
        courseIds.map(async (cid) => {
          if (this.courseNameCache[cid] !== undefined) {
            return
          }
          try {
            const info: any = await getBaseInfo(parseInt(cid, 10))
            this.courseNameCache[cid] = info && (info.name || info.courseName) ? String(info.name || info.courseName) : ''
          } catch (e) {
            this.courseNameCache[cid] = ''
          }
        })
      )

      let summaryItems: ICourseWorkDTO[] = courseIds.map((cid) => {
        const agg = courseAgg[cid]
        return {
          courseWorkId: agg.courseId,
          courseName: this.courseNameCache[cid] || '',
          totalUsers: Object.keys(agg.usernames || {}).length,
          tobeReviewed: agg.tobeReviewed || 0,
          commitedTime: agg.commitedTime || '',
          reviewedTime: agg.reviewedTime || ''
        }
      })

      const keyword = this.listQueryData && this.listQueryData.courseName ? String(this.listQueryData.courseName).trim() : ''
      if (keyword) {
        summaryItems = summaryItems.filter((it) => String((it && it.courseName) || '').indexOf(keyword) >= 0)
      }

      summaryItems.sort((a: any, b: any) => {
        const at = a && a.commitedTime ? String(a.commitedTime) : ''
        const bt = b && b.commitedTime ? String(b.commitedTime) : ''
        return bt.localeCompare(at)
      })

      const counts = summaryItems.length
      const pageSize = this.listQuery.pageSize || 10
      const pages = Math.max(1, Math.ceil(counts / pageSize))
      const pageNo = Math.min(Math.max(this.listQuery.pageNo || 1, 1), pages)
      const start = (pageNo - 1) * pageSize
      const end = Math.min(start + pageSize, counts)

      this.listResult = {
        counts,
        items: summaryItems.slice(start, end),
        page: pageNo,
        pages,
        pageSize
      }
    } catch (e) {
      this.listResult = {}
    } finally {
      this.listLoading = false
    }
  }

  private normalizePageResult(res: any): IWorkRecordPageVO {
    if (!res || typeof res !== 'object') {
      return {}
    }
    const root: any = (res && (res.data || res.result)) ? (res.data || res.result) : res
    const items = root.items || root.records || root.list || root.rows || []
    const counts =
      (typeof root.counts !== 'undefined' ? root.counts : undefined) ||
      (typeof root.total !== 'undefined' ? root.total : undefined) ||
      (typeof root.totalElements !== 'undefined' ? root.totalElements : undefined) ||
      (typeof root.totalCount !== 'undefined' ? root.totalCount : undefined) ||
      (Array.isArray(items) ? items.length : 0)
    const page = root.page || root.pageNo || root.current || 1
    const pageSize = root.pageSize || root.size || root.limit || this.listQuery.pageSize || 10
    const pages = root.pages || root.totalPages || Math.max(1, Math.ceil((counts || 0) / (pageSize || 10)))
    return {
      counts,
      items,
      page,
      pages,
      pageSize
    }
  }

  /**
   * 跳转到批阅详情页面
   */
  private goToWorkRecordReadOverAllView(courseWorkId: number) {
    this.$router.push({
      path: `/organization/work-record-overall?courseId=${courseWorkId}`
    })
  }

  // 监控 watch
  // 搜索栏
  @Watch('listQueryData', { deep: true, immediate: true })
  private watchListQueryData(newVal: string) {
    if (newVal == '') {
      return
    }
    this.getWorkRecordPageList()
  }

  // 翻页 pageSize
  @Watch('listQuery.pageSize', { immediate: true })
  private watchListQueryPageSize(newVal: number) {
    this.listQuery.pageNo = 1
  }

  private created() {}
}
</script>

<style lang="scss" scoped>
.course-list {
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
    margin-top: 16px;
  }

  .dataList-pagination {
    text-align: center;
    width: 100%;
  }
}
</style>

