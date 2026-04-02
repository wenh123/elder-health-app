<template>
  <div class="min-h-screen bg-gray-50">
    <AppNav />
    <main class="max-w-5xl mx-auto px-4 py-6">
      <slot />
    </main>
  </div>
</template>

<script setup>
import AppNav from './AppNav.vue'
</script>
