import { getMainApp } from "../App";
import { borderRadius } from "../css/css";

class ComponentModal extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: "open" });
    }

    connectedCallback() {
        this.render();

        this.shadowRoot!.querySelector('#close-btn')!.addEventListener('click', () => this.hide());
        this.shadowRoot!.querySelector('#mask')!.addEventListener('click', () => this.hide());
    }

    show(content: HTMLElement) {
        this.shadowRoot!.querySelector('#modal-content')!.replaceChildren(content)
        this.shadowRoot!.querySelector('#modal')!.classList.remove("hidden")
    }

    hide() { this.shadowRoot!.querySelector('#modal')!.classList.add("hidden") }

    render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <div id="modal" class="hidden">
                <div id="mask"></div>
                <div id="modal-body">
                    <button id="close-btn">X</button>
                    <div id="modal-content">
                        <p>Missing html element in the modal, should open it with openModalWithElement</p>
                    </div>
                </div>
            </div>

            <style>
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
                        max-width: 85vw;
                        height: max-content;
                        z-index: 1;
                        transform: translate(-50%, -50%);
                        background-color: white;
                        border-radius: ${borderRadius};
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

                    &.hidden {
                        display: none;
                    }
                }
            </style>
        `;
    }
}

customElements.define('component-modal', ComponentModal);

const openModalWithElement = (content: HTMLElement) => {
    const modal = getMainApp().shadowRoot!.querySelector("component-modal") as ComponentModal;
    modal.show(content);
}

const closeModal = () => {
    const modal = getMainApp().shadowRoot!.querySelector("component-modal") as ComponentModal;
    modal.hide();
}

export { openModalWithElement, closeModal }