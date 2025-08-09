<template>
  <div id="todo-lists">
    <div id="todo-list-priority">
      <slot name="priority">List Priority</slot>
      <ComponentTodo
        v-for="todo in todosPriority"
        :key="todo.id"
        :todo="todo"
      />
    </div>

    <div id="todo-list-scheduled">
      <slot name="scheduled">List Scheduled</slot>
      <ComponentTodo
        v-for="todo in todosScheduled"
        :key="todo.id"
        :todo="todo"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from "vue";
import { storeTodo } from "../stores/store_todos";
import { storeList } from "../stores/store_todo_lists";
import Todo from "./Todo.vue"; // assuming you have a Vue version of ComponentTodo

import type { Todo } from "../../../../../declarations/organizer_backend/organizer_backend.did";

const props = defineProps<{
  currentListUUID?: string | null;
}>();

const todosPriority = ref<Todo[]>([]);
const todosScheduled = ref<Todo[]>([]);

async function update() {
  const todos = await storeTodo.apiGetTodos();
  await storeList.apiGetTodoLists();

  todosPriority.value = storeTodo.helperSortTodosByPriority(
    todos,
    props.currentListUUID ?? null
  );
  todosScheduled.value = storeTodo.helperSortTodosByScheduledDate(
    todos,
    props.currentListUUID ?? null
  );
}

onMounted(update);

// If currentListUUID changes, refresh
watch(() => props.currentListUUID, update);
</script>

<style scoped>
    #todo-lists {
        display: flex;
        justify-content: space-around;
        gap: 5em;
    }

    #todo-list-priority, #todo-list-scheduled {
        display: flex;
        flex-direction: column;
        gap: 1em;
    }
</style>
