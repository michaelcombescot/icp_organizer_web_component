import './components/modal'
import './components/router/router_link'
import './components/sidebar'
import { i18n } from './i18n/i18n'
import { navigateTo, routes } from './components/router/router'
import { login, logout, isAuthenticated } from './auth/auth'
// import { logo } from '../assets/icp-logo.svg'

class App extends HTMLElement {
    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    connectedCallback() {
        this.render()
        setTimeout(() => { navigateTo(window.location.pathname) }, 0) // element is not fully rendered without the timeout, and we cannot find the #page for the router
    }

    render() {
        this.shadowRoot!.innerHTML = /*html*/`       
            <div id="main-app">
                <header>
                    <div id="auth-links">
                        ${
                            isAuthenticated ?
                            /*html*/`
                                <a href="#" id="log-out-link">${i18n.headerLogOut}</a>
                            `
                            : /*html*/`
                                <a href="#" id="login-button" title="login">
                                    <img src="/icp-logo.svg" alt="icp-logo" />
                                </a>
                            `
                        }                        
                    </div>
                </header>

                <div id="page"></div>

                <component-modal></component-modal>
                <component-sidebar></component-sidebar>
                <component-loading></component-loading>
            </div>

            <style>
                #main-app {
                    height: 100vh;
                    width: 100vw;

                    header {
                        position: relative;
                        height: 7vh;
                    }

                    #auth-links {
                        position: absolute; top: 0.5em; right: 1em;

                        #login-button {
                            img {
                                width: 2em;
                            }
                        }

                        #log-out-link {
                            font-size: 0.8em;
                        }
                    }

                    #page {
                        padding: 0 1em 0 1em;
                        height: 93vh;
                        width: 100%;
                        box-sizing: border-box;
                    }
                }
            </style>
        `

        this.shadowRoot!.querySelector("#login-button")?.addEventListener("click", () => login())
        this.shadowRoot!.querySelector("#log-out-link")?.addEventListener("click", () => logout())
    }
}

customElements.define('main-app', App)

export const getMainApp = () => document.querySelector("main-app")! as App
export const getPage = () => getMainApp().shadowRoot!.querySelector("#page")!