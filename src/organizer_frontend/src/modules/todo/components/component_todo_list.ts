import { todoStore } from "../models/store";
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
                    // align-items: center;
                    flex-direction: column;
                    gap: 1em;
                    padding: 1em;
                    border-radius: 10px;
                    background-color: rgb(3, 252, 194, 0.1); 
                }

                .todo-list-items {
                    display: flex;
                    flex-direction: column;
                    gap: 1em;
                }
            </style>
        `;

        this.#list.forEach(item => {
            this.querySelector(".todo-list-items")!.appendChild(new ComponentTodo(item))
        })
    }
}

customElements.define("component-todo-list", ComponentTodoList);

export { ComponentTodoList }