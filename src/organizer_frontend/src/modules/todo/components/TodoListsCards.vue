<template>
    <div id="todo-lists-cards">
        <span id="todo-list-card-all" @click="selectAll">
            {{ i18n.todoListCardSeeAll }}
        </span>

        <ComponentListCard
            v-for="list in lists"
            :key="list.uuid"
            :list="list"
            :is-selected="list.uuid === currentListUUID"
            @click="selectList(list.uuid)"
        />
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import { i18n } from "../../../i18n/i18n";
import { storeList } from "../stores/store_todo_lists";
import { getTodoPage } from "./TodoPage.vue";
import { cardFontSize, scaleOnHover } from "../../../css/css";
import ComponentListCard from "./component_list_card.vue";
import type { TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";

const lists = ref<TodoList[]>([]);
const currentListUUID = ref<string | null>(null);

async function fetchLists() {
    lists.value = await storeList.apiGetTodoLists();
}

function selectAll() {
    getTodoPage().currentListUUID = "";
    currentListUUID.value = "";
}

function selectList(uuid: string) {
    getTodoPage().currentListUUID = uuid;
    currentListUUID.value = uuid;
}

onMounted(async () => {
    currentListUUID.value = null;
    await fetchLists();
});
</script>

<style scoped>
#todo-lists-cards {
    display: flex;
    flex-wrap: wrap;
    gap: 0.8em;
}

#todo-list-card-all {
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: v-bind(cardFontSize);
    width: max-content;
    padding: 0.5em;
    border-radius: 8px;
    border: 1px solid black;
    vertical-align: middle;
    cursor: pointer;
}

#todo-list-card-all:hover {
    transform: scale(v-bind(scaleOnHover));
}
</style>
