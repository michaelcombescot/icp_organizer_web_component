import { type Todo } from "./todo";
import { type List } from "./list";

export type UpdateListType =  
    {"addTodo": Todo} 
    | {"deleteTodo": string}
    | {"updateTodo": Todo} 
    | {"addList": List}
    | {"deleteList": string} 
    | {"updateList": List}

export let updateList: UpdateListType[]