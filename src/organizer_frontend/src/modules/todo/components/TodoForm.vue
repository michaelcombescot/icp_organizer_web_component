<template>
    <div id="todo-form">
        <h3>{{ isEditMode ? i18n.todoFormTitleEdit : i18n.todoFormTitleNew }}</h3>

        <form id="todo-form-form" @submit="handleSubmitForm">
            <label for="resume" class="required">{{ i18n.todoFormFieldResume }}</label>
            <input
                type="text"
                name="resume"
                v-model="form.resume"
                :placeholder="i18n.todoFormFieldResumePlaceholder"
                required
            />

            <label for="description">{{ i18n.todoFormFieldDescription }}</label>
            <textarea
                name="description"
                v-model="form.description"
                :placeholder="i18n.todoFormFieldDescriptionPlaceholder"
            ></textarea>

            <label for="scheduledDate">{{ i18n.todoFormFieldScheduledDate }}</label>
            <input
                type="datetime-local"
                name="scheduledDate"
                v-model="form.scheduledDate"
            />

            <label for="priority">{{ i18n.todoFormFieldPriority }}</label>
            <select name="priority" v-model="form.priority">
                <option
                    v-for="value in storeTodo.defTodoPriorities"
                    :key="value"
                    :value="value"
                >
                    {{ i18n.todoFormPriorities[value] }}
                </option>
            </select>

            <label for="listUUID">{{ i18n.todoFormFieldList }}</label>
            <select name="listUUID" v-model="form.listUUID">
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
    import { storeList } from "../stores/store_todo_lists";
    import { stringToEpoch, epochToStringRFC3339 } from "../../../utils/date";

    import type { Todo } from "../../../../../declarations/organizer_backend/organizer_backend.did";

    const props = defineProps<{
        todo: Todo | null;
    }>();

    const listStore = useListStore();
    const isEditMode = !!props.todo;
    const lists = listStore.getLists();

    const form = ref<todoInterface>({
        resume: props.todo?.resume || "",
        description: props.todo?.description || "",
        scheduledDate:
            props.todo?.scheduledDate && props.todo?.scheduledDate !== BigInt(0)
                ? epochToStringRFC3339(props.todo.scheduledDate)
                : "",
        priority: props.todo ? Object.keys(props.todo.priority)[0] as keyof TodoPriority : "low",
        listUUID: props.todo?.todoListUUID || props.currentListUUID || ""
    });

    const submitForm = async () => {
        const todo = await storeTodo.addTodo(form.value);
        if (todo) {
            useModalStore().close();
        }
    };

    useModalStore().close();
</script>
