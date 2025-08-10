import { i18n } from "../../../i18n/i18n";
import { storeTodo } from "../stores/store_todos";
import { closeModal } from "../../../components/modal";
import { Todo } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { stringToEpoch } from "../../../utils/date";
import { getTodoPage } from "./component_todo_page";
import { storeList } from "../stores/store_todo_lists";
import { epochToStringRFC3339 } from "../../../utils/date";
import { getComponentTodoLists } from "./component_todo_lists";

class ComponentTodoForm extends HTMLElement {
    #todo: Todo | null = null;
    #isEditMode: boolean = false;
    #currentListUUID: string
    #validationErrors: Record<string, string[]> = {};

    constructor(todo : Todo | null, currentListUUID : string) {
        super();
        this.attachShadow({ mode: "open" });

        this.#todo = todo;
        this.#isEditMode = !!todo;
        this.#currentListUUID = currentListUUID
    }

    connectedCallback() {
        this.#render();
    }

    private async handleSubmitForm(e : Event) {
            e.preventDefault();

            // extract form data and create a new todo
            const formElement = this.shadowRoot!.querySelector("#todo-form-form") as HTMLFormElement;
            const formData = new FormData(formElement);

            const todo: Todo = {
                uuid: this.#todo?.uuid || crypto.randomUUID(),
                resume: formData.get("resume") as string,
                description: formData.get("description") as string,
                scheduledDate: formData.get("scheduledDate") == "" ? [] : [stringToEpoch(formData.get("scheduledDate") as string)],
                priority:   formData.get("priority") === "low" ? { low: null } :
                            formData.get("priority") === "medium" ? { medium: null } :
                            { high: null },
                status: { 'pending' : null },
                todoListUUID: formData.get("listUUID") == "" ? [] : [formData.get("listUUID") as string],
                createdAt: this.#todo?.createdAt || BigInt(Date.now())
            }

            // update or create todo
            if (this.#isEditMode) {
                await storeTodo.apiUpdateTodo(todo)
            } else {
                await storeTodo.apiAddTodo(todo)
            }

            getComponentTodoLists().update()

            // hide popover
            closeModal()
    }

    //
    // RENDER
    //

    async #render() {
        const priorityValue = this.#todo ? Object.keys(this.#todo!.priority)[0] : "low";

        const lists = await storeList.apiGetTodoLists()

        this.shadowRoot!.innerHTML = /*html*/`
            <div id="todo-form">
                <h3>${this.#isEditMode ? i18n.todoFormTitleEdit : i18n.todoFormTitleNew}</h3>

                <form id="todo-form-form">
                    <label for="resume" class="required">${i18n.todoFormFieldResume}</label>
                    <input type="text" name="resume" value="${this.#todo?.resume ||  ""}" placeholder="${i18n.todoFormFieldResumePlaceholder}" maxLength="100" required />

                    <label for="description">${i18n.todoFormFieldDescription}</label>
                    <textarea type="text" name="description" placeholder="${i18n.todoFormFieldDescriptionPlaceholder}" maxLength="3000">${this.#todo?.description ||  ""}</textarea>

                    <label for="scheduledDate">${i18n.todoFormFieldScheduledDate}</label>
                    <input type="datetime-local" name="scheduledDate" value="${ this.#todo && this.#todo?.scheduledDate.length != 0 ? epochToStringRFC3339(this.#todo!.scheduledDate[0] as bigint) : null }" min="${new Date().toISOString().slice(0, 16)}"/>

                    <label for="priority">${i18n.todoFormFieldPriority}</label>
                    <select name="priority">
                        ${
                            storeTodo.defTodoPriorities.map( value => /*html*/`
                                <option value="${value}" ${value === priorityValue ? "selected" : ""}>
                                    ${i18n.todoFormPriorities[value]}
                                </option>
                            `)
                        }
                    </select>

                    <label for="listUUID">${i18n.todoFormFieldList}</label>
                    <select name="listUUID">
                        <option value=""></option>
                        ${
                            lists.map( list => 
                                /*html*/`
                                    <option value="${list.uuid}" ${list.uuid === this.#todo?.todoListUUID[0] || list.uuid === this.#currentListUUID ? "selected" : ""}>
                                        ${list.name}
                                    </option>
                                `
                            ).join("")
                        }
                    </select>
                    
                    <input id="todo-form-submit" type="submit" value="${i18n.todoFormInputSubmit}" />
                </form>
            </div>

            <style>
                #todo-form {
                    display: flex;
                    flex-direction: column;
                    gap: 3em;
                    align-items: center;

                    form {
                        display: grid;
                        grid-template-columns: 0.5fr 2fr;
                        grid-template-rows: 1fr 3fr 1fr 1fr 1fr;
                        grid-auto-rows: 1fr;
                        gap: 2em;
                        align-items: center;
                        width: 70vw;
                        max-width: 60em;

                        .required::after { content: "*"; color: red; }
                        input { box-sizing: border-box; }

                        textarea { height: 100%; resize: none; }

                        input[type="submit"] { grid-column: -2 / -1; justify-self: right;}
                    }
                }
            </style>
        `

        this.shadowRoot!.querySelector("#todo-form-form")!.addEventListener("submit", this.handleSubmitForm.bind(this));
    }
}

customElements.define("component-todo-form", ComponentTodoForm);

export { ComponentTodoForm };