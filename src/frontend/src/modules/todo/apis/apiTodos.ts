import { Todo, TodoList, TodoPriority } from "../../../../../declarations/backend_todos/backend_todos.did";
import { actor } from "../../../components/auth/auth";

export let APITodo = {
    async createTodo(todo: Todo): Promise<{ ok: bigint } | { err: string[] }> {
        return actor.createTodo(todo)
    },

    async updateTodo(todo: Todo) {
        return actor.updateTodo(todo)
    },

    async removeTodo(id: bigint) {
        return actor.removeTodo(id)
    },
}