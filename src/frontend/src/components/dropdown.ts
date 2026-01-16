import { StoreGroups } from "../modules/todo/stores/storeGroups"
import { StoreUser } from "../modules/todo/stores/storeUser"

export class ComponentDropdown extends HTMLElement {
    #label = "no label"
    #elements: HTMLElement[] = []
    #isOpened = false

    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    connectedCallback() {
        this.#label = this.getAttribute("label")!

        this.render()
    }

    setList(elements: HTMLElement[]) {
        this.#elements = elements
        this.render()
    }

    showContent() {
        this.shadowRoot!.querySelector("#dropdown-content")!.classList.remove("hidden")
    }

    hideContent() {
        this.shadowRoot!.querySelector("#dropdown-content")!.classList.add("hidden")
    }

    render() {
        const groups: String[] = []
        StoreGroups.groupsData.forEach((v,k) => groups.push(v.name))


        this.shadowRoot!.innerHTML = /*html*/`
            <div id="dropdown">
                <label id="dropdown-label">${this.#label} <img id="dropdown-icon" src="./dropdown.svg" /><label>
                <div id="dropdown-content" class="hidden">
                    ${ groups }
                </div>
            </div>

            <style>
                #dropdown {
                    position: relative;
                    display: flex; flex-direction: column;

                    #dropdown-label {
                        display: flex; align-items: center;
                        width: 100%; height: 2em;
                    }

                    #dropdown-content {
                        position: absolute; top: 2em; left: 0;
                        width: 20em;
                        
                        &.hidden {
                            display: none;
                        }
                    }
                }

                #dropdown-icon {
                    width: 2em;
                }
            </style>
        `

        this.shadowRoot!.querySelector("#dropdown-label")!.addEventListener("click", () => {
            this.showContent()

            let onOutsidePointerDown = (e: PointerEvent) => {
                const dropdown = this.shadowRoot!.querySelector("#dropdown")!;

                if (!e.composedPath().includes(dropdown)) {
                    this.hideContent();
                    document.removeEventListener("pointerdown", onOutsidePointerDown);
                }
            }

            document.addEventListener("pointerdown", onOutsidePointerDown);
        })
    }
}

customElements.define("component-dropdown", ComponentDropdown)