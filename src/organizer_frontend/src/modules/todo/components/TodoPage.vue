<template>
    <div id="todo-page">
        <TodoListsCards id="component-lists-card" />

        <div id="todo-lists">
            <TodoLists id="component-todo-lists" />
        </div>

        <div id="todo-page-buttons">
            <button @click="openNewTaskModal">
                <img src="/plus.svg" />
                <span>{{ i18n.todoCreateNewButton }}</span>
            </button>
            <button @click="openNewListModal">
                <img src="/plus.svg" />
                <span>{{ i18n.todoListCreateButton }}</span>
            </button>
        </div>

        
    </div>
</template>

<script setup lang="ts">
    import { i18n } from "../../../i18n/i18n";
    import { borderRadius } from "../../../css/css";

    import TodoLists from "./TodoList.vue";
    import TodoListsCards from "./TodoListsCards.vue";
    import TodoForm from "./TodoForm.vue";
    import ListForm from "./TodoListForm.vue";
    import { useModalStore } from "../../../components/modal/modal_store";
    import { useTodoPageStore } from "./todoPageStore";
    import { h } from "vue"

    const modalStore = useModalStore();

    const openNewTaskModal = () => modalStore.open(h(TodoForm, { list: null }));
    const openNewListModal = () => modalStore.open(h(ListForm));
</script>

<style scoped>
    #todo-page {
        display: flex;
        flex-direction: column;
        gap: 1.5em;
    }

    #todo-page-buttons {
        display: flex;
        gap: 1.5em;
    }

    #todo-page-buttons button {
        font-size: 0.8em;
        padding: 0.5em 1em;
        text-align: center;
        width: max-content;
        border-radius: v-bind(borderRadius);
        background-color: lightblue;
        cursor: pointer;
    }

    #todo-page-buttons button img {
        vertical-align: middle;
        width: 1.5em;
        margin-right: 0.5em;
    }

    #todo-page-buttons button span {
        vertical-align: middle;
    }

    #todo-page-buttons button:hover {
        background-color: darkblue;
        color: white;
    }

    #todo-page-buttons button:hover img {
        filter: invert(1);
    }

    #todo-select-list {
        width: max-content;
    }
</style>
