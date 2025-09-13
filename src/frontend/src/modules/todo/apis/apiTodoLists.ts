import { actor } from "../../../components/auth/auth";
import { TodoList } from "../../../../../declarations/backend_todos/backend_todos.did";

export let APITodoList = {
    async createList(list: TodoList) : Promise<{ ok: bigint } | { err: string[] }> {
        return actor.createTodoList(list);
    },

    async updateList(list: TodoList) {
        return actor.updateTodoList(list)
    },

    async removeList(id: bigint) {
        return actor.removeTodoList(id);
    },
}