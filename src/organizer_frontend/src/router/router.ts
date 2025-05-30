export class Router extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: "open" });
    }
  
    connectedCallback() {
        window.addEventListener("popstate", () => this.render());
        this.render();
    }
  
    render() {
        const path = window.location.pathname;
        let content = "";
  
        if (path === "/articles") {
            content = "<articles-page></articles-page>";
        } else if (path === "/login") {
            content = "<login-page></login-page>";
        } else {
            content = "<h1>Home Page</h1>";
        }
    
        this.shadowRoot!.innerHTML = `
            <style>
                .container {
                    padding: 20px;
                }
            </style>
            <div class="container">${content}</div>
        `;
    }
}