import { i18n } from "../../../i18n/i18n";
import { TodoList } from "../../../../../declarations/backend_todos/backend_todos.did";
import { closeModal } from "../../../components/modal";
import { getListsCards } from "./componentListCards";
import { getLoadingComponent } from "../../../components/loading";
import { StoreTodoLists } from "../stores/storeTodoList";

export class ComponentListForm extends HTMLElement {
    #list: TodoList | null = null
    #isEditMode: boolean

    constructor(listId: bigint | null) {
        super();
        this.attachShadow({ mode: "open" });
        
        this.#list = listId ? StoreTodoLists.todoLists.get(listId)! : null
        this.#isEditMode = !!listId
    }

    connectedCallback() {
        this.#render();
    }

    async #handleSubmitForm(e : Event) {
        e.preventDefault();

        // extract form data and create a new list
        const formElement = this.shadowRoot!.querySelector("#list-form-form") as HTMLFormElement;
        const formData = new FormData(formElement);
        formElement.reset();

        const list: TodoList = {
            id: this.#list ? this.#list.id : BigInt(0),
            name: formData.get("name") as string,
            color: formData.get("color") as string
        }

        getLoadingComponent().wrapAsync(async () => { 
            if (this.#isEditMode) {
                await StoreTodoLists.updateTodoList(list);
            } else {
                await StoreTodoLists.createTodoList(list);
            }            

            closeModal()
        })            
    }

    #render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <div id="list-form">
                <h3>${this.#isEditMode ? i18n.todoListFormTitleEdit : i18n.todoListFormTitleNew}</h3>
                
                <form id="list-form-form">
                    <label for="name" class="required">${i18n.todoListFormFieldName}</label>
                    <input type="text" name="name" value="${this.#list ? this.#list.name : ""}" maxLenght="30" required>

                    <label for="color" class="required">${i18n.todoListFormFieldColor}</label>
                    <input type="color" name="color" value="${this.#list?.color}" required>

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

        this.shadowRoot!.querySelector("#list-form-form")!.addEventListener("submit", (e) => this.#handleSubmitForm(e))
    }
}

customElements.define("component-list-form", ComponentListForm);