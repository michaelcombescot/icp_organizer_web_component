<template>
  <div id="main-app">
    <header>
        <div id="pages-links">
            <component-router-link :href="routes.home" :text="i18n.headerHome" />
        </div>

        <h1>{{ i18n.headerTitle }}</h1>

        <div id="auth-links">
            <template v-if="isAuthenticated">
                <a href="#" id="log-out-link" @click.prevent="logout">Log Out</a>
            </template>
            <template v-else>
                <a href="#" id="login-button" @click.prevent="login">
                    <img src="/icp-logo.svg" alt="icp-logo" />
                </a>
            </template>
        </div>
        </header>

    <div id="page"></div>

    <component-modal />
  </div>
</template>

<script setup>
    import './modules/todo/components/TodoPage.vue'
    import './components/modal/Modal.vue'
    import './components/router/router_link'

    import { i18n } from './i18n/i18n'
    import { navigateTo, routes } from './components/router/router'
    import { login, logout, whoami, isAuthenticated } from './components/auth/auth'

    onMounted(() => {
        setTimeout(() => {
            navigateTo(window.location.pathname)
        }, 0)
    })

</script>

<style scoped>
    #main-app header {
        padding: 0 1em;
        height: 10vh;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 2em;
    }

    #auth-links #login-button img {
        width: 4em;
    }

    #page {
        padding: 1em;
    }
</style>