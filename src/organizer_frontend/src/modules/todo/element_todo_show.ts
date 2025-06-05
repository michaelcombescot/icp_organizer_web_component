import { Todo } from "./element_todo";

export class TodoShowElement extends HTMLElement {
    #todo: Todo

    constructor(todo: Todo) {
        super();
        this.attachShadow({ mode: "open" });
        this.#todo = todo;
    }

    connectedCallback() {
        this.render();
    }

    render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <style>
                #todo-show {
                    display: flex;
                    flex-direction: column;
                    gap: 1em;
                }
            </style>

            <div id="todo-show">
                <div>${this.#todo.resume}</div>
                <div>${this.#todo.description}</div>
                <div>${this.#todo.scheduledDate}</div>
                <div>${this.#todo.priority}</div>
                <div>${this.#todo.status}</div>
            </div>
        `
    }
}

customElements.define("todo-show", TodoShowElement);