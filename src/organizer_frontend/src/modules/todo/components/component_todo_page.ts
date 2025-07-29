import "./component_todo_list";
import { ComponentTodoForm } from "./component_todo_form";
import { openModalWithElement } from "../../../components/modal";
import { i18n } from "../../../i18n/i18n";
import { todoStore } from "../models/todo_store";
import { listStore } from "../models/list_store";
import { ComponentListForm } from "./component_list_form";
import { Todo, sortByPriority, sortByScheduledDate } from "../models/todo";
import { ComponentTodoList } from "./component_todo_list";

class ComponentTodoPage extends HTMLElement {
    #currentListUUID: string
    set currentListUUID(listUUID: string) {
        this.#currentListUUID = listUUID        
        this.update()
    }

    constructor() {
        super()
        this.#currentListUUID = ""
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
            if ( this.#currentListUUID != "" && this.#currentListUUID !== todo.listUUID ) {
                continue
            }

            if (!todo.scheduledDate) {
                priorityTodos.push(todo)
            } else {
                scheduledTodos.push(todo)
            }
        }

        (this.querySelector("#todo-list-priority")! as ComponentTodoList).list = sortByPriority(priorityTodos);
        (this.querySelector("#todo-list-scheduled")! as ComponentTodoList).list = sortByScheduledDate(scheduledTodos);
    }

    async updateListSelector() {
        const lists = await listStore.getLists()
        const select = this.querySelector("#todo-select-list")! as HTMLSelectElement
        select.innerHTML = ""

        select.append( new Option("", "") )
        lists.forEach( element => select.append( new Option(element.name, element.uuid) ) );
    }

    #render() {
        this.innerHTML = /*html*/`
            <div id="todo-page">
                <div id="todo-page-buttons">
                    <button id="todo-open-modal-new-task">${ i18n.todoCreateNewButton }</button>
                    <button id="todo-open-modal-new-list">${ i18n.todoListCreateButton }</button>
                </div>

                <select id="todo-select-list" name="todo-select-list">
                </select>

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
                    
                    #todo-select-list {
                        width: max-content;
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

        this.querySelector("#todo-open-modal-new-task")!.addEventListener("click", () => openModalWithElement(new ComponentTodoForm(null, this.#currentListUUID)))
        this.querySelector("#todo-open-modal-new-list")!.addEventListener("click", () => openModalWithElement(new ComponentListForm(null)))
        this.querySelector("#todo-select-list")!.addEventListener("change", (e) => this.currentListUUID = (e.target as HTMLSelectElement).value)

        this.updateListSelector()
    }
}

customElements.define("component-todo-page", ComponentTodoPage)

export const getTodoPage = () => document.querySelector("component-todo-page")! as ComponentTodoPage