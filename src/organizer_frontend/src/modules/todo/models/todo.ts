import dayjs from "../../../utils/date";

export enum TodoPriority {
  LOW = 1,
  NORMAL = 2,
  HIGH = 3
}

export enum TodoStatus {
  PENDING = 'pending',
  DONE = 'done'
}

export type TodoFormData = {
    uuid: string;
    resume: string;
    description: string;
    scheduledDate: string;
    priority: TodoPriority;
    status: TodoStatus;
};

export class Todo {
    uuid: string;
    resume: string;
    description: string;
    scheduledDate: string;
    priority: TodoPriority;
    status: TodoStatus;
    createdAt: Date

    constructor(data: TodoFormData) {
        this.uuid = data.uuid;
        this.resume = data.resume;
        this.description = data.description;
        this.scheduledDate = data.scheduledDate;
        this.priority = data.priority;
        this.status = data.status;
        this.createdAt = new Date();
    }

    getRemainingTimeStr(): string {
        if (this.scheduledDate != "") {
            return dayjs(this.scheduledDate).fromNow();
        }

		return ""
    }

	getScheduledDateStr(): string {
		if (this.scheduledDate != "") {
            return dayjs(this.scheduledDate).format("DD/MM/YYYY HH:mm");
        }

		return ""
	}
}