import { TodoList } from "../../../../../declarations/backend_todos/backend_todos.did";

export class StoreTodoLists {
    static todoLists: Map<bigint, TodoList> = new Map<bigint, TodoList>();

    static createTodoList(todoList: TodoList) {
        this.todoLists.set(todoList.id, todoList);
    }

    static updateTodoList(todoList: TodoList) {
        this.todoLists.set(todoList.id, todoList);
    }

    static deleteTodoList(id: bigint) {
        this.todoLists.delete(id);
    }
}

