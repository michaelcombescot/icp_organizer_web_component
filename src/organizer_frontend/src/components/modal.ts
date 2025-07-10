import { html, css, LitElement } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import { ComponentTodoForm } from '../modules/todo/components/component_todo_form';

@customElement('component-modal')
export class ComponentModal extends LitElement {
    @property({ type: Boolean }) opened : boolean = false
    show() { this.opened = true }
    hide() { this.opened = false }

    @property() content : LitElement | null = null
    public setContent(content: LitElement) {
        this.content = content;
        const container = this.shadowRoot!.querySelector('#modal-content');
        container?.replaceChildren(this.content);
    }

    static styles = css`
        #modal {
            #mask {
                position: fixed; top: 0; left: 0;
                width: 100%; height: 100%;
                z-index: 0;
                background-color: rgba(0, 0, 0, 0.5);
            }

            #modal-body {
                position: fixed; top: 50%; left: 50%;
                width: max-content;
                height: max-content;
                z-index: 1;
                transform: translate(-50%, -50%);
                border-radius: 10px;
                background-color: white;
                padding: 2em;

                #close-btn {
                    position: absolute; top: 10px; right: 10px;
                    width: 30px; height: 30px;
                    font-size: 24px;
                    background: transparent;
                    border: none;

                    &:hover {
                        transition: transform 0.2s ease-in-out;
                        cursor: pointer;
                        color: #222;
                        transform: scale(1.2);
                    }
                }
            }
        }
    `;

    render() {
        return html`
            <div id="modal" ?hidden="${!this.opened}">
                <div id="mask" @click="${this.hide}"></div>
                <div id="modal-body">
                    <button id="close-btn" @click="${this.hide}">X</button>
                    <div id="modal-content"></div>
                </div>
            </div>
        `;
    }
}

const openModal = (content: LitElement) => {
    const modal = document.querySelector("main-app")!.shadowRoot!.querySelector("component-modal") as ComponentModal;
    modal.setContent(content);
    modal.show();
}

const closeModal = () => {
    const modal = document.querySelector("main-app")!.shadowRoot!.querySelector("component-modal") as ComponentModal;
    modal.hide();
}

export { openModal, closeModal }