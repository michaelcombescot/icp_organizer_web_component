import { Todo } from "./todo";

export class List {
    uuid: string;
    name: string;
    color: string;
    todos: Todo[]
    todosUUIDs: string[]

    constructor(uuid: string, name: string, color: string) {
        this.uuid = uuid;
        this.name = name;
        this.color = color;
        this.todos = []
        this.todosUUIDs = []
    }
}