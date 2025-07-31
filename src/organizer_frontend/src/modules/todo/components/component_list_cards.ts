import { i18n } from "../../../i18n/i18n";
import { List } from "../models/list";
import { listStore } from "../models/list_store";
import { ComponentListCard } from "./component_list_card";
import { getTodoPage } from "./component_todo_page";
import { cardFontSize } from "../models/css";

export class ComponentListsCards extends HTMLElement {
    #lists: List[]
    get lists() { return this.#lists }
    set lists(lists: List[]) {
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
        this.#selectedListUUID = this.getAttribute("data-selected-list-uuid")!
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
                        font-size: ${cardFontSize};
                        width: max-content;
                        padding: 0.5em;
                        border-radius: 8px;
                        border: 1px solid black;
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