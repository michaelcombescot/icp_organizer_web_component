import { Todo } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { i18n } from "../../../i18n/i18n";
import { stringDateFromEpoch } from "../../../utils/date";

export class ComponentTodoShow extends HTMLElement {
    #todo: Todo

    constructor(todo: Todo) {
        super();
        this.attachShadow({ mode: "open" })

        this.#todo = todo
    }

    connectedCallback() {
        this.#render()
    }

    #render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <div id="todo-show">
                <div>${i18n.todoFormFieldResume}</div>
                <div>${this.#todo.resume}</div>

                <div>${i18n.todoFormFieldDescription}</div>
                <div>${this.#todo.description[0]?.replace(/\n/g, "<br>") || ""}</div>

                ${
                    this.#todo.scheduledDate.length != 0 ? 
                        /*html*/`
                            <div>${i18n.todoFormFieldScheduledDate}</div>
                            <div>${stringDateFromEpoch(this.#todo.scheduledDate[0])}</div>
                        ` :
                        ""
                }                

                <div>${i18n.todoFormFieldPriority}</div>
                <div>${i18n.todoFormPriorities[Object.keys(this.#todo.priority)[0]]}</div>

                <div>${i18n.todoFormFieldStatus}</div>
                <div>${i18n.todoFormStatuses[Object.keys(this.#todo.status)[0]]}</div>
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