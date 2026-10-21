# queue persist (agent QUEUE_COL.dat)

queue_work {
    target_id number
}

queue_work_map <number, queue_work>

queue_data {
    _user_id number
    _queue_idx number
    _queue_tbl queue_work_map
    _work_idx number
    _expire_time number
}

queue_bag <number, queue_data>

user_queue_doc {
    _queues queue_bag
}
