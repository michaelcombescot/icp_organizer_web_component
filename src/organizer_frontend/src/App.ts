import './modules/todo/components/component_todo_page'
import './components/modal'

class App extends HTMLElement {
    constructor() {
        super()
    }

    connectedCallback() {
        this.#render()
    }

    #render() { 
        this.innerHTML = /*html*/`       
            <div id="main-app">    
                <component-todo-page></component-todo-page>

                <component-modal></component-modal>
            </div>

            <style>
                #main-app {
                    padding: 1em;
                    font-size: 1rem;
                }
            </style>
        `
    }
}

customElements.define('main-app', App)