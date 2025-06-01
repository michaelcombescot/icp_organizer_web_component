// display a list of TodoElement, attribute type must be "priority" or "scheduled"

import { DB } from "../../db/db";
import { TodoElement } from "./todo";
import { todoStore } from "./todo_store";

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
                this.#list = todos.filter(todo => !todo.scheduledDate).map(todo => new TodoElement(todo));
                break;
            case "scheduled":
                this.#list = todos.filter(todo => todo.scheduledDate).map(todo => new TodoElement(todo));
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
                    align-items: center;
                    flex-direction: column;
                    gap: 1em;
                    padding: 1em;
                }

                .todo-list-items {
                    display: flex;
                    flex-wrap: wrap;
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
