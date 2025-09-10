import { i18n } from "../../../i18n/i18n";
import { TodoList } from "../../../../../declarations/backend_todos/backend_todos.did";
import "./componentListCard";
import { getTodoPage } from "./componentTodoPage";
import { cardFontSize, scaleOnHover } from "../../../css/css";
import { ComponentListCard } from "./componentListCard";
import { StoreGlobal } from "../stores/storeGlobal";
import { StoreTodoLists } from "../stores/storeTodoList";

export class ComponentListsCards extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: "open" });
    }

    async connectedCallback() {
        this.#render()
    }

    #render() {
        const lists = StoreTodoLists.todoLists.values()

        this.shadowRoot!.innerHTML = /*html*/`
            <div id="todo-lists-cards">
                <span id="todo-list-card-all">${i18n.todoListCardSeeAll}</span>
            </div>

            <style>
                #todo-lists-cards {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 0.8em;

                    #todo-list-card-all {
                        cursor: pointer;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        font-size: ${cardFontSize};
                        width: max-content;
                        padding: 0.5em;
                        border-radius: 8px;
                        border: 1px solid black;
                        vertical-align: middle;
                        
                        &:hover {
                            transform: scale(${scaleOnHover});
                        }
                    }
                }
            </style>
        `

        this.shadowRoot!.querySelector("#todo-lists-cards")!.append(
            ...lists.map((list) => {
                return new ComponentListCard(list.id)
            })
        )

        this.shadowRoot!.querySelector("#todo-list-card-all")!.addEventListener("click", element => { StoreGlobal.currentSelectedListId = null })
    }
}

customElements.define("component-lists-cards", ComponentListsCards)

export const getListsCards = () => getTodoPage().shadowRoot!.querySelector("component-lists-cards")! as ComponentListsCards