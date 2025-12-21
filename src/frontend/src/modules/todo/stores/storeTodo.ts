import { group } from "console";
import { Identifier, Todo } from "../../../../../declarations/groupsBucket/groupsBucket.did";
import { getLoadingComponent } from "../../../components/loading";
import { Actors } from "../actors/actors";
import { getComponentTodo } from "../components/componentTodo";
import { getComponentTodoLists } from "../components/componentTodoLists";
import { StoreGlobal } from "./storeGlobal";

export const defTodoPriorities = ["low", "medium", "high"];

export class StoreTodos {
    static todos = new Map<bigint, Todo>();

    //
    // STORE METHODS
    //

    static createTodo(groupIdentifier: Identifier, todo: Todo) {
        getLoadingComponent().wrapAsync(async () => {
            let result = await Actors.createGroupsBucketActor(groupIdentifier.bucket).handlerCreateTodo(groupIdentifier.id, todo);
            if ("ok" in result) {
                todo.id = result.ok;
                this.todos.set(result.ok, todo);
                await getComponentTodoLists().render(); // reload lists of todos, easier to keep ordering that rather than guessing where to place it, should be ok performance wise for now
            } else {
                console.error(result.err);
            }
        })        
    }

    static updateTodo(groupIdentifier: Identifier, todo: Todo) {
        getLoadingComponent().wrapAsync(async () => {
            await Actors.createGroupsBucketActor(groupIdentifier.bucket).handlerUpdateTodo(groupIdentifier.id, todo);
            this.todos.set(todo.id, todo);
            await getComponentTodoLists().render(); // reload lists of todos, easier to keep ordering that do guess where to place it, should be ok performance wise for now
        })
    }

    static deleteTodo(groupIdentifier: Identifier, id: bigint) {
        getLoadingComponent().wrapAsync(async () => {
            await Actors.createGroupsBucketActor(groupIdentifier.bucket).handlerDeleteTodo(groupIdentifier.id, id);
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
