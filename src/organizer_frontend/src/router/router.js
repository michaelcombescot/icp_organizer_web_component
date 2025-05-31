class AppRouter extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: "open" });
    }

    connectedCallback() {
        this.render();
        window.addEventListener("popstate", () => this.updateRoute());
        this.shadowRoot.querySelectorAll("a").forEach(link => {
            link.addEventListener("click", (event) => this.navigate(event));
        });
    }

    render() {
        this.shadowRoot.innerHTML = `
            <nav>
                <a href="/" data-route="/">Home</a>
                <a href="/about" data-route="/about">About</a>
                <a href="/contact" data-route="/contact">Contact</a>
            </nav>
            <div id="content"></div>
        `;
        this.updateRoute();
    }

    navigate(event) {
        event.preventDefault();
        const path = event.target.getAttribute("data-route");
        history.pushState({}, "", path);
        this.updateRoute();
    }

    updateRoute() {
        const path = window.location.pathname;
        const content = this.shadowRoot.querySelector("#content");

        switch (path) {
            case "/about":
                content.innerHTML = "<h2>About Page</h2>";
                break;
            case "/contact":
                content.innerHTML = "<h2>Contact Page</h2>";
                break;
            default:
                content.innerHTML = "<h2>Home Page</h2>";
        }
    }
}

customElements.define("app-router", AppRouter);