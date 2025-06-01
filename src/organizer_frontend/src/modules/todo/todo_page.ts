import "./todo_list";
import "./todo_form";
import "../../components/modal";

class TodoPageElement extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: "open" });
    }

    connectedCallback() {
        this.render();
    }

    render() {
        this.shadowRoot!.innerHTML = `
            <style>
                #todo-lists {
                    display: flex;
                    gap: 1em;
                }
            </style>

            <button popovertarget="modal-new-task">New task</button>
            <component-modal popover-id="modal-new-task">
                <todo-form></todo-form>
            </component-modal>

            <div id="todo-lists">
                <todo-list id="todo-list-priority" type="priority"></todo-list>
                <todo-list id="todo-list-scheduled" type="scheduled"></todo-list>
            </div>
        `;
    }
}

customElements.define("todo-page", TodoPageElement);