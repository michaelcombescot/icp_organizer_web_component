import "./component_todo_list";
import { ComponentTodoForm } from "./component_todo_form";
import { openModalWithElement } from "../../../components/modal";
import { i18n } from "../../../i18n/i18n";
import { todoStore } from "../models/todo_store";
import { ComponentListForm } from "./component_list_form";
import { Todo, sortByPriority, sortByScheduledDate } from "../models/todo";
import { ComponentTodoList } from "./component_todo_list";

class ComponentTodoPage extends HTMLElement {
    constructor() {
        super()
    }

    async connectedCallback() {
        this.#render()
        this.update()
    }

    async update() {
        const todos = await todoStore.getTodos()
        let priorityTodos: Todo[] = []
        let scheduledTodos: Todo[] = []

        for ( const todo of todos ) {
            if (!todo.scheduledDate) {
                priorityTodos.push(todo)
            } else {
                scheduledTodos.push(todo)
            }
        }

        (this.querySelector("#todo-list-priority")! as ComponentTodoList).list = sortByPriority(priorityTodos);
        (this.querySelector("#todo-list-scheduled")! as ComponentTodoList).list = sortByScheduledDate(scheduledTodos);
    }

    #render() {
        this.innerHTML = /*html*/`
            <div id="todo-page">
                <div id="todo-page-buttons">
                    <button id="todo-open-modal-new-task">${ i18n.todoCreateNewButton }</button>
                    <button id="todo-open-modal-new-list">${ i18n.todoListCreateButton }</button>
                </div>

                <div id="todo-lists">
                    <component-todo-list id="todo-list-priority" listType="priority"></component-todo-list>
                    <component-todo-list id="todo-list-scheduled" listType="scheduled"></component-todo-list>
                </div>
            </div>

            <style>
                #todo-page {
                    display: flex;
                    flex-direction: column;
                    gap: 2em;

                    #todo-page-buttons {
                        display: flex
                        gap: 1em;

                        #todo-open-modal-new-task {
                            width: max-content;
                        }
                        
                        #todo-open-modal-new-list {
                            width: max-content;
                        }
                    }                   

                    #todo-lists {
                        display: flex;
                        justify-content: space-around;
                        gap: 5em;

                        todo-list {
                            flex: 1;
                        }
                    }
                }
            </style>
        `;

        this.querySelector("#todo-open-modal-new-task")!.addEventListener("click", () => openModalWithElement(new ComponentTodoForm(null)))
        this.querySelector("#todo-open-modal-new-list")!.addEventListener("click", () => openModalWithElement(new ComponentListForm(null)))
    }
}

customElements.define("component-todo-page", ComponentTodoPage)

export const getTodoPage = () => document.querySelector("component-todo-page")! as ComponentTodoPage