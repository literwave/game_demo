# task persist (agent USER_TASK_COL.dat)
# 只存任务自己的状态。状态类条件接取时去对应模块取当前值，累加类条件按事件增量加
# _reset_time: 上次日常重置的时间，日、周都由它算

task_data {
    _task_id number
    _progress number
    _state number
}

task_bag <number, task_data>

user_task_doc {
    _tasks task_bag
    _reset_time number
    _main_id number
}
