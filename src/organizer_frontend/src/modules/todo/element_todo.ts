import { todoStore } from "./store";
import { TodoFormElement } from "./element_todo_form";
import { TodoShowElement } from "./element_todo_show";
import dayjs from "dayjs";

interface TodoParams {
    id: string;
    resume: string;
    description: string;
    scheduledDate: string;
    priority: Priority;
    status: Status;
}

type Priority = "high" | "medium" | "low";
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

class TodoElement extends HTMLElement {
    //
    // CONST
    //

    #idStr: string

    //
    // PROPERTIES
    //
    #todo: Todo;
    get todo(): Todo {
        return this.#todo;
    }
    set todo(todo: Todo) {
        this.#todo = todo;
        this.render();
    }

    //
    // INITIALIZATION
    //
    constructor(todo: Todo) {
        super();

        this.#todo = todo;

        this.#idStr = `todo-item-${this.#todo.id}`
    }

    connectedCallback(): void {
        this.render();
    }

    //
    // TRIGGERS
    //

    handleDone(): void {
        this.querySelector("#todo-action-done")!.addEventListener("click", () => {
            this.querySelector(`#${this.#idStr}`)!.classList.toggle("done");
        });
    }

    handleOpenEdit(): void {
        this.querySelector("#todo-action-edit")!.addEventListener("click", () => {
            const modal = (document.querySelector("#modal") as ModalElement);
            modal.fillWith(new TodoFormElement(this.#todo));
            modal.show();
        });
    }

    handleOpenShow(): void {
        this.querySelector(`#${this.#idStr} .todo-resume`)!.addEventListener("click", () => {
            const modal = (document.querySelector("#modal") as ModalElement);
            modal.fillWith(new TodoShowElement(this.#todo));
            modal.show();
        });
    }

    handleDelete(): void {
        this.querySelector("#todo-action-delete")!.addEventListener("click", () => {
            todoStore.deleteTodo(this.#todo.id);
            this.remove();
        });
    }

    //
    // RENDERER
    //

    render(): void {

        let scheduledDate: string | null = null
        let remaining_time: string | null = null
        if (this.#todo.scheduledDate != "") {
            scheduledDate = dayjs(this.#todo.scheduledDate).format("DD/MM/YYYY HH:mm");
            remaining_time = dayjs(this.#todo.scheduledDate).fromNow();
        }

        this.innerHTML = /*html*/`
            <style>
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
                        justify-content: space-between;
                    }

                    .todo-resume {
                        &.high { background-color: red; }
                        &.medium { background-color: yellow; }
                    }
                }
            </style>

            <div id="${this.#idStr}" class="todo-item">
                ${scheduledDate != null ?
                    `<div class="todo-date">
                        <span>${scheduledDate}</span>
                        <span>${remaining_time}</span>
                    </div>`
                    : 
                    ""
                }
                <div class="todo-resume ${this.#todo.priority}">${this.#todo.resume}</div>
                <div class="todo-item-actions">
                    <button id="todo-action-edit">Edit</button>
                    <button id="todo-action-delete">Delete</button>
                    <button id="todo-action-done">Done</button>
                </div>
            </div>
        `;

        this.handleDone();
        this.handleOpenEdit();
        this.handleOpenShow();
        this.handleDelete();
    }
}

customElements.define("todo-item", TodoElement);

export { TodoElement, Todo };
export type { TodoParams, Priority }