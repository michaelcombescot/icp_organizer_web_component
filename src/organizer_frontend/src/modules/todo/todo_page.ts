import "./todo_list";
import "./todo_form";
import "../../components/modal";

class TodoPageElement extends HTMLElement {
    constructor() {
        super();
    }

    connectedCallback() {
        this.render();
    }

    render() {
        this.innerHTML = `
            <style>
                #todo-lists {
                    display: flex;
                    gap: 1em;
                }
            </style>

            <button id="js-open-modal-new-task">New task</button>

            <div id="todo-lists">
                <todo-list id="todo-list-priority" type="priority"></todo-list>
                <todo-list id="todo-list-scheduled" type="scheduled"></todo-list>
            </div>
        `;

        this.querySelector("#js-open-modal-new-task")!.addEventListener("click", (e) => {
            e.preventDefault();

            const modal = (document.querySelector("#modal") as ModalElement);
            modal.fillWith(document.createElement("todo-form"))
            modal.show();
        });
    }
}

customElements.define("todo-page", TodoPageElement);