import { todoStore } from "../models/todo_store";
import { Todo } from "../models/todo";
import { ComponentTodoForm } from "./component_todo_form";
import { ComponentTodoShow } from "./component_todo_show";
import { openModalWithElement } from "../../../components/modal";
import { remainingTimeFromEpoch, stringDateFromEpoch } from "../../../utils/date";
import { borderRadius, scaleOnHover } from "../models/css";

class ComponentTodo extends HTMLElement {
    #todo: Todo
    set todo(todo: Todo) {
        this.#todo = todo
        this.#render()
    }

    #color: string
    set color(color: string) {
        this.#todo.list!.color = color
        this.#render()
    }

    constructor(todo: Todo) {
        super()
        this.attachShadow({ mode: "open" });

        this.#todo = todo
        this.#color = this.#todo.list!.color
    }

    connectedCallback() {
        this.#render();
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
                <div id="todo-item-resume" class="${Object.keys(this.#todo.priority)[0]}">${this.#todo!.resume}</div>
                <div id="todo-item-actions">
                    <img id="todo-item-action-edit" src="/edit.svg">
                    <img id="todo-item-action-done" src="/done.svg">
                    <img id="todo-item-action-delete" src="/trash.svg">
                </div>
            </div>

            <style>
                #todo-item {
                    display: flex;
                    flex-direction: column;
                    gap: 1em;
                    background-color: ${this.#todo.list?.color || "#fefee2"};
                    padding: 1em;
                    min-width: 15em;
                    border-radius: ${borderRadius};
    
                    
                    #todo-item-actions {
                        display: flex;
                        justify-content: space-between;

                        img {
                            width: 1em;
                            filter: brightness(0) invert(1);
                            cursor: pointer;

                            &:hover {
                                transform: scale(${scaleOnHover});
                            }
                        }
                    }

                    #todo-item-date {
                        display: flex;
                        gap: 1em;
                        justify-content: space-between;
                    }

                    #todo-item-resume {
                        background-color: white;
                        padding: 0.5em;
                        border-radius: ${borderRadius};
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