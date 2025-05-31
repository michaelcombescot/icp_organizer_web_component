class Modal extends HTMLElement {
    #content

    constructor() {
        super();
        this.attachShadow({ mode: "open" });
        this.popoverID = this.getAttribute("popover-id");
    }

    connectedCallback() {
        this.render()

        document.querySelector(`[popovertarget="${this.popoverID}"]`).addEventListener("click", () => this.showPopover());

        this.shadowRoot.querySelector("#close-btn").addEventListener("click", () => {
            this.shadowRoot.querySelector(`#${this.popoverID}`).hidePopover();
        });
    }

    showPopover() {
        const popover = this.shadowRoot.querySelector(`#${this.popoverID}`);
        if (popover) {
            popover.showPopover();
        } else {
            console.error("Popover element not found.");
        }
    }

    hidePopover() {
        const popover = this.shadowRoot.querySelector(`#${this.popoverID}`);
        if (popover) {
            popover.hidePopover();
        }
    }

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

            
            <div id="${this.popoverID}" popover="manual">
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