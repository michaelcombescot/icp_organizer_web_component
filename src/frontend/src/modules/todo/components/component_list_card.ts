import { openModalWithElement } from "../../../components/modal";
import { ComponentListForm } from "./component_list_form";
import { i18n } from "../../../i18n/i18n";
import { getTodoPage } from "./component_todo_page";
import { ComponentTodo, getComponentTodoOfList } from "./component_todo";
import { borderRadius, cardFontSize, scaleOnHover } from "../../../css/css";
import { getListsCards } from "./component_list_cards";
import { Todo, TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { storeList } from "../stores/store_todo_lists";
import { getContrastColor } from "../../../css/helpers";
import { getLoadingComponent } from "../../../components/loading";

export class ComponentListCard extends HTMLElement {
    #list!: TodoList
    // when a list is updated, we need to update the card itself, and ell ComponentTodo linked to this card (especially for the color)
    set list(list: TodoList) {
        this.#list = list
        this.#render()

        getComponentTodoOfList(this.#list.uuid).forEach((todo) => {
            (todo as ComponentTodo).todoList = this.#list
        })
    }

    #isSelected!: boolean
    set isSelected(isSelected: boolean) {
        if ( this.#isSelected == isSelected ) { return }

        getTodoPage().currentListUUID = this.#list.uuid
    }

    constructor(list: TodoList, isSelected: boolean = false) {
        super();
        this.attachShadow({ mode: "open" });

        this.#list = list
        this.#isSelected = isSelected
    }

    connectedCallback() {
        this.#render();
    }

    #render() {
        const contrastColor = getContrastColor(this.#list.color)

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
                    color: ${contrastColor};
                    padding: 0.5em;
                    border-radius: ${borderRadius};
                    border: 0.3em solid transparent;
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
                            filter: invert(${contrastColor === "black" ? 0 : 1});
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

            getLoadingComponent().wrapAsync( async () => {
                await storeList.apiDeleteTodoList(this.#list.uuid)
                this.remove()

                if ( this.#isSelected) {
                    getTodoPage().currentListUUID = ""
                }
            })
        })
    }
}

customElements.define("component-list-card", ComponentListCard);

export const getCard = (uuid: string) => getListsCards().shadowRoot!.querySelector(`component-list-card[list-uuid="${uuid}"]`) as ComponentListCard