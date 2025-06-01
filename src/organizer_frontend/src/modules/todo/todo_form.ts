import { Todo, TodoElement, TodoParams, Priority } from "./todo";
import { TodoListElement } from "./todo_list";

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
        this.querySelector("#todo-form")!.addEventListener("submit", (e: Event) => {
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();

            const todoParams = this.extractFormData();
            const todo = new Todo(todoParams);

            // add to the right list
            const listId = todo.scheduledDate === "" ? "#todo-list-priority" : "#todo-list-scheduled";
            (document.querySelector(listId) as TodoListElement).addItem(new TodoElement(todo))

            // save to db
            todo.save();

            // hide popover
            (document.querySelector("#modal") as ModalElement).hide();
        });
    }

    private extractFormData(): TodoParams {
        const formElement = this.querySelector("#todo-form") as HTMLFormElement;
        const formData = new FormData(formElement);
        formElement.reset();

        return {
            id: this.#todo ? this.#todo.id : crypto.randomUUID(),
            resume: formData.get("resume") as string,
            description: formData.get("description") as string,
            scheduledDate: formData.get("scheduledDate") as string,
            priority: formData.get("priority") as Priority,
            status: "Pending",
        };
    }

    //
    // RENDERER
    //

    render(): void {
        this.innerHTML = `
            <form id="todo-form">
                <input type="text" name="resume" value="${this.#todo ? this.#todo.resume :  ""}" placeholder="What do you need to do?" required />
                <input type="text" name="description" value="${this.#todo ? this.#todo.description :  ""}" placeholder="Describe the task" />
                <input type="datetime-local" name="scheduledDate" value="${this.#todo ? this.#todo.scheduledDate :  ""}" />
                <select name="priority" value="${this.#todo ? this.#todo.priority :  "Medium"}">
                    <option value="High">High</option>
                    <option value="Medium">Medium</option>
                    <option value="Low">Low</option>
                </select>
                <button id="todo-form-submit" type="submit">Add</button>
            </form>
        `;
    }
}

customElements.define("todo-form", TodoFormElement);
