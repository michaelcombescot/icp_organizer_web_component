import { i18n } from "../../../i18n/i18n";
import { TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { listStore } from "../stores/store_todo_lists";
import { ComponentListCard } from "./component_list_card";
import { getTodoPage } from "./component_todo_page";
import { cardFontSize, scaleOnHover } from "../../../css/css";

export class ComponentListsCards extends HTMLElement {
    #lists: TodoList[]
    get lists() { return this.#lists }
    set lists(lists: TodoList[]) {
        this.#lists = lists 
        this.#render()
    }

    #selectedListUUID = ""
    set selectedListUUID(listUUID: string) {
        this.#selectedListUUID = listUUID
        this.#render()
    }

    constructor() {
        super();
        this.#lists = []
        this.#selectedListUUID = this.getAttribute("selectedListUUID")!
    }

    connectedCallback() {
        this.#render()
    }

    async #render() {
        this.#lists = await listStore.getLists()

        this.innerHTML = /*html*/`
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

        this.#lists.forEach(list => {
            let newCard = new ComponentListCard(list, this.#selectedListUUID === list.uuid)
            newCard.setAttribute("data-uuid", list.uuid)
            this.querySelector("#todo-lists-cards")!.appendChild(newCard)
        })

        this.querySelector("#todo-list-card-all")!.addEventListener("click", element => {
            getTodoPage().currentListUUID = ""
            this.selectedListUUID = ""
        })
    }
}

customElements.define("component-lists-cards", ComponentListsCards)

export const getListsCards = () => document.querySelector("component-lists-cards")! as ComponentListsCards