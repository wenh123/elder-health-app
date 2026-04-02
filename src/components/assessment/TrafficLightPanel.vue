<template>
  <div class="grid grid-cols-3 sm:grid-cols-6 gap-3">
    <div
      v-for="(flag, key) in flags"
      :key="key"
      class="flex flex-col items-center gap-1.5 p-3 rounded-xl border"
      :class="flag ? 'bg-red-50 border-red-200' : 'bg-green-50 border-green-200'"
    >
      <span class="text-2xl">{{ flag ? '🔴' : '🟢' }}</span>
      <span class="text-xs font-medium" :class="flag ? 'text-red-700' : 'text-green-700'">
        {{ FLAG_LABELS[key] }}
      </span>
    </div>
  </div>
</template>

<script setup>
import { FLAG_LABELS } from '@/lib/trafficLight'

defineProps({
  flags: { type: Object, required: true }
})
</script>
