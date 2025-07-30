import dayjs from "../../../utils/date";
import { TodoPriority , TodoStatus } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import {List} from "./list";

export interface TodoFormData {
    uuid: string;
    resume: string;
    description: string;
    scheduledDate: bigint;
    priority: TodoPriority;
    status: TodoStatus;
    listUUID: string;
    list?: List
}

export const priorityValues = ["low", "medium", "high"]

export class Todo {
    uuid: string;
    resume: string;
    description: string;
    scheduledDate: bigint;
    priority: TodoPriority;
    status: TodoStatus;
    createdAt: bigint;
    listUUID: string
    list?: List

    constructor(data: TodoFormData) {
        this.uuid = data.uuid;
        this.resume = data.resume;
        this.description = data.description;
        this.scheduledDate = data.scheduledDate;
        this.priority = data.priority;
        this.status = data.status;
        this.createdAt = BigInt(dayjs().valueOf());
        this.listUUID = data.listUUID
        this.list = data.list
    }
}

export const priorityOrder: Record<keyof TodoPriority, number> = {
    low: 0,
    medium: 1,
    high: 2,
};

export enum TodoListType {
    PRIORITY = "priority",
    SCHEDULED = "scheduled"
}

export const sortByScheduledDate = (todos : Todo[]) : Todo[] => {
    return todos.sort((a, b) => Number(a.scheduledDate) - Number(b.scheduledDate))
}

export const sortByPriority = (todos : Todo[]) : Todo[] => {
    return todos.sort((a, b) => {
        const aLevel = priorityOrder[Object.keys(a.priority)[0] as keyof TodoPriority];
        const bLevel = priorityOrder[Object.keys(b.priority)[0] as keyof TodoPriority];
        return bLevel - aLevel; // descending (high → low)
    })
}