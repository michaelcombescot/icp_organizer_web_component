import "./component_todo_list";
import { ComponentTodoForm } from "./component_todo_form";
import { openModalWithElement } from "../../../components/modal";
import { i18n } from "../../../i18n/i18n";
import { todoStore } from "../models/store";

customElements.define("component-todo-page",
    class ComponentTodoPage extends HTMLElement {
        constructor() {
            super()
        }

        connectedCallback() {
            this.#render()
            todoStore.loadStore()
        }

        #bindEvents() {
            this.querySelector("#todo-open-modal-new-task")!.addEventListener("click", () => this.openNewTaskModal())
        }

        private openNewTaskModal() {
            openModalWithElement(new ComponentTodoForm(null));
        }

        #render() {
            this.innerHTML = /*html*/`
                <div id="todo-page">
                    <button id="todo-open-modal-new-task">${ i18n.todoCreateNewButton }</button>

                    <div id="todo-lists">
                        <component-todo-list id="todo-list-priority" listType="priority"></component-todo-list>
                        <component-todo-list id="todo-list-scheduled" listType="scheduled"></component-todo-list>
                    </div>
                </div>

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
            `;

            this.#bindEvents()
        }
    }
)