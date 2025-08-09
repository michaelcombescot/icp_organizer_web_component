<template>
    <div id="todo-form">
        <h3>{{ isEditMode ? i18n.todoFormTitleEdit : i18n.todoFormTitleNew }}</h3>

        <form id="todo-form-form" @submit="handleSubmitForm">
            <label for="resume" class="required">{{ i18n.todoFormFieldResume }}</label>
            <input
                type="text"
                name="resume"
                :placeholder="i18n.todoFormFieldResumePlaceholder"
                required
            />

            <label for="description">{{ i18n.todoFormFieldDescription }}</label>
            <textarea
                name="description"
                :placeholder="i18n.todoFormFieldDescriptionPlaceholder"
            ></textarea>

            <label for="scheduledDate">{{ i18n.todoFormFieldScheduledDate }}</label>
            <input
                type="datetime-local"
                name="scheduledDate"
            />

            <label for="priority">{{ i18n.todoFormFieldPriority }}</label>
            <select name="priority">
                <option
                    v-for="value in storeTodo.defTodoPriorities" :key="value" :value="value"
                >
                    {{ i18n.todoFormPriorities[value] }}
                </option>
            </select>

            <label for="listUUID">{{ i18n.todoFormFieldList }}</label>
            <select name="listUUID">
                <option value=""></option>
                <option
                    v-for="list in lists"
                    :key="list.uuid"
                    :value="list.uuid"
                >
                    {{ list.name }}
                </option>
            </select>

            <input
                id="todo-form-submit"
                type="submit"
                :value="i18n.todoFormInputSubmit"
            />
        </form>
    </div>
</template>

<script setup lang="ts">
    import { ref, onMounted, computed } from "vue";
    import { Todo as todoInterface } from "../../../../../declarations/organizer_backend/organizer_backend.did";
    import { i18n } from "../../../i18n/i18n";
    import { storeTodo } from "../stores/store_todos";
    import { useModalStore } from "../../../components/modal/modal_store";
    import { useTodoListStore } from "./todoListStore";
    import { stringToEpoch, epochToStringRFC3339 } from "../../../utils/date";

    import type { Todo, TodoPriority } from "../../../../../declarations/organizer_backend/organizer_backend.did";

    const props = defineProps<{
        todo: Todo | null;
    }>();

    const listStore = useTodoListStore();
    const isEditMode = !!props.todo;
    const lists = listStore.getLists();

    const handleSubmitForm = async (event: Event) => {
        event.preventDefault();
        const form = event.target as HTMLFormElement;
        const formData = new FormData(form);
        form.reset();

        const todo: todoInterface = {
            resume:         formData.get("resume") as string,
            description:    formData.get("description") as string,
            scheduledDate:  formData.get("scheduledDate") === "" ? [] : [stringToEpoch(formData.get("scheduledDate") as string)],
            priority:       { [formData.get("priority") as string]: null },
            todoListUUID: formData.get("listUUID") as string,
            createdAt: props.todo?.createdAt ?? BigInt(Date.now())
        }
    
        useModalStore().close();
    }
</script>
