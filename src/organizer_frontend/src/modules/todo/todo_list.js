import { TodoItem } from "./todo_item.js";

class TodoList extends HTMLElement {
    // initialization
    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    connectedCallback() {
        this.render()
    }

    // properties
    #list = []

    set list(list) {
        this.#list = list
        this.render()
    }

    // behaviors
    addItem(item) {
        this.#list.push(item)
        this.shadowRoot.querySelector("#todo-list-items").appendChild(item)

        item.save()
    }

    clearItems() {
        this.#list = []
        this.shadowRoot.querySelector("#todo-list-items").innerHTML = ""
    }

    // render
    render() {
        this.shadowRoot.innerHTML = `
            <style>
                #todo-list { 
                    display: flex;
                    align-items: center;
                    flex-direction: column;
                    padding: 1em;

                    #todo-list-items {
                        display: flex;
                        flex-wrap: wrap;
                        gap: 1em;
                    }
                }
            </style>

            <div id="todo-list">
                <div>
                    <form id="add-item-form">
                        <input type="text" id="add-item-input" placeholder="what do you need to do ?" />
                        <button type="submit">add</button>
                    </form>
                    <button id="clear">clear</button>
                </div>
                
                <div id="todo-list-items">
                    ${this.#list.map(item => item)}
                </div>
            </div>
        `

        //
        // listeners
        //

        // add new item
        this.shadowRoot.querySelector("#add-item-form").addEventListener("submit", (e) => {
            e.preventDefault()
            const target = this.shadowRoot.querySelector("#add-item-input")
            this.addItem(new TodoItem(target.value))
            target.value = ""
        });

        // clear item list
        this.shadowRoot.querySelector("#clear").addEventListener("click", () => this.clearItems());
    }
}

customElements.define("todo-list", TodoList)