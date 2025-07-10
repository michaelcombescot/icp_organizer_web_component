import { i18n } from "../../../i18n/i18n";
import { ComponentTodo } from "./component_todo";
import { ComponentTodoList, TodoListType } from "./component_todo_list";
import { todoStore } from "../models/store";
import { closeModal, ComponentModal } from "../../../components/modal";
import { css, html, LitElement } from "lit";
import { property, customElement } from 'lit/decorators.js';
import { getList } from "./component_todo_list";
import { enumValues } from "../../../utils/enums";
import { Todo, TodoPriority, TodoStatus } from "../models/todo";

@customElement("component-todo-form")
class ComponentTodoForm extends LitElement {
    @property() todoComponent: ComponentTodo | null = null;

    static create(todo : ComponentTodo | null) : ComponentTodoForm {
        const comp = new ComponentTodoForm();
        comp.todoComponent = todo;
        return comp;
    }

    private handleSubmitForm(e : Event): void {
            e.preventDefault();

            // extract form data and create a new todo
            const formElement = this.shadowRoot!.querySelector("#todo-form-form") as HTMLFormElement;
            const formData = new FormData(formElement);
            formElement.reset();

            const todo = new Todo({
                uuid: this.todoComponent ? this.todoComponent.todo.uuid : crypto.randomUUID(),
                resume: formData.get("resume") as string,
                description: formData.get("description") as string,
                scheduledDate: formData.get("scheduledDate") as string,
                priority: Number(formData.get("priority")) as TodoPriority,
                status: TodoStatus.PENDING,
            });

            // update or create new todo
            if (this.todoComponent) {
                todoStore.updateTodo(todo);     
                this.todoComponent!.todo = todo;
            } else {
                todoStore.addTodo(todo);

                const listType = todo.scheduledDate === "" ? TodoListType.PRIORITY : TodoListType.SCHEDULED;
                const list = getList(listType)

                list.addItem(ComponentTodo.create(todo));
            }            

            // hide popover
            closeModal()
    }

    //
    // RENDER
    //

    static styles = css`
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
    `

    render() {
        return html`
            <div id="todo-form">
                <h2>${this.todoComponent ? i18n.todoFormTitleEdit : i18n.todoFormTitleNew}</h2>

                <form id="todo-form-form" @submit=${this.handleSubmitForm}>
                    <label for="resume" class="required">${i18n.todoFormFieldResume}</label>
                    <input type="text" name="resume" value="${this.todoComponent?.todo.resume ||  ""}" placeholder="What do you need to do?" required />

                    <label for="description">${i18n.todoFormFieldDescription}</label>
                    <textarea type="text" name="description" placeholder="Describe the task" .value=${this.todoComponent?.todo.description ||  ""}></textarea>

                    <label for="scheduledDate">${i18n.todoFormFieldScheduledDate}</label>
                    <input type="datetime-local" name="scheduledDate" value="${this.todoComponent?.todo.scheduledDate ||  ""}" />

                    <label for="priority">${i18n.todoFormFieldPriority}</label>
                    <select name="priority" value="${this.todoComponent?.todo.priority || "1"}">
                        ${
                            enumValues(TodoPriority).map( value => html`
                                <option value="${value}" ?selected=${this.todoComponent?.todo.priority === value}>
                                    ${i18n.todoFormPriority[value as TodoPriority]}
                                </option>
                            `)
                        }
                    </select>
                    
                    <input id="todo-form-submit" type="submit" value="${i18n.todoFormInputSubmit}" />
                </form>
            </div>
        `
    }
}

export { ComponentTodoForm };