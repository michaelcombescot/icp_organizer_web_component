import { Todo } from "../../../../../declarations/backend_todos/backend_todos.did";
import { getLoadingComponent } from "../../../components/loading";
import { APITodo } from "../apis/apiTodos";
import { APIUser } from "../apis/apiUsers";
import { getComponentTodo } from "../components/componentTodo";
import { getComponentTodoLists } from "../components/componentTodoLists";
import { StoreGlobal } from "./storeGlobal";

export const defTodoPriorities = ["low", "medium", "high"];

export class StoreTodos {
    static todos = new Map<bigint, Todo>();

    //
    // STORE METHODS
    //

    static createTodo(todo: Todo) {
        getLoadingComponent().wrapAsync(async () => {
            let result = await APITodo.createTodo(todo);
            if ("ok" in result) {
                todo.id = result.ok;
                this.todos.set(result.ok, todo);
                await getComponentTodoLists().render(); // reload lists of todos, easier to keep ordering that do guess where to place it, should be ok performance wise for now
            } else {
                console.error(result.err);
            }
        })        
    }

    static updateTodo(todo: Todo) {
        getLoadingComponent().wrapAsync(async () => {
            await APITodo.updateTodo(todo);
            this.todos.set(todo.id, todo);
            await getComponentTodoLists().render(); // reload lists of todos, easier to keep ordering that do guess where to place it, should be ok performance wise for now
        })
    }

    static deleteTodo(id: bigint) {
        getLoadingComponent().wrapAsync(async () => {
            await APITodo.removeTodo(id);
            this.todos.delete(id);
            await getComponentTodo(id).remove();
        })
    }

    //
    // HELPERS
    //

    static getPriorityTodosOrderedIds(): bigint[] {
        let currentSelectedListId = StoreGlobal.currentSelectedListId

        return [...this.todos]
            .filter(([id, todo]) => todo.scheduledDate.length === 0 && (!currentSelectedListId || todo.todoListId[0] === currentSelectedListId))
            .map(([_, todo]) => todo)
            .sort((a, b) => {
                const aLevel = defTodoPriorities.indexOf(Object.keys(a.priority)[0] as string);
                const bLevel = defTodoPriorities.indexOf(Object.keys(b.priority)[0] as string);
                return bLevel - aLevel;
            })
            .map((todo) => todo.id)
    }


    static getScheduledTodosOrderedIds(): bigint[] {
            let currentSelectedListId = StoreGlobal.currentSelectedListId

            return [...this.todos]
                .filter(([id, todo]) => todo.scheduledDate.length != 0 && (!currentSelectedListId || todo.todoListId[0] === currentSelectedListId) )
                .map(([id, todo]) => todo)
                .sort((a, b) => Number(a.scheduledDate) - Number(b.scheduledDate))
                .map((todo) => todo.id)
    }
}
