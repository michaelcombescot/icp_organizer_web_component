class ComponentContact extends HTMLElement {
    constructor() {
        super();
    }

    connectedCallback() {
        this.#render();
    }

    #render() {
        this.innerHTML = /*html*/`
            <h1>Contact</h1>
            <div>TODO</div>
        `;
    }
}

customElements.define("component-contact", ComponentContact);