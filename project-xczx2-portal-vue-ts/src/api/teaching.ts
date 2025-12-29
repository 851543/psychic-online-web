import { createAPI } from '@/utils/request'

// 作业绑定
export async function workAssociation(
  teachplanId: number,
  id: number,
  courseId: number
) {
  await createAPI(`/teaching/work/association`, 'post', undefined, {
    teachplanId,
    id,
    courseId
  })
}
