import { i18n } from "../../../i18n/i18n";
import { todoStore } from "../models/store";
import { closeModal } from "../../../components/modal";
import { enumValues } from "../../../utils/enums";
import { Todo, TodoPriority, TodoStatus } from "../models/todo";

class ComponentTodoForm extends HTMLElement {
    todo: Todo | null = null;
    isEditMode: boolean = false;

    constructor(todo : Todo | null, elementToUpdate : HTMLElement | null = null) {
        super();
        this.todo = todo;
        this.isEditMode = !!todo;
    }

    connectedCallback() {
        this.render();

        const formElement = this.querySelector("#todo-form-form") as HTMLFormElement;
        formElement.addEventListener("submit", this.handleSubmitForm.bind(this));
    }

    private handleSubmitForm(e : Event): void {
            e.preventDefault();

            // extract form data and create a new todo
            const formElement = this.querySelector("#todo-form-form") as HTMLFormElement;
            const formData = new FormData(formElement);
            formElement.reset();

            const todo = new Todo({
                uuid: this.todo ? this.todo.uuid : crypto.randomUUID(),
                resume: formData.get("resume") as string,
                description: formData.get("description") as string,
                scheduledDate: formData.get("scheduledDate") as string,
                priority: Number(formData.get("priority")) as TodoPriority,
                status: TodoStatus.PENDING,
            });

            // update or create new todo
            if (this.isEditMode) {
                todoStore.updateTodo(todo);     
            } else {
                todoStore.addTodo(todo);
            }            

            // hide popover
            closeModal()
    }

    //
    // RENDER
    //

    private render() {
        this.innerHTML = /*html*/`
            <div id="todo-form">
                <h2>${this.isEditMode ? i18n.todoFormTitleEdit : i18n.todoFormTitleNew}</h2>

                <form id="todo-form-form">
                    <label for="resume" class="required">${i18n.todoFormFieldResume}</label>
                    <input type="text" name="resume" value="${this.todo?.resume ||  ""}" placeholder="What do you need to do?" required />

                    <label for="description">${i18n.todoFormFieldDescription}</label>
                    <textarea type="text" name="description" placeholder="Describe the task" .value=${this.todo?.description ||  ""}></textarea>

                    <label for="scheduledDate">${i18n.todoFormFieldScheduledDate}</label>
                    <input type="datetime-local" name="scheduledDate" value="${this.todo?.scheduledDate ||  ""}" />

                    <label for="priority">${i18n.todoFormFieldPriority}</label>
                    <select name="priority" value="${this.todo?.priority || "1"}">
                        ${
                            enumValues(TodoPriority).map( value => /*html*/`
                                <option value="${value}" ${this.todo?.priority === value ? "selected" : ""}>
                                    ${i18n.todoFormPriority[value as TodoPriority]}
                                </option>
                            `)
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
    }
}

customElements.define("component-todo-form", ComponentTodoForm);

export { ComponentTodoForm };