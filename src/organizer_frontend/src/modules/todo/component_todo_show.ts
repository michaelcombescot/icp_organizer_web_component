import { LitElement, css, html } from "lit";
import { property, customElement } from "lit/decorators.js";
import { ComponentTodo } from "./component_todo";

@customElement('todo-show')
export class ComponentTodoShow extends LitElement {
    @property({ type: Object }) todoComponent!: ComponentTodo

    static create (todoComponent : ComponentTodo) : ComponentTodoShow {
        const comp = new this();
        comp.todoComponent = todoComponent;
        return comp
    }

    static style = css`
        #todo-show {
            display: flex;
            flex-direction: column;
            gap: 1em;
        }
    `

    render() {
        return html`
            <div id="todo-show">
                <div>${this.todoComponent.todo!.resume}</div>
                <div>${this.todoComponent.todo!.description}</div>
                <div>${this.todoComponent.todo!.scheduledDate}</div>
                <div>${this.todoComponent.todo!.priority}</div>
                <div>${this.todoComponent.todo!.status}</div>
            </div>
        `
    }
}