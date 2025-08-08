import { openModalWithElement } from "../../../components/modal";
import { ComponentListForm } from "./component_list_form";
import { i18n } from "../../../i18n/i18n";
import { getTodoPage } from "./component_todo_page";
import { ComponentTodo } from "./component_todo";
import { borderRadius, cardFontSize, scaleOnHover } from "../../../css/css";
import { getListsCards } from "./component_list_cards";
import { Todo, TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { storeList } from "../stores/store_todo_lists";

export class ComponentListCard extends HTMLElement {
    #list!: TodoList
    set list(list: TodoList) {
        this.#list = list
        this.#render()

        document.querySelectorAll(`[data-list-uuid="${this.#list.uuid}"]`).forEach((todo) => {
            (todo as ComponentTodo).list = this.#list
        })
    }

    #isSelected!: boolean
    set isSelected(isSelected: boolean) {
        getTodoPage().currentListUUID = this.#list.uuid
    }

    constructor() {
        super();
        this.attachShadow({ mode: "open" });
    }

    connectedCallback() {
        try {this.#list = JSON.parse(decodeURIComponent(this.getAttribute("list")!)) } catch { throw new Error("list attribute is required, or malformed") }
        this.#isSelected = this.getAttribute("isSelected") === "true"

        this.#render();
    }

    #render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <div class="todo-list-card ${this.#isSelected ? "selected" : ""}">
                <span class="todo-list-card-name">${this.#list.name}</span>
                <div class="todo-list-card-actions">
                    <img class="todo-list-card-edit" src="/edit.svg">
                    <img class="todo-list-card-delete" src="/trash.svg">
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
                    border-radius: ${borderRadius};
                    border: 0.3em solid ;
                    background-color: ${this.#list.color};

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

                    &.selected {
                        border: 0.3em solid black;
                    }

                    &:hover {
                        transform: scale(${scaleOnHover});
                    }
                }
            </style>
        `

        this.shadowRoot!.querySelector(".todo-list-card-name")!.addEventListener( "click", (e) => {
            e.stopPropagation()
            this.isSelected = true
        })

        this.shadowRoot!.querySelector(".todo-list-card-edit")!.addEventListener( "click", (e) => {
            e.stopPropagation()
            openModalWithElement(new ComponentListForm(this.#list)) 
        })

        this.shadowRoot!.querySelector(".todo-list-card-delete")!.addEventListener( "click", async (e) => {
            e.stopPropagation()

            if ( !confirm(i18n.todoListCardConfirmDelete) ) return

            await (await storeList).apiDeleteTodoList(this.#list.uuid)
            this.remove()
            getTodoPage().currentListUUID = ""
        })
    }
}

customElements.define("component-list-card", ComponentListCard);