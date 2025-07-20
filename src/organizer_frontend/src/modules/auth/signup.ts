class ComponentSignUp extends HTMLElement {
    constructor() {
        super()
    }

    connectedCallback() {
        this.#render()
    }

    #render() {
        this.innerHTML = /*html*/`
            <div id="signup">
                <h1>SIGNUP TODO</h1>
            </div>
        `
    }
}

customElements.define("component-sign-up", ComponentSignUp)