// to use it it needs 2 attributes popover-id and shadow-id, example:
// <button popovertarget="new-task">New task</button>
// <component-modal popover-id="new-task" shadow-id="new-task-shadow">
//   <div>CONTENT</div>
// </component-modal>
//

class Modal extends HTMLElement {
    //
    // ATTRIBUTES
    //

    #popoverID
    #shadowID
    #height
    #width

    //
    // INITIALIZATION
    //

    constructor() {
        super();
        this.attachShadow({ mode: "open" });
        this.#popoverID = this.getAttribute("popover-id");
        this.#shadowID = this.getAttribute("shadow-id");
        this.#height = this.getAttribute("height") || "80vh";
        this.#width = this.getAttribute("width") || "80vw";
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
        const shadow = document.querySelector(`#${this.#shadowID}`) as HTMLElement

        shadow.shadowRoot!.querySelector(`[popovertarget="${this.#popoverID}"]`)!.addEventListener("click", () => this.showPopover())
    }

    handleHidePopover() {
        this.shadowRoot!.querySelector("#close-btn")!.addEventListener("click", () => this.hidePopover())
    }

    //
    // BEHAVIOURS
    //

    showPopover() {
        (this.shadowRoot!.querySelector(`#${this.#popoverID}`) as HTMLDialogElement)!.showPopover()
    }

    hidePopover() {
        (this.shadowRoot!.querySelector(`#${this.#popoverID}`) as HTMLDialogElement)!.hidePopover()
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

                #content {
                    position: fixed;
                    z-index: 1;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    border-radius: 10px;
                    background-color: white;
                    padding: 20px;
                    width: ${this.#width};
                    height: ${this.#height};
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