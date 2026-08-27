# queue persist (agent QUEUE_COL.dat)

QueueWork {
    targetId number
}

QueueWorkMap <number, QueueWork>

QueueData {
    _userId string
    _queueIdx number
    _queueTbl QueueWorkMap
    _workIdx number
    _expireTime number
}

QueueBag <number, QueueData>

UserQueueDoc {
    _queues QueueBag
}
