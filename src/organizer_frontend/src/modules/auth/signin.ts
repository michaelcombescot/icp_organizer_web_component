class ComponentSignIn extends HTMLElement {
    constructor() {
        super()
    }

    connectedCallback() {
        this.#render()
    }

    #render() {
        this.innerHTML = /*html*/`
            <div id="signin">
                <h1>SIGNIN TODO</h1>
            </div>
        `
    }
}

customElements.define("component-sign-in", ComponentSignIn)