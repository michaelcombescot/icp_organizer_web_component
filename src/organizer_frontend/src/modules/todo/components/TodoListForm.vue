<template>
    <div id="list-form">
        <h3>{{ isEditMode ? i18n.todoListFormTitleEdit : i18n.todoListFormTitleNew }}</h3>

        <form id="list-form-form" @submit.prevent="handleSubmitForm">
            <label for="name" class="required">{{ i18n.todoListFormFieldName }}</label>
            <input
                type="text"
                name="name"
                v-model="form.name"
                required
            />

            <label for="color" class="required">{{ i18n.todoListFormFieldColor }}</label>
            <input
                type="color"
                name="color"
                v-model="form.color"
            />

            <input type="submit" :value="i18n.todoListFormInputSubmit" />
        </form>
    </div>
</template>

<script setup lang="ts">
    import { reactive, computed } from "vue";
    import { i18n } from "../../../i18n/i18n";
    import { storeList } from "../stores/store_todo_lists";
    import { getListsCards } from "./TodoListsCards.vue";
    import { getCard } from "./TodoListCard.vue";
    import type { TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";

    interface Props {
        list?: TodoList | null;
    }

    const props = defineProps<Props>();

    const isEditMode = computed(() => !!props.list);

    const form = reactive({
        name: props.list?.name ?? "",
        color: props.list?.color ?? "#000000"
    });

    async function handleSubmitForm() {
        const list: TodoList = {
            uuid: props.list ? props.list.uuid : crypto.randomUUID(),
            name: form.name,
            color: form.color
        };

        if (isEditMode.value) {
            await storeList.apiUpdateTodoList(list);
            getCard(props.list!.uuid).list = list;
        } else {
            await storeList.apiAddTodoList(list);
            getListsCards().lists = [...getListsCards().lists, list];
        }

        closeModal();
    }
</script>

<style scoped>
#list-form {
    display: flex;
    flex-direction: column;
    gap: 3em;
    align-items: center;
}

#list-form form {
    display: grid;
    grid-template-columns: 0.5fr 2fr;
    gap: 1em;
    width: 70vw;
    max-width: 60em;
}

#list-form .required::after {
    content: "*";
    color: red;
}

#list-form input[type="submit"] {
    grid-column: -2 / -1;
    justify-self: right;
}
</style>
