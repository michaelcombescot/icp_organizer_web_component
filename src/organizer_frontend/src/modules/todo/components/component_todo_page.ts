import "./component_todo_list";
import { ComponentTodoForm } from "./component_todo_form";
import { openModal, ComponentModal } from "../../../components/modal";
import { i18n } from "../../../i18n/i18n";
import { html, css, LitElement } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement("component-todo-page")
class ComponentTodoPage extends LitElement {
    static styles = css`
        #todo-page {
            display: flex;
            flex-direction: column;
            gap: 2em;

            #todo-open-modal-new-task {
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
    `

    render() {
        return html`
            <div id="todo-page">
                <button id="todo-open-modal-new-task" @click=${() => openModal(ComponentTodoForm.create(null))}>${ i18n.todoCreateNewButton }</button>

                <div id="todo-lists">
                    <component-todo-list id="todo-list-priority" listType="priority"></component-todo-list>
                    <component-todo-list id="todo-list-scheduled" listType="scheduled"></component-todo-list>
                </div>
            </div>
        `;
    }
}