import { i18n } from "../../../i18n/i18n";
import { TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { storeList } from "../stores/store_todo_lists";
import "./component_list_card";
import { getTodoPage } from "./component_todo_page";
import { cardFontSize, scaleOnHover } from "../../../css/css";
import { ComponentListCard } from "./component_list_card";

export class ComponentListsCards extends HTMLElement {
    #lists!: TodoList[]
    get lists() { return this.#lists }
    set lists(lists: TodoList[]) {
        this.#lists = lists
        this.#render()
    }

    #currentListUUID!: string | null
    set currentListUUID(listUUID: string) {
        this.#currentListUUID = listUUID
        this.#render()
    }

    constructor() {
        super();
        this.attachShadow({ mode: "open" });
    }

    async connectedCallback() {
        this.#currentListUUID = this.getAttribute("currentListUUID")
        this.#lists = await storeList.apiGetTodoLists()
        this.#render()
    }

    #render() {
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
            ...this.#lists.map((list) => {
                const card = new ComponentListCard(list, list.uuid === this.#currentListUUID)
                card.setAttribute("list-uuid", list.uuid)
                return card
            })
        )

        this.shadowRoot!.querySelector("#todo-list-card-all")!.addEventListener("click", element => {
            getTodoPage().currentListUUID = ""
            this.#currentListUUID = ""
        })
    }
}

customElements.define("component-lists-cards", ComponentListsCards)

export const getListsCards = () => getTodoPage().shadowRoot!.querySelector("component-lists-cards")! as ComponentListsCards