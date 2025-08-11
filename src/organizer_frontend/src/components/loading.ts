import { getMainApp } from "../App";
import { maskColor } from "../css/css";

export class ComponentLoading extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: "open" });
    }

    connectedCallback() {
        this.#render()
    }

    show() { this.shadowRoot!.querySelector("#loading")!.classList.remove("hidden") }
    hide() { this.shadowRoot!.querySelector("#loading")!.classList.add("hidden") }

    async wrapAsync(func: () => Promise<void>) {
        this.show();
        await func();
        this.hide();
    }

    #render() {
        this.shadowRoot!.innerHTML = /*html*/`
            <div id="loading" class="hidden">
                <span id="loader"></span>
            </div>

            <style>
                #loading {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100vw;
                    height: 100vh;
                    background-color: ${maskColor};
                    z-index: 1;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                
                    #loader {
                        width: 48px;
                        height: 48px;
                        border-radius: 50%;
                        display: inline-block;
                        border-top: 4px solid green;
                        border-right: 4px solid transparent;
                        box-sizing: border-box;
                        animation: rotation 1s linear infinite;
                    
                        &::after {
                            content: '';  
                            box-sizing: border-box;
                            position: absolute;
                            left: 0;
                            top: 0;
                            width: 48px;
                            height: 48px;
                            border-radius: 50%;
                            border-left: 4px solid blue;
                            border-bottom: 4px solid transparent;
                            animation: rotation 0.5s linear infinite reverse;
                        }
                    }

                    &.hidden {
                        display: none;
                    }
                }

                @keyframes rotation {
                    0% {
                        transform: rotate(0deg);
                    }
                    100% {
                        transform: rotate(360deg);
                    }
                } 
            </style>
        `
    }
}

customElements.define("component-loading", ComponentLoading);

export const getLoadingComponent = () => getMainApp().shadowRoot!.querySelector("component-loading")! as ComponentLoading