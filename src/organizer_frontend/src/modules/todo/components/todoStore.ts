import { defineStore } from 'pinia'
import { Todo } from '../../../../../declarations/organizer_backend/organizer_backend.did'
import { actor } from '../../../components/auth/auth'

export const useTodoStore = defineStore('todo', {
    state: () => ({
        todos: [] as Todo[],
    }),

    actions: {
        async apiGetTodos(): Promise<Todo[]> {
            const todos = await actor.getTodos()
            return todos
        }
    }
})