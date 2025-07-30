import { todoStore } from "../models/todo_store";
import { Todo } from "../models/todo";
import { TodoListType } from "../models/todo";
import { ComponentTodo } from "./component_todo";

class ComponentTodoList extends HTMLElement {
    #list: Todo[]
    set list(list: Todo[]) {
        this.#list = list;
        this.#render()
    }
    get list() {
        return this.#list
    }

    constructor() {
        super();
        this.#list = []
    }

    async connectedCallback() {
        this.#render()
    }

    //
    // RENDER
    //

    async #render() {
        this.innerHTML = /*html*/`
            <div class="todo-list">
                <div class="todo-list-items">
                </div>
            </div>

            <style>
                .todo-list { 
                    display: flex;
                    flex-direction: column;
                    gap: 1em;
                }

                .todo-list-items {
                    display: flex;
                    flex-direction: column;
                    gap: 1em;
                }
            </style>
        `;

        this.#list.forEach(item => {
            const newTodo = new ComponentTodo(item)
            newTodo.setAttribute("data-uuid", item.uuid)
            newTodo.setAttribute("data-list-uuid", item.listUUID)
            this.querySelector(".todo-list-items")!.appendChild(newTodo)
        })
    }
}

customElements.define("component-todo-list", ComponentTodoList);

export { ComponentTodoList }