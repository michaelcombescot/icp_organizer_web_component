import { Todo, TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { ComponentTodo } from "./component_todo";
import { storeTodo } from "../stores/store_todos";  
import { storeList } from "../stores/store_todo_lists";
import { getTodoPage } from "./component_todo_page";

const listTypes = ["scheduled", "priority"]

class ComponentTodoList extends HTMLElement {
    #listType!: string
    #currentListUUID : string | null = null

    #todos: Todo[] = []
    set todos(todos: Todo[]) {
        this.#todos = todos;
        this.#render()
    }
    get todos() { return this.#todos }

    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    async connectedCallback() {
        this.#currentListUUID   = this.getAttribute("currentListUUID")
        this.#listType          = this.getAttribute("listType") || (() => {throw new Error(`listType attribute is required`)})()
        this.#todos             = await this.#loadList()

        this.#render()
    }

    async #loadList(): Promise<Todo[]> {
        return  this.#listType == "scheduled" ? 
                    await storeTodo.helperGetTodosByScheduledDate(this.#currentListUUID)
                    : await storeTodo.helperGetTodosByPriority(this.#currentListUUID)
    }



    //
    // RENDER
    //

    async #render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <div class="todo-list">
                <div class="todo-list-items">
                    ${
                        this.#todos.map(item => `<component-todo uuid="${item.uuid}" listUUID="${item.todoListUUID}" todo="${JSON.stringify(item)}"></component-todo>`).join("")
                    }
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
    }
}

customElements.define("component-todo-list", ComponentTodoList);

export { ComponentTodoList }

export const getComponentTodoListScheduled = () => getTodoPage().shadowRoot!.querySelector("#todo-list-scheduled")! as ComponentTodoList
export const getComponentTodoListPriority = () => getTodoPage().shadowRoot!.querySelector("todo-list-priority")! as ComponentTodoList