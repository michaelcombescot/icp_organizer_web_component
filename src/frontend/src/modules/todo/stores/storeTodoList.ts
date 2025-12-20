import { Identifier, TodoList } from "../../../../../declarations/organizerGroupsBucket/organizerGroupsBucket.did";
import { getLoadingComponent } from "../../../components/loading";
import { Actors } from "../actors/actors";
import { getListsCards } from "../components/componentListCards";
import { getTodoPage } from "../components/componentTodoPage";
import { StoreTodos } from "./storeTodo";

export class StoreTodoLists {
    static todoLists: Map<bigint, TodoList> = new Map<bigint, TodoList>();

    static createTodoList(groupIdentifier: Identifier, todoList: TodoList) {
        getLoadingComponent().wrapAsync(async () => {
            const result = await Actors.createGroupsBucketActor(groupIdentifier.bucket).handlerCreateTodosList(groupIdentifier.id, todoList);
            if ("ok" in result) {
                todoList.id = result.ok;
                this.todoLists.set(result.ok, todoList);

                getListsCards().render();
            }
        })
    }

    static updateTodoList(groupIdentifier: Identifier, todoList: TodoList) {
        getLoadingComponent().wrapAsync(async () => {
            await Actors.createGroupsBucketActor(groupIdentifier.bucket).handlerUpdateTodosList(groupIdentifier.id, todoList);;
            this.todoLists.set(todoList.id, todoList);

            getTodoPage().render();
        })
    }

    static deleteTodoList(groupIdentifier: Identifier, id: bigint) {
        getLoadingComponent().wrapAsync(async () => {
            await Actors.createGroupsBucketActor(groupIdentifier.bucket).handlerDeleteTodosList(groupIdentifier.id, id);
            this.todoLists.delete(id);

            StoreTodos.todos.forEach((todo) => {
                if (todo.todoListId[0] === id) {
                    StoreTodos.todos.delete(todo.id)
                }
            })

            getTodoPage().render();
        })
    }
}

