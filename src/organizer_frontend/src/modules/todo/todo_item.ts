export class TodoItem extends HTMLElement {
     // properties
     #message: string = ""
     set message(message: string) {
         this.#message = message
         this.render()
    }

    // css properties
    readonly #width = "25vw"

    // constructor and  web component events
    constructor(message: string) {
        super()
        this.attachShadow({ mode: "open" })

        this.#message = message
    }

    connectedCallback() {
        this.render()
    }

    // behaviors
    save() {

    }

    // render
    render() {
        this.shadowRoot!.innerHTML = `
            <style>
                .todo-item { 
                    display: flex;
                    width: ${this.#width};

                    #toggle { margin-right: 0.6em; }
                    &.done { background-color: green; }
                }
            </style>

            <div class="todo-item">
                <input type="checkbox" id="toggle" />
                <h2>${this.#message}</h2>
                <button id="edit">edit</button>
            </div>
        `

        //
        // listeners
        //

        // toggle done status
        this.shadowRoot!.querySelector("#toggle")!.addEventListener("change", () => {
            this.shadowRoot!.querySelector(".todo-item")!.classList.toggle("done");
        });

        // display edit for this item
        this.shadowRoot!.querySelector("#edit")!.addEventListener("click", () => {
            this.renderEdit()
        })
    }

    renderEdit() {
        this.shadowRoot!.innerHTML = `
            <style>
                .todo-item { 
                    display: flex;
                    width: ${this.#width};
            </style>

            <div class="todo-item">
                <form>
                    <input id="edit-input" type="text" />
                    <button id="edit-save">save</button>
                </form>
            </div>
        `

        //
        // listeners
        //

        // save new message
        this.shadowRoot!.querySelector("#edit-save")!.addEventListener("click", (e) => {
            this.#message = (this.shadowRoot!.querySelector("#edit-input")! as HTMLInputElement).value
            this.render()
        })
    }
}

customElements.define("todo-item", TodoItem)