<template>
  <router-view />
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator'
import { SSEManager } from '@/utils/sse'
import { UserModule } from '@/store/modules/user'
import { getName } from '@/utils/cookies'

@Component
export default class App extends Vue {
  private sseManager: SSEManager | null = null

  mounted() {

    // 获取用户ID，优先使用 userId，否则使用 name
    const uid = String(UserModule.userId)

    if (uid) {
      this.sseManager = new SSEManager(uid)

      this.sseManager.connect(
        (event) => {
          // 接收消息时提示，空字符串不提示
          if (event.data && event.data.trim()) {
            this.$message.success(event.data)
          }
        },
        (error) => {
          // 错误处理
          this.$message.error('SSE 连接错误')
        }
      )
    }
  }

  beforeDestroy() {
    // 组件销毁时关闭连接，静默处理错误
    if (this.sseManager) {
      this.sseManager.close().catch(() => {
        // 静默处理关闭错误
      })
    }
  }
}
</script>

<style lang="scss">
</style>
