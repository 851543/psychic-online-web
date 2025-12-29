import { createAPI } from '@/utils/request'
import {
  IWorkRecordPageVO,
  IWorkRecordDTO
} from '@/entity/work-record-page-list'

export const defaultWorkRecord: IWorkRecordDTO = {
  coursePubId: 0,
  teachplanId: 0,
  teachplanName: '',
  workId: 0
}

// 作业提交记录[按照课程分组]
export async function getWorkRecordPageList(
  params: any,
  body: any
): Promise<IWorkRecordPageVO> {
  const { data } = await createAPI(
    '/teaching/work/record/list',
    'post',
    params,
    body
  )
  return data
}

// 批改作业
export async function correctionWorkRecord(body: any): Promise<IWorkRecordDTO> {
  const { data } = await createAPI(
      '/teaching/work/record/correction',
      'put',
      null,
      body
    )
    return data
}
