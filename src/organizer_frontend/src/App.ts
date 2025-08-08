import './modules/todo/components/component_todo_page'
import './components/modal'
import './components/router/router_link'
import { i18n } from './i18n/i18n'
import { navigateTo, routes } from './components/router/router'
import { login, logout, whoami, isAuthenticated } from './components/auth/auth'
// import { logo } from '../assets/icp-logo.svg'

class App extends HTMLElement {
    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    connectedCallback() {
        this.#render()
        setTimeout(() => { navigateTo(window.location.pathname) }, 0) // element is not fully rendered without the timeout, and we cannot find the #page for the router
    }

    #render() {
        this.shadowRoot!.innerHTML = /*html*/`       
            <div id="main-app">
                <header>
                    <div id="pages-links">
                        <component-router-link href="${routes.home}" text="${i18n.headerHome}"></component-router-link>
                    </div>

                    <h1>${i18n.headerTitle}</h1>

                    <div id="auth-links">
                        ${
                            isAuthenticated ?
                            /*html*/`
                                <a href="#" id="log-out-link">Log Out</a>
                            `
                            : /*html*/`
                                <a href="#" id="login-button">
                                    <img src="/icp-logo.svg" alt="icp-logo" />
                                </a>
                            `
                        }                        
                    </div>
                </header>

                <div id="page"></div>

                <component-modal></component-modal>
            </div>

            <style>
                #main-app {
                    header {
                        padding: 0 1em 0 1em;
                        height: 10vh;
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        gap: 2em;

                        #auth-links {
                            #login-button {
                                img {
                                    width: 4em;
                                }
                            }
                        }
                    }

                    #page {
                        padding: 1em;
                    }
                }
            </style>
        `

        this.shadowRoot!.querySelector("#whoami-button")?.addEventListener("click", () => whoami().then(r => console.log(r)))
        this.shadowRoot!.querySelector("#login-button")?.addEventListener("click", () => login())
        this.shadowRoot!.querySelector("#log-out-link")?.addEventListener("click", () => logout())
    }
}

customElements.define('main-app', App)

export const getMainApp = () => document.querySelector("main-app")!
export const getPage = () => getMainApp().shadowRoot!.querySelector("#page")!