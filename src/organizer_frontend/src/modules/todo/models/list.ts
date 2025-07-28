import { Todo } from "./todo";

interface ListParams {
    uuid: string,
    name: string,
    color: string
}

export class List {
    uuid: string;
    name: string;
    color: string;

    constructor(data: ListParams) {
        this.uuid = data.uuid;
        this.name = data.name;
        this.color = data.color;
    }
}