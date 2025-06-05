// to use it it needs 2 attributes popover-id and shadow-id, example:
// <button popovertarget="new-task">New task</button>
// <component-modal popover-id="new-task" shadow-id="new-task-shadow">
//   <div>CONTENT</div>
// </component-modal>
//

class ModalElement extends HTMLElement {

    //
    // INITIALIZATION
    //

    constructor() {
        super();
        this.attachShadow({ mode: "open" });
    }

    connectedCallback() {
        this.render()
    }

    //
    // BEHAVIOURS
    //

    show() {
        (this.shadowRoot!.querySelector(`#modal`) as HTMLDialogElement)!.showPopover()
    }

    hide() {
        (this.shadowRoot!.querySelector(`#modal`) as HTMLDialogElement)!.hidePopover()
    }

    fillWith (content: HTMLElement) {
        this.replaceChildren(content);
    }

    //
    // RENDERER
    //

    render() {
        this.shadowRoot!.innerHTML = `
            <style>
                #mask {
                    position: fixed; top: 0; left: 0;
                    width: 100%; height: 100%;
                    z-index: 0;
                    background-color: rgba(0, 0, 0, 0.5);
                }

                #modal-body {
                    position: fixed; top: 50%; left: 50%;
                    width: max-content; height: 70vh;
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
            </style>

            
            <div id="modal" popover="manual" opened>
                <div id="mask"></div>
                <div id=modal-body>
                    <button id="close-btn">X</button>
                    <slot></slot>
                    
                </div>
            </div>
        `

        this.shadowRoot!.querySelector("#close-btn")!.addEventListener("click", () => {
            this.hide()
        })
    }
}

customElements.define("component-modal", ModalElement);