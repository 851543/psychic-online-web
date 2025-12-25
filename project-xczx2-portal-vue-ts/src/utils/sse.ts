import { getToken } from '@/utils/cookies'
import { closeSse } from '@/api/sse'
import { fetchEventSource } from '@microsoft/fetch-event-source'

/**
 * SSE 工具类
 */
export class SSEManager {
  private abortController: AbortController | null = null
  private uid: string
  private isConnected: boolean = false

  constructor(uid: string) {
    this.uid = uid
  }

  /**
   * 创建 SSE 连接
   * @param onMessage 消息回调
   * @param onError 错误回调
   */
  async connect(onMessage?: (event: MessageEvent) => void, onError?: (event: Event) => void) {
    // 如果已存在连接，先关闭
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }

    const token = getToken()
    const url = `http://localhost:8601/api/content/sse/${this.uid}`
    const uid = this.uid
    
    console.log(`正在建立 SSE 连接 - 用户ID: ${uid}`)
    
    // 创建 AbortController 用于控制连接
    this.abortController = new AbortController()
    this.isConnected = true

    try {
      await fetchEventSource(url, {
        method: 'GET',
        headers: {
          'Authorization': token ? `Bearer ${token}` : '',
          'Accept': 'text/event-stream'
        },
        signal: this.abortController.signal,
        onmessage(ev) {
          // 创建 MessageEvent 对象以保持兼容性
          const messageEvent = new MessageEvent('message', {
            data: ev.data
          })
          onMessage && onMessage(messageEvent)
        },
        onerror(err) {
          // 创建 Event 对象以保持兼容性
          const errorEvent = new Event('error')
          onError && onError(errorEvent)
          // 返回 undefined 表示不重试，抛出错误表示重试
          throw err
        },
        async onopen() {
          console.log(`SSE 连接成功 - 用户ID: ${uid}`)
          // 连接打开
        }
      })
    } catch (error) {
      // 如果是手动取消，不触发错误回调
      if (error instanceof Error && error.name === 'AbortError') {
        return
      }
      onError && onError(new Event('error'))
    } finally {
      this.isConnected = false
    }
  }

  /**
   * 关闭 SSE 连接
   */
  async close() {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
      this.isConnected = false
      
      // 调用后端关闭接口，静默处理错误
      try {
        await closeSse(this.uid)
      } catch (error) {
        // 关闭失败时静默处理，不抛出错误
        // 因为连接可能已经断开或服务不可用
      }
    }
  }

  /**
   * 获取连接状态
   */
  get readyState(): number {
    if (this.isConnected) {
      return 1 // OPEN
    }
    // EventSource.CONNECTING = 0, EventSource.OPEN = 1, EventSource.CLOSED = 2
    return 2 // CLOSED
  }
}

