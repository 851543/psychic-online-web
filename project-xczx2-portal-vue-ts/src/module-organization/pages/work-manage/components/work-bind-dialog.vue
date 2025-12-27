<template>
  <el-dialog
    title="绑定课程章节"
    :visible.sync="syncDialogVisible"
    width="600px"
    @close="handleClose"
  >
    <el-form ref="form" :model="bindForm" :label-width="formLabelWidth">
      <el-form-item label="选择课程：" prop="courseId">
        <el-select
          v-model="bindForm.courseId"
          filterable
          placeholder="请选择课程"
          @change="handleCourseChange"
          style="width: 100%"
        >
          <el-option
            v-for="item in courseList"
            :key="item.id || item.courseBaseId"
            :label="item.name"
            :value="item.id || item.courseBaseId"
          ></el-option>
        </el-select>
      </el-form-item>

      <el-form-item prop="teachplanId">
        <template slot="label">
          <span>选择章节：</span>
        </template>
        <el-tree
          v-if="chapterTree.length > 0"
          ref="tree"
          :data="chapterTree"
          :props="treeProps"
          node-key="teachPlanId"
          show-checkbox
          :check-strictly="true"
          @check="handleChapterCheck"
          @node-click="handleNodeClick"
          class="chapter-tree"
          style="max-height: 300px; overflow-y: auto; border: 1px solid #dcdfe6; padding: 10px; border-radius: 4px;"
        ></el-tree>
        <div v-else-if="bindForm.courseId" style="color: #909399; padding: 20px; text-align: center;">
          该课程暂无章节，请先添加章节
        </div>
        <div v-else style="color: #909399; padding: 20px; text-align: center;">
          请先选择课程
        </div>
      </el-form-item>
    </el-form>

    <div slot="footer" class="dialog-footer">
      <el-button @click="syncDialogVisible = false">取 消</el-button>
      <el-button type="primary" @click="handleBind" :loading="bindLoading">确 定</el-button>
    </div>
  </el-dialog>
</template>

<script lang="ts">
import { Component, Vue, Prop, PropSync, Watch } from 'vue-property-decorator'
import { Form as ElForm } from 'element-ui'
import { list } from '@/api/courses'
import { getOutline } from '@/api/courses'
import { workAssociation } from '@/api/teaching'
import { ICoursePageList, ICourseBaseDTO } from '@/entity/course-page-list'
import { ICourseOutlineTreeNode } from '@/entity/course-add-outline'

@Component
export default class WorkBindDialog extends Vue {
  @PropSync('dialogVisible', { type: Boolean, required: true, default: false })
  syncDialogVisible!: boolean
  @Prop({ type: Number, required: true })
  readonly workId!: number
  @Prop({ type: Number, default: null })
  readonly teachplanId!: number | null

  private formLabelWidth: string = '120px'
  private bindLoading: boolean = false
  private courseList: ICourseBaseDTO[] = []
  private chapterTree: ICourseOutlineTreeNode[] = []
  private selectedTeachplanId: number | null = null

  private bindForm = {
    courseId: null as number | null,
    teachplanId: null as number | null
  }

  private treeProps = {
    children: 'teachPlanTreeNodes',
    label: 'pname'
  }

  /**
   * 对话框打开时加载课程列表
   */
  @Watch('syncDialogVisible')
  private async onDialogVisibleChange(visible: boolean) {
    if (visible) {
      console.log('绑定对话框打开，接收到的workId:', this.workId, 'teachplanId:', this.teachplanId)
      if (!this.workId || this.workId === 0) {
        console.error('警告：workId无效或为0')
      }
      await this.loadCourseList()
      this.resetForm()
      
      // 如果有 teachplanId，自动选中对应的课程和章节
      if (this.teachplanId) {
        await this.selectCourseAndChapterByTeachplanId(this.teachplanId)
      }
    }
  }

  /**
   * 加载课程列表
   */
  private async loadCourseList() {
    try {
      const result: ICoursePageList = await list(undefined, {
        pageNo: 1,
        pageSize: 1000
      })
      this.courseList = result.items || []
    } catch (error) {
      this.$message.error('加载课程列表失败')
      console.error(error)
    }
  }

  /**
   * 根据 teachplanId 自动选中对应的课程和章节
   */
  private async selectCourseAndChapterByTeachplanId(teachplanId: number) {
    // 遍历所有课程，查找包含该 teachplanId 的课程
    for (const course of this.courseList) {
      const courseId = course.id || course.courseBaseId
      if (!courseId) continue

      try {
        const outline: any = await getOutline(courseId)
        let treeData: ICourseOutlineTreeNode[] = []
        
        if (Array.isArray(outline)) {
          treeData = outline
        } else if (outline && outline.teachPlanTreeNodes) {
          treeData = outline.teachPlanTreeNodes
        } else if (outline) {
          treeData = [outline]
        }

        // 递归查找是否包含该 teachplanId
        const findTeachplan = (nodes: ICourseOutlineTreeNode[]): ICourseOutlineTreeNode | null => {
          for (const node of nodes) {
            const nodeId = node.teachPlanId || (node as any).id
            if (nodeId === teachplanId) {
              return node
            }
            if (node.teachPlanTreeNodes && node.teachPlanTreeNodes.length > 0) {
              const found = findTeachplan(node.teachPlanTreeNodes)
              if (found) return found
            }
          }
          return null
        }

        const foundNode = findTeachplan(treeData)
        if (foundNode) {
          // 找到了，选中该课程
          this.bindForm.courseId = courseId
          
          // 直接加载章节树（不调用 handleCourseChange，避免清空选中状态）
          const flattenedTree = this.flattenTreeNodes(treeData)
          this.chapterTree = flattenedTree
          
          // 等待 DOM 更新后选中对应的章节
          await this.$nextTick()
          const tree = this.$refs.tree as any
          if (tree) {
            tree.setChecked(teachplanId, true, false)
            this.selectedTeachplanId = teachplanId
          }
          return
        }
      } catch (error) {
        console.error(`加载课程 ${courseId} 的章节失败:`, error)
        continue
      }
    }
    
    // 如果没找到，提示用户
    this.$message.warning('未找到对应的课程章节信息')
  }

  /**
   * 课程选择变化时加载章节树
   */
  private async handleCourseChange(courseId: number) {
    if (!courseId) {
      this.chapterTree = []
      this.selectedTeachplanId = null
      return
    }

    try {
      const outline: any = await getOutline(courseId)
      // 处理返回的数据结构
      let treeData: ICourseOutlineTreeNode[] = []
      
      // 如果返回的是数组，直接使用
      if (Array.isArray(outline)) {
        treeData = outline
      } 
      // 如果返回的是对象，取它的 teachPlanTreeNodes
      else if (outline && outline.teachPlanTreeNodes) {
        treeData = outline.teachPlanTreeNodes
      }
      // 如果都没有，尝试将对象包装成数组
      else if (outline) {
        treeData = [outline]
      }
      
      // 过滤并展平树形结构，只显示 grade=2 的小节
      this.chapterTree = this.flattenTreeNodes(treeData)
      this.selectedTeachplanId = null
      
      // 清空之前的选中状态
      if (this.$refs.tree) {
        ;(this.$refs.tree as any).setCheckedKeys([])
      }
    } catch (error) {
      this.$message.error('加载章节列表失败')
      console.error(error)
      this.chapterTree = []
    }
  }

  /**
   * 展平树形结构，只保留 grade=2 的小节
   */
  private flattenTreeNodes(nodes: ICourseOutlineTreeNode[]): ICourseOutlineTreeNode[] {
    const result: ICourseOutlineTreeNode[] = []
    
    const traverse = (nodeList: ICourseOutlineTreeNode[]) => {
      nodeList.forEach(node => {
        // 只添加 grade=2 的小节
        if (node.grade === 2) {
          // 确保有 teachPlanId，如果没有则使用 id
          const nodeId = node.teachPlanId || (node as any).id
          result.push({
            ...node,
            teachPlanId: nodeId,
            teachPlanTreeNodes: [] // 设置为空数组，因为只显示小节
          })
        }
        // 递归处理子节点
        if (node.teachPlanTreeNodes && node.teachPlanTreeNodes.length > 0) {
          traverse(node.teachPlanTreeNodes)
        }
      })
    }
    
    traverse(nodes)
    return result
  }

  /**
   * 点击节点名称时切换选中状态
   */
  private handleNodeClick(data: ICourseOutlineTreeNode) {
    const tree = this.$refs.tree as any
    if (!tree) return

    const nodeKey = data.teachPlanId || (data as any).id
    const checkedKeys = tree.getCheckedKeys()
    const isChecked = checkedKeys.includes(nodeKey)

    if (isChecked) {
      // 如果已选中，取消选中
      tree.setChecked(nodeKey, false, false)
      this.selectedTeachplanId = null
    } else {
      // 如果未选中，先取消所有其他节点的选中
      checkedKeys.forEach((key: any) => {
        if (key !== nodeKey) {
          tree.setChecked(key, false, false)
        }
      })
      // 然后选中当前节点
      tree.setChecked(nodeKey, true, false)
      this.selectedTeachplanId = nodeKey
    }
  }

  /**
   * 章节选择变化（点击勾选框时触发）
   */
  private handleChapterCheck(data: ICourseOutlineTreeNode, checked: any) {
    const tree = this.$refs.tree as any
    if (!tree) return

    const checkedKeys = checked.checkedKeys || []
    const clickedKey = data.teachPlanId || (data as any).id

    // 使用 $nextTick 确保在 DOM 更新后处理
    this.$nextTick(() => {
      // 如果当前点击的节点在选中列表中，说明刚被选中了
      if (checkedKeys.includes(clickedKey)) {
        // 单选模式：取消所有其他节点的选中，只保留当前点击的节点
        const allCheckedKeys = tree.getCheckedKeys()
        allCheckedKeys.forEach((key: any) => {
          if (key !== clickedKey) {
            tree.setChecked(key, false, false)
          }
        })
        // 保存当前选中的节点
        this.selectedTeachplanId = clickedKey
      } else {
        // 如果不在选中列表中，说明刚被取消选中了
        this.selectedTeachplanId = null
      }
    })
  }

  /**
   * 绑定作业到章节
   */
  private async handleBind() {
    if (!this.bindForm.courseId) {
      this.$message.warning('请选择课程')
      return
    }

    if (!this.selectedTeachplanId) {
      this.$message.warning('请选择章节')
      return
    }

    if (!this.workId || this.workId === 0) {
      this.$message.error('作业ID无效，无法绑定')
      console.error('workId值:', this.workId)
      return
    }

    this.bindLoading = true
    try {
      await workAssociation(
        this.selectedTeachplanId,
        this.workId
      )

      this.$message.success('绑定成功')
      this.syncDialogVisible = false
      this.refreshList()
    } finally {
      this.bindLoading = false
    }
  }

  /**
   * 重置表单
   */
  private resetForm() {
    this.bindForm = {
      courseId: null,
      teachplanId: null
    }
    this.chapterTree = []
    this.selectedTeachplanId = null
    if (this.$refs.tree) {
      ;(this.$refs.tree as any).setCheckedKeys([])
    }
  }

  /**
   * 关闭对话框
   */
  private handleClose() {
    this.resetForm()
  }

  /**
   * 刷新列表
   */
  private refreshList() {
    this.$emit('refreshList')
  }
}
</script>

<style lang="scss" scoped>
.dialog-footer {
  text-align: right;
}

// 增加勾选框与文本之间的间距，并让节点名称可点击
::v-deep .chapter-tree {
  .el-tree-node__content {
    .el-checkbox {
      margin-right: 12px;
    }
    
    // 让节点名称区域可点击，鼠标悬停时显示手型光标
    .el-tree-node__label {
      cursor: pointer;
      user-select: none;
      
      &:hover {
        color: #409eff;
      }
    }
  }
}
</style>

