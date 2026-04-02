<template>
  <header class="bg-white border-b border-gray-200 sticky top-0 z-40">
    <div class="max-w-5xl mx-auto px-4 h-14 flex items-center justify-between">
      <!-- Logo -->
      <RouterLink to="/elders" class="flex items-center gap-2 font-bold text-blue-800 text-base">
        <span class="text-xl">🏥</span>
        <span class="hidden sm:block">長者健康管理系統</span>
        <span class="sm:hidden">健康管理</span>
      </RouterLink>

      <!-- Nav links -->
      <nav class="hidden md:flex items-center gap-1">
        <RouterLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="px-3 py-1.5 text-sm rounded-lg transition-colors"
          :class="isActive(item.to)
            ? 'bg-blue-50 text-blue-700 font-medium'
            : 'text-gray-600 hover:bg-gray-100'"
        >
          {{ item.label }}
        </RouterLink>
      </nav>

      <!-- User info + logout -->
      <div class="flex items-center gap-3">
        <span class="hidden sm:block text-sm text-gray-500">{{ auth.userName }}</span>
        <span class="badge-blue hidden sm:inline-flex">{{ roleLabel }}</span>
        <button @click="handleLogout" class="btn-secondary text-xs px-3 py-1.5">
          登出
        </button>
      </div>
    </div>

    <!-- Mobile nav -->
    <div class="md:hidden border-t border-gray-100 flex overflow-x-auto">
      <RouterLink
        v-for="item in navItems"
        :key="item.to"
        :to="item.to"
        class="flex-shrink-0 px-4 py-2.5 text-sm border-b-2 transition-colors"
        :class="isActive(item.to)
          ? 'border-blue-600 text-blue-700 font-medium'
          : 'border-transparent text-gray-600'"
      >
        {{ item.label }}
      </RouterLink>
    </div>
  </header>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth   = useAuthStore()
const route  = useRoute()
const router = useRouter()

const navItems = [
  { to: '/elders',    label: '長者清單' },
  { to: '/referrals', label: '轉介管理' },
]

const roleLabel = computed(() => ({
  admin:      '管理員',
  manager:    '主持人',
  instructor: '指導員',
  caregiver:  '照服員',
  medical:    '醫療人員'
}[auth.role] || auth.role))

function isActive(path) {
  return route.path.startsWith(path)
}

async function handleLogout() {
  await auth.logout()
  router.push('/login')
}
</script>
