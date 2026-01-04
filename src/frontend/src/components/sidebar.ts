import { i18n } from "../i18n/i18n"
import { routes } from "./router/router"

export class ComponentSidebar extends HTMLElement {
    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    connectedCallback() {
        this.render()
    }

    show() {
        this.shadowRoot!.querySelector("nav")!.classList.remove("hidden")
        this.shadowRoot!.querySelector("#sidebar-open-icon")!.classList.add("hidden")
    }

    hide() {
        this.shadowRoot!.querySelector("nav")!.classList.add("hidden")
        this.shadowRoot!.querySelector("#sidebar-open-icon")!.classList.remove("hidden")
    }

    render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <img id="sidebar-open-icon" src="/menu-hamburger.svg" alt="OPEN MENU" /></div>
            <nav class="hidden">
                <img id="close-button" src="./close.svg">

                <h3 id="title">${i18n.headerTitle}</h1>

                <div id="pages-links">
                    <component-router-link href="${routes.home}" text="${i18n.headerHome}"></component-router-link>
                </div>
            </nav>

            <style>
                #sidebar-open-icon {
                    position: fixed;
                    top: 0.5em; left: 0.5em;
                    width: 1.5em;
                    cursor: pointer;
                }

                #close-button {
                    width: 1em;
                    position: absolute; top: 0.5em; right: 0.5em;
                    cursor: pointer;
                }

                nav {
                    position: fixed;
                    left: 0; top: 0;
                    width: 20%; height: 100%;
                    padding-left: 0.5em; 
                    background-color: #F2F0EF;

                }

                .hidden {
                    display: none;
                }
            </style>
        `
    
        this.shadowRoot!.querySelector("#sidebar-open-icon")!.addEventListener("click", () => this.show())
        this.shadowRoot!.querySelector("#close-button")!.addEventListener("click", () => this.hide())
    }
}

customElements.define("component-sidebar", ComponentSidebar)