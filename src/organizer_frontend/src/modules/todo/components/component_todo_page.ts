import "./component_todo_list";
import { ComponentTodoForm } from "./component_todo_form";
import { openModalWithElement } from "../../../components/modal";
import { i18n } from "../../../i18n/i18n";
import { ComponentListForm } from "./component_list_form";
import { borderRadius } from "../../../css/css";

class ComponentTodoPage extends HTMLElement {
    #currentListUUID: string
    set currentListUUID(listUUID: string) {
        this.#currentListUUID = listUUID
        this.#render()
    }

    constructor() {
        super()
        this.#currentListUUID = ""
    }

    async connectedCallback() {
        this.#render()
    }

    #render() {
        this.innerHTML = /*html*/`
            <div id="todo-page">
                <div id="todo-page-buttons">
                    <button id="todo-open-modal-new-task"><img src="/plus.svg"><span>${ i18n.todoCreateNewButton }</span></button>
                    <button id="todo-open-modal-new-list"><img src="/plus.svg"><span>${ i18n.todoListCreateButton }</span></button>
                </div>

                <component-lists-cards selectedListUUID="${ this.#currentListUUID }" id="component-lists-card"></component-lists-cards>

                <div id="todo-lists">
                    <component-todo-list id="todo-list-priority" listType="priority" currentListUUID="${ this.#currentListUUID }"></component-todo-list>
                    <component-todo-list id="todo-list-scheduled" listType="scheduled" currentListUUID="${ this.#currentListUUID }"></component-todo-list>
                </div>
            </div>

            <style>
                #todo-page {
                    display: flex;
                    flex-direction: column;
                    gap: 1.5em;

                    #todo-page-buttons {
                        display: flex;
                        gap: 1.5em;

                        button {
                            font-size: 0.8em;
                            padding: 0.5em 1em;
                            text-align: center;
                            width: max-content;
                            border-radius: ${borderRadius};
                            background-color: lightblue;
                            cursor: pointer;

                            img {
                                vertical-align: middle;
                                width: 1.5em;
                                margin-right: 0.5em;
                            }

                            span {
                                vertical-align: middle;
                            }

                            &:hover {
                                background-color: darkblue;
                                color: white;

                                img {
                                    filter: invert(1);
                                }
                            }
                        }
                    }
                    
                    #todo-select-list {
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

        this.querySelector("#todo-open-modal-new-task")!.addEventListener("click", () => openModalWithElement(new ComponentTodoForm(null, this.#currentListUUID)))
        this.querySelector("#todo-open-modal-new-list")!.addEventListener("click", () => openModalWithElement(new ComponentListForm(null)))
    }
}

customElements.define("component-todo-page", ComponentTodoPage)

export const getTodoPage = () => document.querySelector("component-todo-page")! as ComponentTodoPage