import { i18n } from "../../../i18n/i18n";
import { List } from "../models/list";
import { closeModal } from "../../../components/modal";
import { listStore } from "../models/list_store";
import { getTodoPage } from "./component_todo_page";

export class ComponentListForm extends HTMLElement {
    #list: List | null = null
    #isEditMode: boolean

    constructor(list: List | null = null) {
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

            const list = new List({
                uuid:this.#list ? this.#list.uuid : crypto.randomUUID(),
                name: formData.get("name") as string,
                color: formData.get("color") as string
            });

            // update or create new todo
            if (this.#isEditMode) {
                // listStore.updateList(list);     
            } else {
                listStore.addList(list);
                getTodoPage().updateListSelector();
            }            

            // hide popover
            closeModal()
    }

    #render() {
        this.innerHTML = /*html*/`
            <div id="list-form">
                <h2>Create a new list</h2>

                <form id="list-form-form">
                    <label for="name">${i18n.todoListFormFieldName}</label>
                    <input type="text" name="name" placeholder="${i18n.todoListFormFieldNamePlaceholder}">

                    <label for="color">${i18n.todoListFormFieldColor}</label>
                    <input type="color" name="color" placeholder="List color">

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
                    }
                }
            </style>
        `

        this.querySelector("#list-form-form")!.addEventListener("submit", (e) => this.#handleSubmitForm(e))
    }
}

customElements.define("component-list-form", ComponentListForm);