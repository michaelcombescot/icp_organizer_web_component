import { todoStore } from "./todo_store";
import { TodoFormElement } from "./todo_form";

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
    }

    connectedCallback(): void {
        this.render();
    }

    //
    // TRIGGERS
    //

    handleDone(): void {
        this.querySelector("#todo-action-done")!.addEventListener("click", () => {
            debugger
            this.querySelector(`#todo-item-${this.#todo.id}`)!.classList.toggle("done");
        });
    }

    handleOpenEdit(): void {
        this.querySelector("#todo-action-edit")!.addEventListener("click", () => {
            const modal = (document.querySelector("#modal") as ModalElement);
            modal.fillWith(new TodoFormElement(this.#todo));
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
        this.innerHTML = `
            <style>
                .todo-item {
                    display: flex;
                    flex-direction: column;

                    #toggle { margin-right: 0.6em; }
                    &.done { background-color: green; }
                    .todo-item-actions {
                        display: flex;
                        justify-content: space-between;
                    }
                }
            </style>

            <div id="todo-item-${this.#todo.id}" class="todo-item">
                <div class="todo-date">${this.#todo.scheduledDate}</div>">
                <div class="todo-resume ${this.#todo.status}">${this.#todo.resume}</div>
                <div class="todo-item-actions">
                    <button id="todo-action-edit">Edit</button>
                    <button id="todo-action-delete">Delete</button>
                    <button id="todo-action-done">Done</button>
                </div>
            </div>
        `;

        this.handleDone();
        this.handleOpenEdit();
        this.handleDelete();
    }
}

customElements.define("todo-item", TodoElement);

export { TodoElement, Todo };
export type { TodoParams, Priority }