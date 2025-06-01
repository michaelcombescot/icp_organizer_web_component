import { Todo, TodoElement, TodoParams } from "./todo";
import { TodoListElement } from "./todo_list";

class TodoFormElement extends HTMLElement {
    //
    // ATTRIBUTES
    //

    #popoverID: string | null;

    //
    // INITIALIZATION
    //

    constructor() {
        super();
        this.attachShadow({ mode: "open" });
        this.#popoverID = this.getAttribute("popover-id");
    }

    connectedCallback(): void {
        this.render();
        this.handleSubmitForm();
    }

    //
    // TRIGGERS
    //

    private handleSubmitForm(): void {
        this.shadowRoot!.querySelector("#todo-form")!.addEventListener("submit", (e: Event) => {
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();

            const formElement = this.shadowRoot!.querySelector("#todo-form") as HTMLFormElement;
            const formData = new FormData(formElement);
            formElement.reset();

            let data = Object.fromEntries(formData.entries());

            data.id = crypto.randomUUID();
           

            // create and validate todo
            const params: TodoParams = {
                id: data.id,
                resume: data.resume as string,
                description: data.description as string,
                scheduledDate: data.scheduledDate as string,
                priority: data.priority as string
            }

            const todo = new Todo(params);

            // add to the right list
            const listId = !todo.scheduledDate ? "#todo-list-priority" : "#todo-list-scheduled";

            (document.querySelector(listId) as TodoListElement).addItem(new TodoElement(todo))

            // save to db
            todo.save();

            // hide popover
            (document.querySelector(`[popover-id=${this.#popoverID}]`) as any).hidePopover();
        });
    }

    //
    // RENDERER
    //
    private render(): void {
        this.shadowRoot!.innerHTML = `
            <form id="todo-form">
                <input type="text" name="resume" placeholder="What do you need to do?" required />
                <input type="text" name="description" placeholder="Describe the task" />
                <input type="datetime-local" name="scheduled-date" />
                <select name="priority">
                    <option value="high">High</option>
                    <option value="medium">Medium</option>
                    <option value="low">Low</option>
                </select>
                <button id="todo-form-submit" type="submit">Add</button>
            </form>
        `;
    }
}

customElements.define("todo-form", TodoFormElement);
