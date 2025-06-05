import "./element_todo_list";
import "./element_todo_form";
import "../../components/modal";
import { i18n } from "../../i18n/i18n";

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
                    display: flex;
                    flex-direction: column;
                    gap: 2em;

                    #todo-open-modal-new-task {
                        width: max-content;
                    }                    

                    #todo-lists {
                        display: flex;
                        justify-content: space-around;
                        gap: 5em;

                        todo-list {
                            flex: 1;
                        }
                    }
                }
            </style>

            <div id="todo-page">
                <button id="todo-open-modal-new-task">${ i18n.todoCreateNewButton }</button>

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