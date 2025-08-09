import { defineStore } from 'pinia';

export const useModalStore = defineStore('modal', {
    state: () => ({
        isOpen: false,
        content: null
    }),
    actions: {
        open(content: any) {
            this.content = content;
            this.isOpen = true;
        },
        close() {
            this.isOpen = false;
            this.content = null;
        }
    }
});