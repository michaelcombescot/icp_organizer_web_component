import { Todo, TodoList } from "../../../../../declarations/backend_todos/backend_todos.did";
import "./componentTodo";
import { getTodoPage } from "./componentTodoPage";
import { ComponentTodo } from "./componentTodo";
import { StoreTodos } from "../stores/storeTodo";
import { isAuthenticated } from "../../../components/auth/auth";
import { StoreGlobal } from "../stores/storeGlobal";

const listTypes = ["scheduled", "priority"]

class ComponentTodoLists extends HTMLElement {
    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    async connectedCallback() {
        this.render()
    }

    //
    // RENDER
    //

    async render() {
        let todosPriority = StoreTodos.getPriorityTodosOrderedIds()
        let todosScheduled = StoreTodos.getScheduledTodosOrderedIds()

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

        this.shadowRoot!.querySelector("#todo-list-priority")!.append( ...todosPriority.map((todoId) => {
            let todoComp = new ComponentTodo(todoId)
            todoComp.setAttribute("component_todo_id", todoId.toString())
            return todoComp
        }))
        this.shadowRoot!.querySelector("#todo-list-scheduled")!.append( ...todosScheduled.map((todoId) => {
            let todoComp = new ComponentTodo(todoId)
            todoComp.setAttribute("component_todo_id", todoId.toString())
            return todoComp
        }))
    }
}

customElements.define("component-todo-lists", ComponentTodoLists);

export { ComponentTodoLists }

export const getComponentTodoLists = () => getTodoPage().shadowRoot!.querySelector("component-todo-lists")! as ComponentTodoLists