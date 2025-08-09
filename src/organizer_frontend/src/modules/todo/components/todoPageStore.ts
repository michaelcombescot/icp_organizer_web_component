import { defineStore } from 'pinia';

export const useTodoPageStore = defineStore('modal', {
    state: () => ({
        currentListUUID: ""
    }),
    actions: {
        setCurrentListUUID(uuid: string) {
            this.currentListUUID = uuid;
        }
    }
});