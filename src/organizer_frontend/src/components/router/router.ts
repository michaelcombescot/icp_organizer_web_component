import "../../modules/todo/components/component_todo_page.ts";
import "../../modules/about/about.ts";
import "../../modules/contact/contact.ts";
import "../../modules/auth/signin.ts";
import "../../modules/auth/signup.ts";

export const routes = {
    home: "/",
    about: "/about",
    contact: "/contact",
    signIn: "/signin",
    signUp: "/signup",
    todo: "/todo",
}

export const navigateTo = (path: string) => {
    const page = document.querySelector("#page")!
    let element: HTMLElement | HTMLDivElement 

    switch (path) {
        case routes.home:
            element = document.createElement("component-todo-page")
            break;
        case routes.about:
            element = document.createElement("component-about")
            break;
        case routes.contact:
            element = document.createElement("component-contact")
            break;
        case routes.signIn:
            element = document.createElement("component-sign-in")
            break;
        case routes.signUp:
            element = document.createElement("component-sign-up")
            break;
        case routes.todo:
            element = document.createElement("component-todo-page")
            break;
        default:
            element = document.createElement("div")
            element.innerText = "404"
            break;
    }

    page.replaceChildren(element)
    history.pushState({}, "", path);
}