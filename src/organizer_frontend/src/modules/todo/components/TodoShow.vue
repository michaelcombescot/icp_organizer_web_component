<template>
    <div id="todo-show">
        <div>{{ i18n.todoFormFieldResume }}</div>
        <div>{{ todo.resume }}</div>

        <div>{{ i18n.todoFormFieldDescription }}</div>
        <div>{{ todo.description }}</div>

        <template v-if="todo.scheduledDate">
            <div>{{ i18n.todoFormFieldScheduledDate }}</div>
            <div>{{ stringDateFromEpoch(todo.scheduledDate) }}</div>
        </template>

        <div>{{ i18n.todoFormFieldPriority }}</div>
        <div>{{ i18n.todoFormPriorities[  Object.keys(props.todo.priority)[0] ] }}</div>

        <div>{{ i18n.todoFormFieldStatus }}</div>
        <div>{{ i18n.todoFormStatuses[ Object.keys(props.todo.status)[0] ] }}</div>
    </div>
</template>

<script setup lang="ts">
    import { computed } from "vue";
    import { i18n } from "../../../i18n/i18n";
    import { stringDateFromEpoch } from "../../../utils/date";
    import type { Todo } from "../../../../../declarations/organizer_backend/organizer_backend.did";

    const props = defineProps<{
        todo: Todo;
    }>();
</script>

<style scoped>
    #todo-show {
        display: grid;
        grid-template-columns: 0.3fr 1fr;
        gap: 1em;
    }
</style>
