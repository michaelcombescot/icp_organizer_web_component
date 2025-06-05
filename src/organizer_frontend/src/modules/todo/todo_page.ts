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
                #todo-page {
                    #todo-open-new-task {
                        margin-bottom: 1em;
                    }                    

                    #todo-lists {
                        display: flex;
                        justify-content: space-around;
                        width: 100%;
                    }
                }
            </style>

            <div id="todo-page">
                <button id="todo-open-modal-new-task">New task</button>

                <div id="todo-lists">
                    <todo-list id="todo-list-priority" type="priority"></todo-list>
                    <todo-list id="todo-list-scheduled" type="scheduled"></todo-list>
                </div>
            </div>
        `;

        this.querySelector("#todo-open-modal-new-task")!.addEventListener("click", (e) => {
            e.preventDefault();

            const modal = (document.querySelector("#modal") as ModalElement);
            modal.fillWith(document.createElement("todo-form"))
            modal.show();
        });
    }
}

customElements.define("todo-page", TodoPageElement);