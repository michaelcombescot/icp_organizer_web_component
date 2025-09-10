import { actor } from "../../../components/auth/auth";
import { TodoList } from "../../../../../declarations/backend_todos/backend_todos.did";

export let APITodoList = {
    async apiCreateList(list: TodoList) {
        try {
            actor.createTodoList(list);
        } catch (error) {
            console.error("Failed to add todo:", error);
        }
    },

    async apiUpdateList(list: TodoList) {
        try {
            await actor.updateTodoList(list);
        } catch (error) {
            console.error("Failed to update todo:", error);
        }
    },

    async apiDeleteList(id: bigint) {
        try {
            await actor.removeTodoList(id);
        } catch (error) {
            console.error("Failed to delete todo:", error);
        }
    },
}