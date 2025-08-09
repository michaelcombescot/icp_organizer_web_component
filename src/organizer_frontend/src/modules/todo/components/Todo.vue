<template>
    <div
        class="todo-item"
        :style="{ backgroundColor: list?.color || '#fefee2' }"
    >
        <div v-if="todo.scheduledDate !== 0n" class="todo-item-date">
            <span>{{ stringDateFromEpoch(todo.scheduledDate) }}</span>
            <span>{{ remainingTimeFromEpoch(todo.scheduledDate) }}</span>
        </div>

        <div
            class="todo-item-resume"
            :class="priorityClass"
            @click="openShowModal"
        >
            {{ todo.resume }}
        </div>

        <div class="todo-item-actions">
            <img
                class="todo-item-action-edit"
                src="/edit.svg"
                @click="openEditModal"
            />
            <img
                class="todo-item-action-done"
                src="/done.svg"
                @click="toggleDone"
            />
            <img
                class="todo-item-action-delete"
                src="/trash.svg"
                @click="deleteTodo"
            />
        </div>
    </div>
</template>

<script setup lang="ts">
    import { computed, h } from "vue";
    import { storeTodo } from "../stores/store_todos";
    import { openModalWithElement } from "../../../components/modal/Modal.vue";
    import { remainingTimeFromEpoch, stringDateFromEpoch } from "../../../utils/date";
    import { borderRadius, scaleOnHover } from "../../../css/css";

    import TodoForm from "./TodoForm.vue";
    import TodoShow from "./TodoShow.vue";

    import type { Todo, TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";

    const props = defineProps<{
        todo: Todo;
        list: TodoList | null;
    }>();

    const priorityClass = computed(() => {
        return Object.keys(props.todo.priority)[0] || "";
    });

    function openShowModal() {
        openModalWithElement(h(TodoShow, { todo: props.todo }));
    }

    function openEditModal() {
        openModalWithElement(
            h(ComponentTodoForm, {
                todo: props.todo,
                todoListUUID: props.todo.todoListUUID,
            })
        );
    }

    function toggleDone() {
        props.todo.done = !props.todo.done;
    }

    async function deleteTodo() {
        await storeTodo.apiDeleteTodo(props.todo.uuid);
    }
</script>

<style scoped>
    .todo-item {
        display: flex;
        flex-direction: column;
        gap: 1em;
        padding: 1em;
        min-width: 15em;
        border-radius: v-bind(borderRadius);
    }

    .todo-item-actions {
        display: flex;
        justify-content: space-between;
    }

    .todo-item-actions img {
        width: 1em;
        cursor: pointer;
    }

    .todo-item-actions img:hover {
        transform: scale(v-bind(scaleOnHover));
    }

    .todo-item-date {
        display: flex;
        gap: 1em;
        justify-content: space-between;
    }

    .todo-item-resume {
        background-color: white;
        padding: 0.5em;
        border-radius: v-bind(borderRadius);
    }

    .todo-item-resume.high {
        background-color: red;
    }

    .todo-item-resume.medium {
        background-color: yellow;
    }
</style>
