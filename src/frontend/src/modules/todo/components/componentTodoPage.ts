import "./componentTodoLists";
import "../../../components/dropdown"
import { ComponentTodoForm } from "./componentTodoForm";
import { openModalWithElement } from "../../../components/modal";
import { i18n } from "../../../i18n/i18n";
import { ComponentListForm } from "./componentListForm";
import { borderRadius } from "../../../css/css";
import { getPage } from "../../../App";
import { isAuthenticated } from "../../../auth/auth";
import { StoreGlobal } from "../stores/storeGlobal";
import { ComponentDropdown } from "../../../components/dropdown";
import { StoreUser } from "../stores/storeUser";

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
            await StoreUser.fetchUserData();
        }

        let currentListId = StoreGlobal.currentSelectedListId

        this.shadowRoot!.innerHTML = /*html*/`
            <div id="todo-page">
                ${
                    !isAuthenticated
                    ? ''
                    : /*html*/`
                        <div id="selectors">
                            <div class="select">
                                <component-dropdown id="select-group" label="${i18n.groupSelectorLabel}"></component-dropdown>
                                <img id="todo-open-modal-new-list" class="select-plus" src="/plus.svg" />
                            </div>

                            <div class="select">
                                <component-dropdown id="select-list" label="${i18n.listSelectorLabel}"></component-dropdown>
                                <img id="todo-open-modal-new-list" class="select-plus" src="/plus.svg" />
                            </div>

                            <button id="todo-open-modal-new-task"><img src="/plus.svg"><span>${ i18n.todoCreateNewButton }</span></button>
                        </div>
                    `
                }

                ${ 
                    !isAuthenticated
                    ?   /*html*/`
                            <p>Not CONNECTED</p>
                        `
                    :   /*html*/`
                            <div id="todo-lists">
                                <component-todo-lists currentListUUID="${ currentListId }"></component-todo-lists>
                            </div>
                        `
                }
            </div>

            <style>
                #todo-page {
                    width: 100%; height: 100%;
                    display: flex; flex-direction: column; gap: 1.5em;

                    #selectors {
                        display: flex; flex-direction: row; align-items: center; justify-content: center;
                        gap: 1.5em;

                        .select {
                            display: flex;

                            .select-plus {
                                width: 1.8em;
                            }
                        }

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
export const getDropdownGroups = () => getTodoPage().querySelector("#select-group")! as ComponentDropdown
export const getDropdownLists = () => getTodoPage().querySelector("#select-list")! as ComponentDropdown