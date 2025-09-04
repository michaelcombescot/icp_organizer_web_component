import { storeTodo, TodoWithList } from "../stores/store_todos";
import { ComponentTodoForm } from "./component_todo_form";
import { ComponentTodoShow } from "./component_todo_show";
import { openModalWithElement } from "../../../components/modal";
import { remainingTimeFromEpoch, stringDateFromEpoch } from "../../../utils/date";
import { baseCardColor, borderRadius, scaleOnHover } from "../../../css/css";
import { TodoList } from "../../../../../declarations/backend/backend.did";
import { getComponentTodoLists } from "./component_todo_lists";
import { getContrastColor } from "../../../css/helpers";
import { getLoadingComponent } from "../../../components/loading";

export class ComponentTodo extends HTMLElement {
    #todo: TodoWithList
    set todo(todo: TodoWithList) {
        this.#todo = todo
        this.#render()
    }

    #todoList: TodoList | null = null
    set todoList(todoList: TodoList | null) {
        this.#todo.todoList = todoList
        this.#render()
    }

    constructor(todo: TodoWithList) {
        super()
        this.attachShadow({ mode: "open" });

        this.#todo = todo
    }

    connectedCallback() {
        this.#render();
    }

    #render() {
        const contrastColor = getContrastColor(this.#todo.todoList?.color || baseCardColor)

        this.shadowRoot!.innerHTML = /*html*/`
            <div class="todo-item">
                ${this.#todo.scheduledDate.length != 0 ?
                    /*html*/`
                        <div class="todo-item-date">
                            <span>${stringDateFromEpoch(this.#todo.scheduledDate[0])}</span>
                            <span class="todo-item-date-remaining ${this.#todo.scheduledDate[0] < BigInt(Date.now()) ? "expired" : ""}">${remainingTimeFromEpoch(this.#todo.scheduledDate[0])}</span>
                        </div>
                    ` : ""
                }
                <div class="todo-item-resume ${Object.keys(this.#todo.priority)[0]}">${this.#todo.resume}</div>
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
                    background-color: ${this.#todo.todoList?.color || baseCardColor};
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

        this.shadowRoot!.querySelector(".todo-item-resume")!.addEventListener("click", () => openModalWithElement(new ComponentTodoShow(this.#todo)) );

        this.shadowRoot!.querySelector(".todo-item-action-done")!.addEventListener("click", () => this.querySelector(`#${this.#todo.uuid}`)!.classList.toggle("done") );

        this.shadowRoot!.querySelector(".todo-item-action-edit")!.addEventListener("click", () => openModalWithElement(new ComponentTodoForm(this.#todo, this.#todo.todoListUUID[0] as string))  );

        this.shadowRoot!.querySelector(".todo-item-action-delete")!.addEventListener("click", () => {
            getLoadingComponent().wrapAsync(async () => {
                await storeTodo.apiDeleteTodo(this.#todo.uuid)
                this.remove();
                getLoadingComponent().hide();
            })
        });
    }
}

customElements.define("component-todo", ComponentTodo);

export const getComponentTodos = () => getComponentTodoLists().shadowRoot!.querySelectorAll(`component-todo`)
export const getComponentTodoOfList = (listUUID: string) => getComponentTodoLists().shadowRoot!.querySelectorAll(`component-todo[listUUID="${listUUID}"]`)