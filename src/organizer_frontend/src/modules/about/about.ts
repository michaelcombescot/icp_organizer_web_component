class ComponentAbout extends HTMLElement {
    constructor () {
        super();
    }

    connectedCallback() {
        this.#render();
    }

    #render() {
        this.innerHTML = /*html*/`
            <h1>About</h1>
            <p>TODO</p>
        `
    }
}

customElements.define("component-about", ComponentAbout)