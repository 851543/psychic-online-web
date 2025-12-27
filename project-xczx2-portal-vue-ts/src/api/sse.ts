import { createAPI } from '@/utils/request'

/**
 * 关闭 SSE 连接
 * @param uid 用户ID
 */
export async function closeSse(uid: string): Promise<string> {
  const { data } = await createAPI(`/content/sse/${uid}`, 'delete')
  return data
}





