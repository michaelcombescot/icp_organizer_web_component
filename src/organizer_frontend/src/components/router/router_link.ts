import { navigateTo } from "./router"

class RouterLinkComponent extends HTMLElement {
    #href: string
    #text: string

    constructor() {
        super();
        this.attachShadow({ mode: "open" });

        this.#href = this.getAttribute("href")!
        this.#text = this.getAttribute("text")!

        if (!this.#href) { throw new Error("href attribute is required") }
        if (!this.#text) { throw new Error("text attribute is required") }
    }

    connectedCallback() {
        this.#render();
        this.shadowRoot!.querySelector("a")!.addEventListener("click", (e) => {
            e.preventDefault()
            navigateTo(this.#href)
        })
    }

    #render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <a href="${this.#href}">${this.#text}</a>
        `;
    }
}

customElements.define("component-router-link", RouterLinkComponent);