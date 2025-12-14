<template>
  <el-dialog title="绑定用户" :visible.sync="syncDialogVisible">
    <div class="types">
      <el-form label-width="100px">
        <!-- 查询邮箱 -->
        <el-form-item label="邮箱：">
          <el-input v-model="email" @keyup.enter="handleSubmit" placeholder="输入邮箱 回车确认"></el-input>
        </el-form-item>
        <!-- 用户信息 -->
        <el-form-item label="昵称：">
          <el-input v-model="member.name" :disabled="true"></el-input>
        </el-form-item>
        <el-form-item label="介绍：">
          <el-input v-model="member.intro" type="textarea" :rows="5" :disabled="true"></el-input>
        </el-form-item>
      </el-form>
    </div>
    <div slot="footer">
      <el-button @click="handleCancel">取消</el-button>
      <el-button type="primary" @click="handleSubmit">提交</el-button>
    </div>
  </el-dialog>
</template>

<style lang="scss" scoped>
.types {
  text-align: center;
}
</style>

<script lang="ts">
import { Component, Prop, PropSync, Watch, Vue } from 'vue-property-decorator'
import { IMemberDTO } from '@/entity/learning-member'
import { findUserByEmail, bindUser } from '@/api/learning-member'

@Component({
  name: 'MemberBindDialog',
  components: {}
})
export default class extends Vue {
  @PropSync('dialogVisible', { type: Boolean, default: false })
  syncDialogVisible!: boolean

  private submitting: boolean = false
  private email: string = ''
  private member: IMemberDTO = {
    name: '',
    phone: '',
    username: '',
    verifyCode: '',
    verifyKey: ''
  }
  private selValue: any = null

  public restForm() {
    this.submitting = false
    this.email = ''
    this.member = {
      name: '',
      phone: '',
      username: '',
      verifyCode: '',
      verifyKey: ''
    }
    this.selValue = null
  }

  // async remoteQuery() {
  //   if (this.email == '') {
  //     return
  //   }
  //   this.member = await findUserByEmail(this.email)
  //   this.syncDialogVisible = false
  //   this.$emit('getList')
  // }

  handleCancel() {
    this.syncDialogVisible = false
  }
  async handleSubmit() {
    // 防止重复提交
    if (this.submitting) {
      return
    }
    // if (this.member.userId) {
    //   await bindUser(this.member.phone, this.member.userId)
    //   this.syncDialogVisible = false
    //   this.$emit('getList')
    // }
    if (this.email == '') {
      return
    }
    this.submitting = true
    try {
      this.member = await findUserByEmail(this.email)
      this.syncDialogVisible = false
      this.$emit('getList')
    } finally {
      this.submitting = false
    }
  }
}
</script>
