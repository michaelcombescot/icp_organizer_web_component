import { todoStore } from "./store";
import { ComponentTodoForm } from "./component_todo_form";
import { ComponentTodoShow } from "./component_todo_show";
import dayjs from "../../utils/date";
import { css, html, LitElement } from "lit";
import { property, customElement } from "lit/decorators.js";
import { openModal } from "../../components/modal";

interface TodoParams {
    id: string;
    resume: string;
    description: string;
    scheduledDate: string;
    priority: Priority;
    status: Status;
}

enum Priority {
    High = 3,
    Medium = 2,
    Low = 1
}

type Status = "done" | "pending";

class Todo {
    id: string;
    resume: string;
    description: string;
    scheduledDate: string;
    priority: Priority;
    status: Status;

    constructor(todoParams: TodoParams) {
        this.id = todoParams.id;
        this.resume = todoParams.resume;
        this.description = todoParams.description;
        this.scheduledDate = todoParams.scheduledDate;
        this.priority = todoParams.priority;
        this.status = todoParams.status;
    }
}

@customElement("component-todo")
class ComponentTodo extends LitElement {
    @property({ type: Object }) todo!: Todo 
    get idStr() { return this.todo ? `todo-item-${this.todo.id}` : '' }

    static create(todo: Todo) {
        const compTodo = new ComponentTodo();
        compTodo.todo = todo;
        return compTodo;
    }

    handleDone(): void { this.shadowRoot!.querySelector(`#${this.idStr}`)!.classList.toggle("done") }

    handleOpenEdit(): void { openModal(ComponentTodoForm.create(this)) }

    handleOpenShow(): void { openModal(ComponentTodoShow.create(this)) }

    handleDelete(): void {
        todoStore.deleteTodo(this.todo!.id);
        this.remove();
    }

    static styles = css`
        .todo-item {
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
            gap: 1em;
            border-radius: 10px;
            background-color: white;
            padding: 1em;
            
            &.done { background-color: green; }
            
            .todo-item-actions {
                display: flex;
                justify-content: space-between;
            }

            .todo-date {
                display: flex;
                gap: 1em;
                justify-content: space-between;
            }

            .todo-resume {
                &.high { background-color: red; }
                &.medium { background-color: yellow; }
            }
        }
    `

    protected render() {
        let scheduledDate: string | null = null
        let remainingTime: string | null = null
        if (this.todo!.scheduledDate != "") {
            scheduledDate = dayjs(this.todo!.scheduledDate).format("DD/MM/YYYY HH:mm");
            remainingTime = dayjs(this.todo!.scheduledDate).fromNow();
        }

        return html `
            <div id="${this.idStr}" class="todo-item">
                ${scheduledDate != null ?
                    html`
                        <div class="todo-date">
                            <span>${scheduledDate}</span>
                            <span>${remainingTime}</span>
                        </div>
                    ` : ""
                }
                <div class="todo-resume ${this.todo!.priority}" @click=${this.handleOpenShow}>${this.todo!.resume}</div>
                <div class="todo-item-actions">
                    <button id="todo-action-edit" @click=${this.handleOpenEdit}>Edit</button>
                    <button id="todo-action-delete" @click=${this.handleDelete}>Delete</button>
                    <button id="todo-action-done" @click=${this.handleDone}>Done</button>
                </div>
            </div>
        `
    }
}

export { ComponentTodo, Todo };
export type { TodoParams, Priority }