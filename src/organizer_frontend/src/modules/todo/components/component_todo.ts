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
        this.attachShadow({ mode: "open" });

        this.#todo = todo
        this.id = `todo-${todo.uuid}`
    }

    connectedCallback() {
        this.#render();
    }

    update(color: string) {
        this.#todo.list!.color = color
        this.#render()
    }

    #render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <div id="todo-item">
                ${this.#todo.scheduledDate != BigInt(0) ?
                    /*html*/`
                        <div id="todo-item-date">
                            <span>${stringDateFromEpoch(this.#todo.scheduledDate)}</span>
                            <span>${remainingTimeFromEpoch(this.#todo.scheduledDate)}</span>
                        </div>
                    ` : ""
                }
                <div id="todo-item-resume" class="${this.#todo.priority}">${this.#todo!.resume}</div>
                <div id="todo-item-actions">
                    <button id="todo-item-action-edit">Edit</button>
                    <button id="todo-item-action-delete">Delete</button>
                    <button id="todo-item-action-done">Done</button>
                </div>
            </div>

            <style>
                #todo-item {
                    box-sizing: border-box;
                    display: flex;
                    flex-direction: column;
                    gap: 1em;
                    background-color: white;
                    padding: 1em;
                    border: 3px solid ${this.#todo.list?.color || "black"};
                    
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

        this.shadowRoot!.querySelector("#todo-item-resume")!.addEventListener("click", () => openModalWithElement(new ComponentTodoShow(this.#todo)) );

        this.shadowRoot!.querySelector("#todo-item-action-done")!.addEventListener("click", () => this.querySelector(`#${this.#todo.uuid}`)!.classList.toggle("done") );

        this.shadowRoot!.querySelector("#todo-item-action-edit")!.addEventListener("click", () => openModalWithElement(new ComponentTodoForm(this.#todo, this.#todo.listUUID))  );

        this.shadowRoot!.querySelector("#todo-item-action-delete")!.addEventListener("click", () => {
            todoStore.deleteTodo(this.#todo.uuid)
            this.remove();
        });
    }
}

customElements.define("component-todo", ComponentTodo);

export { ComponentTodo };