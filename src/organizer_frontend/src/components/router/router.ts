import "../../modules/todo/components/component_todo_page.js";
import "../../modules/todo/components/component_list_page.js";

export const routes = {
    home: "/",
    todoLists: "/todo/lists",
}

export const navigateTo = (path: string) => {
    const page = document.querySelector("#page")!
    let element: HTMLElement | HTMLDivElement 

    switch (path) {
        case routes.home:
            element = document.createElement("component-todo-page")
            break;
        case routes.todoLists:
            element = document.createElement("component-todo-lists-page")
            break;
        default:
            element = document.createElement("div")
            element.innerText = "404"
            break;
    }

    page.replaceChildren(element)
    history.pushState({}, "", path);
}