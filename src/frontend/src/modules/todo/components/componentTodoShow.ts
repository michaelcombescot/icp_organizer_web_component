import { Todo } from "../../../../../declarations/backend_todos/backend_todos.did";
import { i18n } from "../../../i18n/i18n";
import { stringDateFromEpoch } from "../../../utils/date";
import { APITodo } from "../apis/apiTodos";
import { StoreTodos } from "../stores/storeTodo";

export class ComponentTodoShow extends HTMLElement {
    #todoId: bigint

    constructor(todoId: bigint) {
        super();
        this.attachShadow({ mode: "open" })

        this.#todoId = todoId
    }

    connectedCallback() {
        this.#render()
    }

    #render() {
        let todo = StoreTodos.todos.get(this.#todoId)!

        this.shadowRoot!.innerHTML = /*html*/`
            <div id="todo-show">
                <div>${i18n.todoFormFieldResume}</div>
                <div>${todo.resume}</div>

                <div>${i18n.todoFormFieldDescription}</div>
                <div>${todo.description[0]?.replace(/\n/g, "<br>") || ""}</div>

                ${
                    todo.scheduledDate.length != 0 ? 
                        /*html*/`
                            <div>${i18n.todoFormFieldScheduledDate}</div>
                            <div>${stringDateFromEpoch(todo.scheduledDate[0])}</div>
                        ` :
                        ""
                }                

                <div>${i18n.todoFormFieldPriority}</div>
                <div>${i18n.todoFormPriorities[Object.keys(todo.priority)[0]]}</div>

                <div>${i18n.todoFormFieldStatus}</div>
                <div>${i18n.todoFormStatuses[Object.keys(todo.status)[0]]}</div>
            </div>

            <style>
                #todo-show {
                    display: grid;
                    grid-template-columns: 0.3fr 1fr;
                    gap: 1em;
                }
            </style>
        `
    }
}

customElements.define('todo-show', ComponentTodoShow);