import dayjs from "../../../utils/date";
import {organizer_backend} from "../../../../../declarations/organizer_backend";

export interface TodoFormData {
    uuid: string;
    resume: string;
    description: string;
    scheduledDate: bigint;
    priority: TodoPriority;
    status: TodoStatus;
}

export type TodoPriority = Parameters<typeof organizer_backend.addTodo>[0]["priority"];
export const todoPriorityValues = ['low', 'medium', 'high']

export type TodoStatus = Parameters<typeof organizer_backend.addTodo>[0]["status"];


export class Todo implements Todo {
    uuid: string;
    resume: string;
    description: string;
    scheduledDate: bigint;
    priority: TodoPriority;
    status: TodoStatus;
    createdAt: bigint;

    constructor(data: TodoFormData) {
        this.uuid = data.uuid;
        this.resume = data.resume;
        this.description = data.description;
        this.scheduledDate = data.scheduledDate;
        this.priority = data.priority;
        this.status = data.status;
        this.createdAt = BigInt(dayjs().valueOf());
    }
}

export enum TodoListType {
    PRIORITY = "priority",
    SCHEDULED = "scheduled"
}
