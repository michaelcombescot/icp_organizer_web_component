import { List } from "../models/list";
import { openModalWithElement } from "../../../components/modal";
import { ComponentListForm } from "./component_list_form";
import { listStore } from "../models/list_store";
import { i18n } from "../../../i18n/i18n";
import { getTodoPage } from "./component_todo_page";
import { ComponentTodo } from "./component_todo";
import { cardFontSize } from "../models/css";

export class ComponentListCard extends HTMLElement {
    #list: List

    constructor(list: List) {
        super();
        this.attachShadow({ mode: "open" });

        this.#list = list
    }

    connectedCallback() {
        this.#render();
    }

    update(list: List) {
        this.#list = list
        this.#render()

        document.querySelectorAll(`[data-list-uuid="${this.#list.uuid}"]`).forEach((todo) => {
            (todo as ComponentTodo).update(this.#list.color)
        })
    }

    #render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <div class="todo-list-card" style="background-color: ${this.#list.color}">
                <span class="todo-list-card-name">${this.#list.name}</span>
                <div class="todo-list-card-actions">
                    <img class="todo-list-card-edit" src="/assets/edit.svg">
                    <img class="todo-list-card-delete" src="/assets/trash.svg">
                </div>
            </div>

            <style>
                .todo-list-card {
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    width: max-content;
                    font-size: ${cardFontSize};
                    color: white;
                    padding: 0.5em;
                    border-radius: 8px;

                    .todo-list-card-name {
                        cursor: pointer;
                        margin-right: 0.5em;
                    }

                    .todo-list-card-actions {
                        display: flex;
                        gap: 0.5em;

                        img {
                            width: 1em;
                            filter: brightness(0) invert(1);
                            cursor: pointer;
                        }
                    }
                }
            </style>
        `

        this.shadowRoot!.querySelector(".todo-list-card-name")!.addEventListener( "click", (e) => {
            e.stopPropagation()
            getTodoPage().currentListUUID = this.#list.uuid
        })

        this.shadowRoot!.querySelector(".todo-list-card-edit")!.addEventListener( "click", (e) => {
            e.stopPropagation()
            openModalWithElement(new ComponentListForm(this.#list)) 
        })

        this.shadowRoot!.querySelector(".todo-list-card-delete")!.addEventListener( "click", async (e) => {
            e.stopPropagation()

            if ( !confirm(i18n.todoListCardConfirmDelete) ) return
            await listStore.deleteList(this.#list.uuid)
            this.remove()
            getTodoPage().currentListUUID = ""
        })
    }
}

customElements.define("component-list-card", ComponentListCard);