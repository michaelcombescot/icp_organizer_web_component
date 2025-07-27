import { i18n } from "../../../i18n/i18n";
import { openModalWithElement } from "../../../components/modal";
import { ComponentListForm } from "./component_list_form";
import { listStore } from "../models/list_store";

class ComponentTodoListsPage extends HTMLElement {
    constructor() {
        super();
    }

    connectedCallback() {
        this.#render();
    }

    #bindEvents() {
        this.querySelector("#todo-list-open-modal-new-list")!.addEventListener("click", () => this.#openNewListModal())
        this.querySelector("#todo-list-select-list")!.addEventListener("change", (e) => listStore.getList((e.target! as HTMLSelectElement).value))
    }

    #openNewListModal() {
        openModalWithElement(new ComponentListForm());
    }

    #render() {
        this.innerHTML = /*html*/`
            <div id="todo-lists-page">
                <button id="todo-list-open-modal-new-list">${ i18n.todoListCreateButton }</button>

                <select id="todo-list-select-list">
                    <option value="" disabled selected>Select your option</option>
                </select>
                
                <div id="todo-lists-list">
                    
                </div>
            </div>
        `;

        this.#bindEvents()
    }
}

customElements.define("component-todo-lists-page", ComponentTodoListsPage);