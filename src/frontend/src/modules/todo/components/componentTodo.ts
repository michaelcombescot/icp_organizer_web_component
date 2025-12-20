import { ComponentTodoForm } from "./componentTodoForm";
import { ComponentTodoShow } from "./componentTodoShow";
import { openModalWithElement } from "../../../components/modal";
import { remainingTimeFromEpoch, stringDateFromEpoch } from "../../../utils/date";
import { baseCardColor, borderRadius, scaleOnHover } from "../../../css/css";
import { getComponentTodoLists } from "./componentTodoLists";
import { getContrastColor } from "../../../css/helpers";
import { StoreTodoLists } from "../stores/storeTodoList";
import { StoreTodos } from "../stores/storeTodo";

export class ComponentTodo extends HTMLElement {
    #todoId: bigint = BigInt(0)

    constructor(todoId: bigint) {
        super()
        this.attachShadow({ mode: "open" });

        this.#todoId = todoId
    }

    connectedCallback() {
        this.render();
    }

    render() {
        let todo        = StoreTodos.todos.get(this.#todoId)!;
        let todoList    = todo.todoListId.length != 0 ? StoreTodoLists.todoLists.get(todo.todoListId[0])! : null;

        const contrastColor = getContrastColor(todoList?.color || baseCardColor)

        this.shadowRoot!.innerHTML = /*html*/`
            <div class="todo-item">
                ${todo.scheduledDate.length != 0 ?
                    /*html*/`
                        <div class="todo-item-date">
                            <span>${stringDateFromEpoch(todo.scheduledDate[0])}</span>
                            <span class="todo-item-date-remaining ${todo.scheduledDate[0] < BigInt(Date.now()) ? "expired" : ""}">${remainingTimeFromEpoch(todo.scheduledDate[0])}</span>
                        </div>
                    ` : ""
                }
                <div class="todo-item-resume ${Object.keys(todo.priority)[0]}">${todo.resume}</div>
                <div class="todo-item-actions">
                    <img class="todo-item-action-edit" src="/edit.svg">
                    <img class="todo-item-action-done" src="/done.svg">
                    <img class="todo-item-action-delete" src="/trash.svg">
                </div>
            </div>

            <style>
                .todo-item {
                    display: flex;
                    flex-direction: column;
                    gap: 1em;
                    background-color: ${todoList?.color || baseCardColor};
                    padding: 1em;
                    width: 15em;
                    border-radius: ${borderRadius};
    
                    
                    .todo-item-actions {
                        display: flex;
                        justify-content: space-between;

                        img {
                            width: 1em;
                            filter: invert(${contrastColor == "black" ? 0 : 1});
                            cursor: pointer;

                            &:hover {
                                transform: scale(${scaleOnHover});
                            }
                        }
                    }

                    .todo-item-date {
                        color: ${contrastColor};
                        display: flex;
                        gap: 1em;
                        justify-content: space-between;

                        .todo-item-date-remaining {
                            &.expired {
                                color: red;
                                transform: scale(${scaleOnHover});
                            }
                        }
                    }

                    .todo-item-resume {
                        background-color: white;
                        padding: 0.5em;
                        border-radius: ${borderRadius};
                        word-wrap: break-word;
                        &.high { background-color: red; }
                        &.medium { background-color: yellow; }
                    }
                }
            </style>
        `

        this.shadowRoot!.querySelector(".todo-item-resume")!.addEventListener("click", () => openModalWithElement(new ComponentTodoShow(todo.id)) );

        this.shadowRoot!.querySelector(".todo-item-action-done")!.addEventListener("click", () => this.querySelector(`#${todo.id}`)!.classList.toggle("done") );

        this.shadowRoot!.querySelector(".todo-item-action-edit")!.addEventListener("click", () => openModalWithElement(new ComponentTodoForm(todo.id)));

        this.shadowRoot!.querySelector(".todo-item-action-delete")!.addEventListener("click", () => { StoreTodos.deleteTodo(todo.id) });
    }
}

customElements.define("component-todo", ComponentTodo);

export const getComponentTodo = (todoId: bigint) => getComponentTodoLists().shadowRoot!.querySelector(`[component_todo_id="${todoId}"]`)! as ComponentTodo
export const getComponentTodoOfList = (listUUID: string) => getComponentTodoLists().shadowRoot!.querySelectorAll(`component-todo[listUUID="${listUUID}"]`)