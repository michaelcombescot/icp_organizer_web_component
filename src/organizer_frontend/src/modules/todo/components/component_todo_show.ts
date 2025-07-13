import { ComponentTodo } from "./component_todo";
import { Todo } from "../models/todo";

export class ComponentTodoShow extends HTMLElement {
    #todo: Todo

    constructor(todo: Todo) {
        super();
        this.#todo = todo
    }

    connectedCallback() {
        this.#render()
    }

    #render() {
        this.innerHTML = /*html*/`
            <div id="todo-show">
                <div>${this.#todo!.resume}</div>
                <div>${this.#todo!.description}</div>
                <div>${this.#todo!.scheduledDate}</div>
                <div>${this.#todo!.priority}</div>
                <div>${this.#todo!.status}</div>
            </div>

            <style>
                #todo-show {
                    display: flex;
                    flex-direction: column;
                    gap: 1em;
                }
            </style>
        `
    }
}

customElements.define('todo-show', ComponentTodoShow);