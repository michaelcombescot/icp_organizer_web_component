import { openModalWithElement } from "../../../components/modal";
import { ComponentListForm } from "./componentListForm";
import { i18n } from "../../../i18n/i18n";
import { getTodoPage } from "./componentTodoPage";
import { ComponentTodo, getComponentTodoOfList } from "./componentTodo";
import { borderRadius, cardFontSize, scaleOnHover } from "../../../css/css";
import { getListsCards } from "./componentListCards";
import { Todo, TodoList } from "../../../../../declarations/organizerTodosBucket/organizerTodosBucket.did";
import { getContrastColor } from "../../../css/helpers";
import { getLoadingComponent } from "../../../components/loading";
import { StoreGlobal } from "../stores/storeGlobal";
import { StoreTodoLists } from "../stores/storeTodoList";

export class ComponentListCard extends HTMLElement {
    #listId: bigint

    constructor(listId: bigint) {
        super();
        this.attachShadow({ mode: "open" });

        this.#listId = listId
    }

    connectedCallback() {
        this.#render();
    }

    #render() {
        const list          = StoreTodoLists.todoLists.get(this.#listId)!
        const isSelected    = StoreGlobal.currentSelectedListId === list.id
        const contrastColor = getContrastColor(list.color)

        this.shadowRoot!.innerHTML = /*html*/`
            <div class="todo-list-card ${ isSelected ? "selected" : "" }">
                <span class="todo-list-card-name">${ list.name }</span>
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
                    font-size: ${ cardFontSize };
                    color: ${ contrastColor };
                    padding: 0.5em;
                    border-radius: ${borderRadius};
                    border: 0.3em solid transparent;
                    background-color: ${ list.color };

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
            StoreGlobal.updateCurrentSelectedListId(list.id)
        })

        this.shadowRoot!.querySelector(".todo-list-card-edit")!.addEventListener( "click", (e) => {
            e.stopPropagation()
            openModalWithElement(new ComponentListForm(list.id)) 
        })

        this.shadowRoot!.querySelector(".todo-list-card-delete")!.addEventListener( "click", async (e) => {
            e.stopPropagation()

            if ( !confirm(i18n.todoListCardConfirmDelete) ) return

            StoreTodoLists.deleteTodoList(list.id)
        })
    }
}

customElements.define("component-list-card", ComponentListCard);

export const getCard = (id: bigint) => getListsCards().shadowRoot!.querySelector(`component-list-card[list-uuid="${id}"]`) as ComponentListCard