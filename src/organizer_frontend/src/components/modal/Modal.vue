<template>
    <div v-if="modalStore.isOpen" id="modal">
        <div id="mask"></div>
        <div id="modal-body">
            <button id="close-btn" @click="onCloseClick">X</button>
            <div id="modal-content">
                ${modalStore.content}
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
    import { ref, onMounted, defineExpose } from "vue";
    import { borderRadius } from "../../css/css";
    import { useModalStore } from "./modal_store";

    const modalStore = useModalStore();

    const onCloseClick = () => modalStore.close()
</script>

<style scoped>
    #modal {
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        z-index: 9999;
    }

    #mask {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.5);
        z-index: 0;
    }

    #modal-body {
        position: fixed;
        top: 50%;
        left: 50%;
        width: max-content;
        max-width: 85vw;
        height: max-content;
        z-index: 1;
        transform: translate(-50%, -50%);
        background-color: white;
        border-radius: var(--border-radius);
        padding: 2em;
    }

    #close-btn {
        position: absolute;
        top: 10px;
        right: 10px;
        width: 30px;
        height: 30px;
        font-size: 24px;
        background: transparent;
        border: none;
        cursor: pointer;
        transition: transform 0.2s ease-in-out;
    }

    #close-btn:hover {
        color: #222;
        transform: scale(1.2);
    }
</style>
