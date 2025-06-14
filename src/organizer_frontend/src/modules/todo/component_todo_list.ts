import { LitElement, html, css } from "lit";
import { customElement, property } from "lit/decorators.js";
import { DB } from "../../db/db";
import { ComponentTodo, Todo } from "./component_todo";
import { todoStore } from "./store";

enum TodoListType {
  PRIORITY = "priority",
  SCHEDULED = "scheduled"
}

@customElement("component-todo-list")
class ComponentTodoList extends LitElement {
    @property({ type: Object }) list: ComponentTodo[] = []
    @property({ type: String }) listType!: TodoListType

    async loadList() {
        const todos = await todoStore.getTodos();

        console.log("Todos: ", todos, this.listType);

        switch ( this.listType ) {
            case TodoListType.PRIORITY:
                this.list = todos
                                .filter(todo => !todo.scheduledDate)
                                .sort((a, b) => b.priority.valueOf() - a.priority.valueOf())
                                .map(todo => ComponentTodo.create(todo));
                                
                break;
            case TodoListType.SCHEDULED:
                this.list = todos
                                .filter(todo => todo.scheduledDate)
                                .sort((a, b) => new Date(a.scheduledDate).getTime() - new Date(b.scheduledDate).getTime())
                                .map(todo => ComponentTodo.create(todo))
                break;
            default:
                console.log(`Invalid todo list type ${this.getAttribute("type")}`);
                break;
        }
    }

    async addItem(item: ComponentTodo) {
        await this.loadList();
        this.render();
    }

    //
    // LIFECYCLE
    //

    protected async firstUpdated() {
        await this.loadList();
    }

    //
    // RENDER
    //

    static styles = css`
        .todo-list { 
            display: flex;
            // align-items: center;
            flex-direction: column;
            gap: 1em;
            padding: 1em;
            border-radius: 10px;
            background-color: rgb(3, 252, 194, 0.1); 
        }

        .todo-list-items {
            display: flex;
            flex-direction: column;
            gap: 1em;
        }
    `
    render() {
        return html`
            <div class="todo-list">
                <div class="todo-list-items">
                    ${this.list.map(item => item)}
                </div>
            </div>
        `;
    }
}

const getList = (type : TodoListType) : ComponentTodoList => {
    return document
            .querySelector("main-app")!
            .shadowRoot!.querySelector("component-todo-page")!
            .shadowRoot!.querySelector(`component-todo-list[listType=${type}]`)!;
}

export { TodoListType, ComponentTodoList, getList }