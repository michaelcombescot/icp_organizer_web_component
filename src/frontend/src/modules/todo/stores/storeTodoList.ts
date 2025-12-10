import { TodoList } from "../../../../../declarations/backend_todos/backend_todos.did";
import { getLoadingComponent } from "../../../components/loading";
import { APITodoList } from "../apis/apiTodoLists";
import { getListsCards } from "../components/componentListCards";
import { getTodoPage } from "../components/componentTodoPage";
import { StoreTodos } from "./storeTodo";

export class StoreTodoLists {
    static todoLists: Map<bigint, TodoList> = new Map<bigint, TodoList>();

    static createTodoList(todoList: TodoList) {
        getLoadingComponent().wrapAsync(async () => {
            // const result = await APITodoList.createList(todoList);
            // if ("ok" in result) {
            //     todoList.id = result.ok;
            //     this.todoLists.set(result.ok, todoList);

            //     getListsCards().render();
            // }
        })
    }

    static updateTodoList(todoList: TodoList) {
        getLoadingComponent().wrapAsync(async () => {
            // await APITodoList.updateList(todoList);
            // this.todoLists.set(todoList.id, todoList);

            // getTodoPage().render();
        })
    }

    static deleteTodoList(id: bigint) {
        getLoadingComponent().wrapAsync(async () => {
            // await APITodoList.removeList(id);
            // this.todoLists.delete(id);

            // StoreTodos.todos.forEach((todo) => {
            //     if (todo.todoListId[0] === id) {
            //         StoreTodos.todos.delete(todo.id)
            //     }
            // })

            // getTodoPage().render();
        })
    }
}

