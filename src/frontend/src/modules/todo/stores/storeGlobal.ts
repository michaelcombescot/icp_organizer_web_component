import { getLoadingComponent } from "../../../components/loading"
import { APIUser } from "../apis/apiUsers"
import { getTodoPage } from "../components/componentTodoPage"
import { StoreTodos } from "./storeTodo"
import { StoreTodoLists } from "./storeTodoList"

export class StoreGlobal {
    static loaded = false

    static currentSelectedListId: bigint | null = null

    static updateCurrentSelectedListId(listId: bigint | null) {
        this.currentSelectedListId = listId
        getTodoPage().render()
    }

    static async getUserData() {
        if (this.loaded) {
            return
        }

        await getLoadingComponent().wrapAsync(async () =>{
            let data = await APIUser.getUserData()

            if ("ok" in data) {
                data.ok.todos.forEach( ([id, todo]) => StoreTodos.todos.set(id, todo));
                data.ok.todoLists.forEach( ([id, todoList]) => StoreTodoLists.todoLists.set(id, todoList));
                this.loaded = true
            }
        })
    }
}



