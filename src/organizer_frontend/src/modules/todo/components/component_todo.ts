import { todoStore } from "../models/todo_store";
import { Todo } from "../models/todo";
import { ComponentTodoForm } from "./component_todo_form";
import { ComponentTodoShow } from "./component_todo_show";
import { openModalWithElement } from "../../../components/modal";
import { remainingTimeFromEpoch, stringDateFromEpoch } from "../../../utils/date";

class ComponentTodo extends HTMLElement {
    #todo: Todo
    set todo(todo: Todo) {
        this.#todo = todo
        this.#render()
    }

    constructor(todo: Todo) {
        super()
        this.#todo = todo
        this.id = `todo-${todo.uuid}`
    }

    connectedCallback() {
        this.#render();
    }

    #handleDone(): void { this.querySelector(`#${this.#todo.uuid}`)!.classList.toggle("done") }

    #handleOpenEdit(): void { openModalWithElement(new ComponentTodoForm(this.#todo, this.#todo.listUUID)) }

    #handleOpenShow(): void { openModalWithElement(new ComponentTodoShow(this.#todo)) }

    #handleDelete(): void {
        todoStore.deleteTodo(this.#todo.uuid)
        this.remove();
    }

    #render() {
        this.innerHTML = /*html*/`
            <div class="todo-item">
                ${this.#todo.scheduledDate != BigInt(0) ?
                    /*html*/`
                        <div id="todo-date">
                            <span>${stringDateFromEpoch(this.#todo.scheduledDate)}</span>
                            <span>${remainingTimeFromEpoch(this.#todo.scheduledDate)}</span>
                        </div>
                    ` : ""
                }
                <div id="todo-resume" class="${this.#todo.priority}">${this.#todo!.resume}</div>
                <div id="todo-item-actions">
                    <button id="todo-action-edit">Edit</button>
                    <button id="todo-action-delete">Delete</button>
                    <button id="todo-action-done">Done</button>
                </div>
            </div>

            <style>
                .todo-item {
                    box-sizing: border-box;
                    display: flex;
                    flex-direction: column;
                    gap: 1em;
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
            </style>
        `

        this.querySelector("#todo-resume")!.addEventListener("click", () => this.#handleOpenShow());
        this.querySelector("#todo-action-done")!.addEventListener("click", () => this.#handleDone());
        this.querySelector("#todo-action-edit")!.addEventListener("click", () => this.#handleOpenEdit());
        this.querySelector("#todo-action-delete")!.addEventListener("click", () => this.#handleDelete());
    }
}

customElements.define("component-todo", ComponentTodo);

export { ComponentTodo };