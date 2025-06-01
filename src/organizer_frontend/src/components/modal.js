// to use it:
// <button popovertarget="new-task">New task</button>
// <component-modal popover-id="new-task">
//   <div>CONTENT</div>
// </component-modal>
//

class Modal extends HTMLElement {
    //
    // ATTRIBUTES
    //

    #popoverID

    //
    // INITIALIZATION
    //

    constructor() {
        super();
        this.attachShadow({ mode: "open" });
        this.#popoverID = this.getAttribute("popover-id");
    }

    connectedCallback() {
        this.render()

        this.handleShowPopover()
        this.handleHidePopover()
    }

    //
    // TRIGGERS
    //

    handleShowPopover() {
        document.querySelector(`[popovertarget="${this.#popoverID}"]`).addEventListener("click", () => this.showPopover())
    }

    handleHidePopover() {
        this.shadowRoot.querySelector("#close-btn").addEventListener("click", () => this.hidePopover())
    }

    //
    // BEHAVIOURS
    //

    showPopover() {
        this.shadowRoot.querySelector(`#${this.#popoverID}`).showPopover()
    }

    hidePopover() {
        this.shadowRoot.querySelector(`#${this.#popoverID}`).hidePopover()
    }

    //
    // RENDERER
    //

    render() {
        this.shadowRoot.innerHTML = `
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

                #content {
                    position: fixed;
                    z-index: 1;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    border-radius: 10px;
                    background-color: white;
                    padding: 20px;
                }
            </style>

            
            <div id="${this.#popoverID}" popover="manual">
                <div id="mask"></div>
                <div id="content">
                    <slot></slot>
                    <button id="close-btn">Close</button>
                </div>
            </div>
        `
    }
}

customElements.define("component-modal", Modal);