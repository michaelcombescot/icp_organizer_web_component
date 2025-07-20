import './modules/todo/components/component_todo_page'
import './components/modal'
import './components/router/router_link'
import { i18n } from './i18n/i18n'
import { navigateTo, routes } from './components/router/router'

class App extends HTMLElement {
    constructor() {
        super()
    }

    connectedCallback() {
        this.#render()

        navigateTo(window.location.pathname);
    }

    #render() { 
        this.innerHTML = /*html*/`       
            <div id="main-app">
                <header>
                    <div id="pages-links">
                        <component-router-link href="${routes.home}" text="${i18n.headerHome}"></component-router-link>
                        <component-router-link href="${routes.about}" text="${i18n.headerAbout}"></component-router-link>
                        <component-router-link href="${routes.contact}" text="${i18n.headerContact}"></component-router-link>
                    </div>

                    <h1>${i18n.headerTitle}</h1>

                    <div id="auth-links">
                        <component-router-link href="${routes.signUp}" text="Sign up"></component-router-link>
                        <component-router-link href="${routes.signIn}" text="Sign in"></component-router-link>
                        <component-router-link href="${routes.logOut}" text="Log Out"></component-router-link>
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
                        background-color: rgb(3, 252, 194, 0.1);
                    }

                    #page {
                        padding: 1em;
                    }
                }
            </style>
        `
    }
}

customElements.define('main-app', App)