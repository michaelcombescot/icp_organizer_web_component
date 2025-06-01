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
        this.attachShadow({ mode: "open" });
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

        this.#list = todos.map(todo => new TodoElement(todo));

        console.log("initList", this.#list);
    }

    addItem(item: TodoElement): void {
        this.#list.push(item);
        this.shadowRoot!.querySelector("#todo-list-items")!.appendChild(item);
    }

    //
    // RENDERER
    //
    render(): void {
        this.shadowRoot!.innerHTML = `
            <style>
                #todo-list { 
                    display: flex;
                    align-items: center;
                    flex-direction: column;
                    padding: 1em;
                }

                #todo-list-items {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 1em;
                }
            </style>

            <div id="todo-list">
                <div id="todo-list-items">
                </div>
            </div>
        `;

        // populate with todo list
        this.#list.forEach((item) => {
            this.shadowRoot!.querySelector("#todo-list-items")!.appendChild(item)
        });
    }
}

customElements.define("todo-list", TodoListElement);
