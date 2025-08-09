<template>
    <div
        class="todo-list-card"
        :class="{ selected: isSelected }"
        :data-list-uuid="list.uuid"
    >
        <span
            class="todo-list-card-name"
            @click.stop="selectList"
        >
            {{ list.name }}
        </span>

        <div class="todo-list-card-actions">
            <img
                class="todo-list-card-edit"
                src="/edit.svg"
                @click.stop="editList"
            >
            <img
                class="todo-list-card-delete"
                src="/trash.svg"
                @click.stop="deleteList"
            >
        </div>
    </div>
</template>

<script setup lang="ts">
    import { openModalWithElement } from "../../../components/modal/Modal.vue";
    import ComponentListForm from "./TodoListForm.vue";
    import { i18n } from "../../../i18n/i18n";
    import { getTodoPage } from "./TodoPage.vue";
    import { borderRadius, cardFontSize, scaleOnHover } from "../../../css/css";
    import { storeList } from "../stores/store_todo_lists";
    import type { TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";

    interface Props {
        list: TodoList;
        isSelected: boolean;
    }

    const props = defineProps<Props>();

    const selectList = () => getTodoPage().currentListUUID = props.list.uuid
    const editList = () => openModalWithElement(new ComponentListForm(props.list))
    const deleteList = () => {
        if (!confirm(i18n.todoListCardConfirmDelete)) return;
        
        await storeList.apiDeleteTodoList(props.list.uuid);
        getTodoPage().currentListUUID = "";
    }
</script>

<style scoped>
    .todo-list-card {
        display: flex;
        justify-content: center;
        align-items: center;
        width: max-content;
        font-size: v-bind(cardFontSize);
        color: white;
        padding: 0.5em;
        border-radius: v-bind(borderRadius);
        border: 0.3em solid;
        background-color: v-bind(list.color);
        transition: transform 0.2s ease;
    }

    .todo-list-card-name {
        cursor: pointer;
        margin-right: 0.5em;
    }

    .todo-list-card-actions {
        display: flex;
        gap: 0.5em;
    }

    .todo-list-card-actions img {
        width: 1em;
        filter: brightness(0) invert(1);
        cursor: pointer;
    }

    .todo-list-card.selected {
        border: 0.3em solid black;
    }

    .todo-list-card:hover {
        transform: scale(v-bind(scaleOnHover));
    }
</style>
