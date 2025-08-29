import { getPage } from "../../App.js";
import "../../modules/todo/components/component_todo_page.js";

export const routes = {
    home: "/",
}

export const navigateTo = (path: string) => {
    const page = getPage()
    let element: HTMLElement | HTMLDivElement 

    switch (path) {
        case routes.home:
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