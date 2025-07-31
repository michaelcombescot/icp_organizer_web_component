import { i18n } from "../../../i18n/i18n";
import { todoStore } from "../models/todo_store";
import { closeModal } from "../../../components/modal";
import { Todo, priorityValues } from "../models/todo";
import { stringToEpoch } from "../../../utils/date";
import { getTodoPage } from "./component_todo_page";
import { listStore } from "../models/list_store";
import { epochToStringRFC3339 } from "../../../utils/date";

class ComponentTodoForm extends HTMLElement {
    todo: Todo | null = null;
    isEditMode: boolean = false;
    currentListUUID: string

    constructor(todo : Todo | null, currentListUUID : string) {
        super();
        this.todo = todo;
        this.isEditMode = !!todo;
        this.currentListUUID = currentListUUID
    }

    connectedCallback() {
        this.#render();
    }

    #bindEvents() {
        this.querySelector("#todo-form-form")!.addEventListener("submit", this.handleSubmitForm.bind(this));
    }

    private async handleSubmitForm(e : Event) {
            e.preventDefault();

            // extract form data and create a new todo
            const formElement = this.querySelector("#todo-form-form") as HTMLFormElement;
            const formData = new FormData(formElement);
            formElement.reset();

            const todo = new Todo({
                uuid: this.todo ? this.todo.uuid : crypto.randomUUID(),
                resume: formData.get("resume") as string,
                description: formData.get("description") as string,
                scheduledDate: stringToEpoch(formData.get("scheduledDate") as string),
                priority:   formData.get("priority") === "low" ? { low: null } :
                            formData.get("priority") === "medium" ? { medium: null } :
                            { high: null },
                status: { 'pending' : null },
                listUUID: formData.get("listUUID") as string
            });

            // update or create new todo
            if (this.isEditMode) {
                todoStore.updateTodo(todo);     
            } else {
                todoStore.addTodo(todo);
            }

            // update the todo page
            getTodoPage().update();

            // hide popover
            closeModal()
    }

    //
    // RENDER
    //

    async #render() {
        const priorityValue = this.todo ?
                                Object.keys(this.todo!.priority)[0]
                                : "low";

        const lists = await listStore.getLists()

        this.innerHTML = /*html*/`
            <div id="todo-form">
                <h3>${this.isEditMode ? i18n.todoFormTitleEdit : i18n.todoFormTitleNew}</h3>

                <form id="todo-form-form">
                    <label for="resume" class="required">${i18n.todoFormFieldResume}</label>
                    <input type="text" name="resume" value="${this.todo?.resume ||  ""}" placeholder="${i18n.todoFormFieldResumePlaceholder}" required />

                    <label for="description">${i18n.todoFormFieldDescription}</label>
                    <textarea type="text" name="description" placeholder="${i18n.todoFormFieldDescriptionPlaceholder}">${this.todo?.description ||  ""}</textarea>

                    <label for="scheduledDate">${i18n.todoFormFieldScheduledDate}</label>
                    <input type="datetime-local" name="scheduledDate" value="${this.todo?.scheduledDate ? epochToStringRFC3339(this.todo.scheduledDate) : ""}" />

                    <label for="priority">${i18n.todoFormFieldPriority}</label>
                    <select name="priority">
                        ${
                            priorityValues.map( value => /*html*/`
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
                                    <option value="${list.uuid}" ${list.uuid === this.todo?.listUUID || list.uuid === this.currentListUUID ? "selected" : ""}>
                                        ${list.name}
                                    </option>
                                `
                            )
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

        this.#bindEvents();
    }
}

customElements.define("component-todo-form", ComponentTodoForm);

export { ComponentTodoForm };