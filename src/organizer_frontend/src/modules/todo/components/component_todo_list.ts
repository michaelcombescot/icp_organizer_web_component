import { Todo, TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { ComponentTodo } from "./component_todo";
import { storeTodo } from "../stores/store_todos";  
import { storeList } from "../stores/store_todo_lists";

const listTypes = ["scheduled", "priority"]

class ComponentTodoList extends HTMLElement {
    #type: string

    #currentListUUID = this.getAttribute("listUUID")

    #todos: Todo[]
    set todos(todos: Todo[]) {
        this.#todos = todos;
        this.#render()
    }

    constructor() {
        super()
    }

    async connectedCallback() {
        this.#type = this.getAttribute("listType")!
        if (!listTypes.includes(this.#type) ) { throw new Error(`listType attribute is required, is ${this.#type}`) }

        this.#currentListUUID = this.getAttribute("listUUID")

        this.#todos = this.#type == "scheduled" ? await storeTodo.getOrderedByScheduledDateTodos(this.#currentListUUID) : await storeTodo.getOrderedByPriorityTodos(this.#currentListUUID)

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

        this.#todos.forEach(item => {
            const newTodo = new ComponentTodo(item, this.#list)
            newTodo.setAttribute("data-uuid", item.uuid)
            newTodo.setAttribute("data-list-uuid", item.todoListUUID)
            this.querySelector(".todo-list-items")!.appendChild(newTodo)
        })
    }
}

customElements.define("component-todo-list", ComponentTodoList);

export { ComponentTodoList }

export const getComponentTodoListScheduled = () => document.querySelector("todo-list-scheduled")! as ComponentTodoList
export const getComponentTodoListPriority = () => document.querySelector("todo-list-priority")! as ComponentTodoList