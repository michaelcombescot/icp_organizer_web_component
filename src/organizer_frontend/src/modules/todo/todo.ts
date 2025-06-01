import { todoStore } from "./todo_store";

interface TodoParams {
    id: string;
    resume: string;
    description: string;
    scheduledDate: string;
    priority: string;
}

class Todo {
    id: string;
    resume: string;
    description: string;
    scheduledDate: string;
    priority: string;

    constructor(todoParams: TodoParams) {
        this.id = todoParams.id;
        this.resume = todoParams.resume;
        this.description = todoParams.description;
        this.scheduledDate = todoParams.scheduledDate;
        this.priority = todoParams.priority;
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
        this.attachShadow({ mode: "open" });

        this.#todo = todo;

        console.log(" constructor todo", todo);
    }

    connectedCallback(): void {
        this.render();
    }

    //
    // TRIGGERS
    //

    handleDone(): void {
        this.shadowRoot!.querySelector("#toggle")!.addEventListener("change", () => {
            this.shadowRoot!.querySelector(".todo-item")!.classList.toggle("done");
        });
    }

    handleOpenEditMode(): void {
        this.shadowRoot!.querySelector("#edit")!.addEventListener("click", () => {
            this.renderEdit();
        });
    }

    handleSaveEdit(): void {
        this.shadowRoot!.querySelector("#edit-save")!.addEventListener("click", () => {
            const inputElement = this.shadowRoot!.querySelector("#edit-input") as HTMLInputElement;
            this.#todo.resume = inputElement.value;
            this.render();
        });
    }

    //
    // RENDERER
    //
    render(): void {
        this.shadowRoot!.innerHTML = `
            <style>
                .todo-item {
                    display: flex;

                    #toggle { margin-right: 0.6em; }
                    &.done { background-color: green; }
                }
            </style>

            <div class="todo-item">
                <input type="checkbox" id="toggle" />
                <h2>${this.#todo.resume}</h2>
                <button id="edit">edit</button>
            </div>
        `;

        this.handleDone();
        this.handleOpenEditMode();
    }

    renderEdit(): void {
        this.shadowRoot!.innerHTML = `
            <style>
                .todo-item { 
                    display: flex;
                }
            </style>

            <div class="todo-item">
                <form>
                    <input id="edit-input" type="text" />
                    <button id="edit-save">save</button>
                </form>
            </div>
        `;

        this.handleSaveEdit();
    }
}

customElements.define("todo-item", TodoElement);

export { TodoElement, Todo };
export type { TodoParams }