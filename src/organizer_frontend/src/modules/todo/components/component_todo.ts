import { todoStore } from "../models/store";
import { Todo } from "../models/todo";
import { ComponentTodoForm } from "./component_todo_form";
import { ComponentTodoShow } from "./component_todo_show";
import { css, html, LitElement } from "lit";
import { property, customElement } from "lit/decorators.js";
import { openModal } from "../../../components/modal";

@customElement("component-todo")
class ComponentTodo extends LitElement {
    @property({ type: Object }) todo!: Todo 

    static create(todo: Todo) {
        const compTodo = new ComponentTodo();
        compTodo.todo = todo;
        return compTodo;
    }

    handleDone(): void { this.shadowRoot!.querySelector(`#${this.todo.uuid}`)!.classList.toggle("done") }

    handleOpenEdit(): void { openModal(ComponentTodoForm.create(this)) }

    handleOpenShow(): void { openModal(ComponentTodoShow.create(this)) }

    handleDelete(): void {
        todoStore.deleteTodo(this.todo!.uuid);
        this.remove();
    }

    static styles = css`
        .todo-item {
            box-sizing: border-box;
            display: flex;
            flex-direction: column;
            gap: 1em;
            border-radius: 10px;
            background-color: white;
            padding: 1em;
            
            &.done { background-color: green; }
            
            .todo-item-actions {
                display: flex;
                justify-content: space-between;
            }

            .todo-date {
                display: flex;
                gap: 1em;
                justify-content: space-between;
            }

            .todo-resume {
                &.high { background-color: red; }
                &.medium { background-color: yellow; }
            }
        }
    `


    protected render() {
        return html `
            <div id="${this.todo.uuid}" class="todo-item">
                ${this.todo.scheduledDate != "" ?
                    html`
                        <div class="todo-date">
                            <span>${this.todo.getScheduledDateStr()}</span>
                            <span>${this.todo.getRemainingTimeStr()}</span>
                        </div>
                    ` : ""
                }
                <div class="todo-resume ${this.todo!.priority}" @click=${this.handleOpenShow}>${this.todo!.resume}</div>
                <div class="todo-item-actions">
                    <button id="todo-action-edit" @click=${this.handleOpenEdit}>Edit</button>
                    <button id="todo-action-delete" @click=${this.handleDelete}>Delete</button>
                    <button id="todo-action-done" @click=${this.handleDone}>Done</button>
                </div>
            </div>
        `
    }
}

export { ComponentTodo };