import { todoStore } from "./todo_store";

interface TodoParams {
    id: string;
    resume: string;
    description: string;
    scheduledDate: string;
    priority: Priority;
    status: Status;
}

type Priority = "High" | "Medium" | "Low";
type Status = "Done" | "Pending";

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

    save(): void {
        todoStore.addTodo(this);
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
        this.querySelector("#toggle")!.addEventListener("change", () => {
            this.querySelector(".todo-item")!.classList.toggle("done");
        });
    }

    handleOpenEditMode(): void {
        this.querySelector("#edit")!.addEventListener("click", () => {
            this.renderEdit();
        });
    }

    handleCancelEdit(): void {
        this.querySelector("#edit-cancel")!.addEventListener("click", () => {
            this.render();
        });
    }

    handleSaveEdit(): void {
        this.querySelector("#edit-form")!.addEventListener("submit", () => {
            const inputElement = this.querySelector("#edit-input") as HTMLInputElement;
            this.#todo.resume = inputElement.value;
            todoStore.updateTodo(this.#todo);
            this.render();
        });
    }

    handleDelete(): void {
        this.querySelector("#delete")!.addEventListener("click", () => {
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

                    #toggle { margin-right: 0.6em; }
                    &.done { background-color: green; }
                }
            </style>

            <div class="todo-item">
                <input type="checkbox" id="toggle" />
                <span>${this.#todo.resume}</span>
                <button id="edit">Edit</button>
                <button id="delete">Delete</button>
            </div>
        `;

        this.handleDone();
        this.handleOpenEditMode();
        this.handleDelete();
    }

    renderEdit(): void {
        this.innerHTML = `
            <style>
                .todo-item { 
                    display: flex;
                }
            </style>

            <div class="todo-item">
                <form id="edit-form">
                    <input id="edit-input" type="text" required />
                    <input type="submit" value="save" />
                    <button id="edit-cancel">cancel</button>
                </form>
            </div>
        `;

        this.handleSaveEdit();
        this.handleCancelEdit();
    }
}

customElements.define("todo-item", TodoElement);

export { TodoElement, Todo };
export type { TodoParams, Priority }