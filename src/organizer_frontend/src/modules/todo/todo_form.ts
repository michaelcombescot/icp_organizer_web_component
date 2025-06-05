import { i18n } from "../../i18n/i18n";
import { Todo, TodoElement, TodoParams, Priority } from "./todo";
import { TodoListElement } from "./todo_list";
import { todoStore } from "./todo_store";

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
        this.querySelector("#todo-form-form")!.addEventListener("submit", (e: Event) => {
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();

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
        const formElement = this.querySelector("#todo-form-form") as HTMLFormElement;
        const formData = new FormData(formElement);
        formElement.reset();

        return {
            id: this.#todo ? this.#todo.id : crypto.randomUUID(),
            resume: formData.get("resume") as string,
            description: formData.get("description") as string,
            scheduledDate: formData.get("scheduledDate") as string,
            priority: formData.get("priority") as Priority,
            status: "pending",
        };
    }

    //
    // RENDERER
    //

    
    

    render(): void {
        this.innerHTML = `
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
                <h2>${this.#todo ? i18n.toDoFormTitleEdit : i18n.toDoFormTitleNew}</h2>

                <form id="todo-form-form">
                    <label for="resume">${i18n.todoFormFieldResume}</label>
                    <input type="text" name="resume" value="${this.#todo ? this.#todo.resume :  ""}" placeholder="What do you need to do?" required />

                    <label for="description">${i18n.todoFormFieldDescription}</label>
                    <textarea type="text" name="description" value="${this.#todo ? this.#todo.description :  ""}" placeholder="Describe the task"></textarea>

                    <label for="scheduledDate">${i18n.todoFormFieldScheduledDate}</label>
                    <input type="datetime-local" name="scheduledDate" value="${this.#todo ? this.#todo.scheduledDate :  ""}" />

                    <label for="priority">${i18n.todoFormFieldPriority}</label>
                    <select name="priority" value="${this.#todo ? this.#todo.priority :  "low"}">
                        <option value="low" selected>Low</option>
                        <option value="medium">Medium</option>
                        <option value="high">High</option>
                    </select>
                    
                    <input id="todo-form-submit" type="submit" value="${i18n.todoFormInputSubmit}" />
                </form>
            </div>
        `;
    }
}

customElements.define("todo-form", TodoFormElement);

export { TodoFormElement };