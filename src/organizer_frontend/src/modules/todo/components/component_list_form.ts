import { i18n } from "../../../i18n/i18n";
import { TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { closeModal } from "../../../components/modal";
import { listStore } from "../stores/store_todo_lists";
import { getListsCards } from "./component_list_cards";
import { ComponentListCard } from "./component_list_card";

export class ComponentListForm extends HTMLElement {
    #list: TodoList | null = null
    #isEditMode: boolean

    constructor(list: TodoList | null = null) {
        super();
        this.#list = list
        this.#isEditMode = !!list
    }

    connectedCallback() {
        this.#render();
    }

    async #handleSubmitForm(e : Event) {
            e.preventDefault();

            // extract form data and create a new list
            const formElement = this.querySelector("#list-form-form") as HTMLFormElement;
            const formData = new FormData(formElement);
            formElement.reset();

            const list: TodoList = {
                uuid:this.#list ? this.#list.uuid : crypto.randomUUID(),
                name: formData.get("name") as string,
                color: formData.get("color") as string
            }

            // update or create new todo
            if (this.#isEditMode) {
                await listStore.updateList(list);
                (document.querySelector(`[data-uuid="${list.uuid}"]`)! as ComponentListCard).list = list;
            } else {
                await listStore.addList(list);
                let lists = getListsCards().lists
                lists.push(list)
                getListsCards().lists = lists
            }            

            // hide popover
            closeModal()
    }

    #render() {
        this.innerHTML = /*html*/`
            <div id="list-form">
                <h3>${this.#isEditMode ? i18n.todoListFormTitleEdit : i18n.todoListFormTitleNew}</h3>
                
                <form id="list-form-form">
                    <label for="name" class="required">${i18n.todoListFormFieldName}</label>
                    <input type="text" name="name" value="${this.#list ? this.#list.name : ""}" required>

                    <label for="color" class="required">${i18n.todoListFormFieldColor}</label>
                    <input type="color" name="color" value="${this.#list ? this.#list.color : "#000000"}">

                    <input type="submit" value="${i18n.todoListFormInputSubmit}">
                </form>
            </div>

            <style>
                #list-form {
                    display: flex;
                    flex-direction: column;
                    gap: 3em;
                    align-items: center;

                    form {
                        display: grid;
                        grid-template-columns: 0.5fr 2fr;
                        gap: 1em;
                        width: 70vw;
                        max-width: 60em;

                        .required::after { content: "*"; color: red; }

                        input[type="submit"] { grid-column: -2 / -1; justify-self: right;}
                    }
                }
            </style>
        `

        this.querySelector("#list-form-form")!.addEventListener("submit", (e) => this.#handleSubmitForm(e))
    }
}

customElements.define("component-list-form", ComponentListForm);