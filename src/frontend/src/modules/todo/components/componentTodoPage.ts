import "./componentTodoLists";
import { ComponentTodoForm } from "./componentTodoForm";
import { openModalWithElement } from "../../../components/modal";
import { i18n } from "../../../i18n/i18n";
import { ComponentListForm } from "./componentListForm";
import { borderRadius } from "../../../css/css";
import { getPage } from "../../../App";
import { isAuthenticated } from "../../../components/auth/auth";
import { getLoadingComponent } from "../../../components/loading";
import { StoreGlobal } from "../stores/storeGlobal";

class ComponentTodoPage extends HTMLElement {
    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    async connectedCallback() {
        this.render()
    }

    async render() {
        if ( isAuthenticated ) {
            await StoreGlobal.getUserData();
        }

        let currentListId = StoreGlobal.currentSelectedListId

        this.shadowRoot!.innerHTML = /*html*/`
            <div id="todo-page">
                ${ 
                    !isAuthenticated
                    ?   /*html*/`
                            <p>Not CONNECTED</p>
                        `
                    :   /*html*/`
                            <div id="todo-page-buttons">
                                <button id="todo-open-modal-new-task"><img src="/plus.svg"><span>${ i18n.todoCreateNewButton }</span></button>
                                <button id="todo-open-modal-new-list"><img src="/plus.svg"><span>${ i18n.todoListCreateButton }</span></button>
                            </div>

                            <component-lists-cards currentListUUID="${ currentListId }" id="component-lists-card"></component-lists-cards>

                            <div id="todo-lists">
                                <component-todo-lists currentListUUID="${ currentListId }"></component-todo-lists>
                            </div>
                        `
                }
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
                }
            </style>
        `;

        if (isAuthenticated) {
            this.shadowRoot!.querySelector("#todo-open-modal-new-task")!.addEventListener("click", () => openModalWithElement(new ComponentTodoForm(null)))
            this.shadowRoot!.querySelector("#todo-open-modal-new-list")!.addEventListener("click", () => openModalWithElement(new ComponentListForm(null)))
        }
       
    }
}

customElements.define("component-todo-page", ComponentTodoPage)

export const getTodoPage = () => getPage().querySelector("component-todo-page")! as ComponentTodoPage