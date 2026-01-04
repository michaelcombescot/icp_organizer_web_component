import { getLoadingComponent } from "../../../components/loading"
import { getTodoPage } from "../components/componentTodoPage"
import { StoreTodos } from "./storeTodo"

export class StoreGlobal {
    static indexesFetched = false

    static currentSelectedGroupId: bigint | null = null

    static currentSelectedListId: bigint | null = null

    static updateCurrentGroupId(groupId: bigint | null) {
        this.currentSelectedGroupId = groupId
        getTodoPage().render()
    }

    static updateCurrentSelectedListId(listId: bigint | null) {
        this.currentSelectedListId = listId
        getTodoPage().render()
    }
}



