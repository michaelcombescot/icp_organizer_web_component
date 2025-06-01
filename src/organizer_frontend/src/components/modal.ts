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
                    position: fixed;
                    z-index: 0;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background-color: rgba(0, 0, 0, 0.5);
                }

                #modal-body {
                    position: fixed;
                    z-index: 1;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    border-radius: 10px;
                    background-color: white;
                    padding: 20px;
                    width: 80vw;
                    height: 70vh;
                }
            </style>

            
            <div id="modal" popover="manual">
                <div id="mask"></div>
                <div id=modal-body>
                    <slot></slot>
                    <button id="close-btn">Close</button>
                </div>
            </div>
        `

        this.shadowRoot!.querySelector("#close-btn")!.addEventListener("click", () => {
            this.hide()
        })
    }
}

customElements.define("component-modal", ModalElement);