import { i18n } from "../../i18n/i18n";
import { Todo, TodoElement, TodoParams, Priority } from "./element_todo";
import { TodoListElement } from "./element_todo_list";
import { todoStore } from "./store";

class TodoFormElement extends HTMLElement {
    //
    // ATTRIBUTES
    //

    #popoverID: string | null;
    #todo: Todo | null;

    //
    // INITIALIZATION
    //

    constructor(todo: Todo | null) {
        super();
        this.attachShadow({ mode: "open" });

        this.#popoverID = this.getAttribute("popover-id");
        this.#todo = todo;
    }

    connectedCallback(): void {
        this.render();
        this.handleSubmitForm();
    }

    //
    // TRIGGERS
    //

    private handleSubmitForm(): void {
        this.shadowRoot!.querySelector("#todo-form-form")!.addEventListener("submit", (e: Event) => {
            e.preventDefault();

            const todo = this.extractFormData();

            // save and display
            if (this.#todo) {
                todoStore.updateTodo(todo);

                const todoElement = document.querySelector(`#todo-item-${this.#todo.id}`)?.parentElement as TodoElement;
                todoElement.todo = todo;
            } else {
                todoStore.addTodo(todo);

                const listId = todo.scheduledDate === "" ? "#todo-list-priority" : "#todo-list-scheduled";
                (document.querySelector(listId) as TodoListElement).addItem(new TodoElement(todo))
            }            

            // hide popover
            (document.querySelector("#modal") as ModalElement).hide();
        });
    }

    private extractFormData(): Todo {
        const formElement = this.shadowRoot!.querySelector("#todo-form-form") as HTMLFormElement;
        const formData = new FormData(formElement);
        formElement.reset();

        return new Todo({
            id: this.#todo ? this.#todo.id : crypto.randomUUID(),
            resume: formData.get("resume") as string,
            description: formData.get("description") as string,
            scheduledDate: formData.get("scheduledDate") as string,
            priority: Number(formData.get("priority")) as Priority,
            status: "pending",
        });
    }

    //
    // RENDERER
    //

    render(): void {
        this.shadowRoot!.innerHTML = /*html*/`
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

                        label[for="resume"]::after { content: "*"; color: red; }
                        input { box-sizing: border-box; }

                        textarea { height: 100%; resize: none; }

                        input[type="submit"] { grid-column: -2 / -1; justify-self: right;}
                    }
                }
            </style>

            <div id="todo-form">
                <h2>${this.#todo ? i18n.todoFormTitleEdit : i18n.todoFormTitleNew}</h2>

                <form id="todo-form-form">
                    <label for="resume">${i18n.todoFormFieldResume}</label>
                    <input type="text" name="resume" value="${this.#todo ? this.#todo.resume :  ""}" placeholder="What do you need to do?" required />

                    <label for="description">${i18n.todoFormFieldDescription}</label>
                    <textarea type="text" name="description" value="" placeholder="Describe the task">${this.#todo ? this.#todo.description :  ""}</textarea>

                    <label for="scheduledDate">${i18n.todoFormFieldScheduledDate}</label>
                    <input type="datetime-local" name="scheduledDate" value="${this.#todo ? this.#todo.scheduledDate :  ""}" />

                    <label for="priority">${i18n.todoFormFieldPriority}</label>
                    <select name="priority" value="${this.#todo ? this.#todo.priority :  "1"}">
                        <option value="1">Low</option>
                        <option value="2">Medium</option>
                        <option value="3">High</option>
                    </select>
                    
                    <input id="todo-form-submit" type="submit" value="${i18n.todoFormInputSubmit}" />
                </form>
            </div>
        `;

        const selectPriority = this.shadowRoot!.querySelector("select[name=priority]") as HTMLSelectElement;
        selectPriority.value = this.#todo ? this.#todo.priority.toString() : "1";
    }
}

customElements.define("todo-form", TodoFormElement);

export { TodoFormElement };