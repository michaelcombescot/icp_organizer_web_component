import { Todo, TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import "./component_todo";
import { storeTodo,TodoWithList } from "../stores/store_todos";  
import { storeList } from "../stores/store_todo_lists";
import { getTodoPage } from "./component_todo_page";
import { ComponentTodo } from "./component_todo";

const listTypes = ["scheduled", "priority"]

class ComponentTodoLists extends HTMLElement {
    #listType!: string
    #currentListUUID : string | null = null
    #todosPriority: Todo[] = []
    #todosScheduled: Todo[] = []

    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    async connectedCallback() {
        this.#currentListUUID   = this.getAttribute("currentListUUID")
        this.update()
    }

    async update() {
        const todos = await storeTodo.apiGetTodos()
        const lists = await storeList.apiGetTodoLists()

        this.#todosPriority = storeTodo.helperSortTodosByPriority(todos, this.#currentListUUID)
        this.#todosScheduled = storeTodo.helperSortTodosByScheduledDate(todos, this.#currentListUUID)

        this.#render()
    }

    //
    // RENDER
    //

    async #render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <div id="todo-lists">
                <div id="todo-list-priority">
                    <!-- component-todo -->
                </div>
                <div id="todo-list-scheduled">
                    <!-- component-todo -->
                </div>
            </div>

            <style>
                #todo-lists {
                    width: 100%;
                    display: flex;
                    justify-content: space-around;
                    gap: 5em;

                    #todo-list-priority, #todo-list-scheduled {
                        width: 100%;
                        min-width: 15em;
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        justify-content: flex-start;
                        gap: 1em;
                    }
                }
            </style>
        `;

        this.shadowRoot!.querySelector("#todo-list-priority")!.append(
            ...this.#todosPriority.map((todo) => {
                const componentTodo = new ComponentTodo(todo as TodoWithList)
                componentTodo.setAttribute("listUUID", todo.todoListUUID[0]!)
                return componentTodo
            })
        )
        this.shadowRoot!.querySelector("#todo-list-scheduled")!.append(
            ...this.#todosScheduled.map((todo) => {
                const componentTodo = new ComponentTodo(todo as TodoWithList)
                componentTodo.setAttribute("listUUID", todo.todoListUUID[0]!)
                return componentTodo
            })
        )
    }
}

customElements.define("component-todo-lists", ComponentTodoLists);

export { ComponentTodoLists }

export const getComponentTodoLists = () => getTodoPage().shadowRoot!.querySelector("component-todo-lists")! as ComponentTodoLists