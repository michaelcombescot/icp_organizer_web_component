import { Todo, TodoList, TodoPriority } from "../../../../../declarations/backend_todos/backend_todos.did";
import { actor } from "../../../components/auth/auth";

export let APITodo = {
    async apiGetTodos() {
        return actor.getuserData()
    },

    async apiCreateTodo(todo: Todo): Promise<{ ok: bigint } | { err: string[] }> {
        return actor.createTodo(todo)
    },

    async apiUpdateTodo(todo: Todo) {
        return actor.updateTodo(todo)
    },

    async apiDeleteTodo(id: bigint) {
        return actor.removeTodo(id)
    },
}