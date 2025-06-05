// display a list of TodoElement, attribute type must be "priority" or "scheduled"

import { DB } from "../../db/db";
import { TodoElement, Todo } from "./element_todo";
import { todoStore } from "./store";

export class TodoListElement extends HTMLElement {
    //
    // PROPERTIES
    //

    #list: TodoElement[] = [];
    setList(list: TodoElement[]): void {
        this.#list = list;
        this.render();
    }

    //
    // INITIALIZATION
    //
    constructor() {
        super();
    }

    async connectedCallback(): Promise<void> {
        await this.initList();

        this.render();
    }

    //
    // BEHAVIORS
    //

    async initList() {
        const todos = await todoStore.getTodos();

        switch ( this.getAttribute("type") ) {
            case "priority":
                this.#list = todos
                                .filter(todo => !todo.scheduledDate)
                                .sort((a, b) => b.priority.valueOf() - a.priority.valueOf())
                                .map(todo => new TodoElement(todo));
                                
                break;
            case "scheduled":
                this.#list = todos
                                .filter(todo => todo.scheduledDate)
                                .sort((a, b) => new Date(a.scheduledDate).getTime() - new Date(b.scheduledDate).getTime())
                                .map(todo => new TodoElement(todo))
                break;
            default:
                console.log("Invalid todo list type");
                break;
        }
    }

    addItem(item: TodoElement): void {
        this.#list.push(item);
        this.querySelector(".todo-list-items")!.appendChild(item);
    }

    //
    // RENDERER
    //
    render(): void {
        this.innerHTML = `
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

            <div class="todo-list">
                <div class="todo-list-items">
                </div>
            </div>
        `;

        // populate with todo list
        this.#list.forEach((item) => {
            this.querySelector(".todo-list-items")!.appendChild(item)
        });
    }
}

customElements.define("todo-list", TodoListElement);
