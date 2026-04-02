<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 to-white flex items-center justify-center px-4">
    <div class="w-full max-w-sm">

      <!-- Logo card -->
      <div class="text-center mb-8">
        <div class="text-5xl mb-3">🏥</div>
        <h1 class="text-2xl font-bold text-blue-900">長者健康管理系統</h1>
        <p class="text-sm text-gray-500 mt-1">延緩失能益智桌遊計畫</p>
      </div>

      <div class="card shadow-md">
        <h2 class="text-lg font-semibold text-gray-800 mb-5">登入帳號</h2>

        <form @submit.prevent="handleLogin" class="space-y-4">
          <div>
            <label class="form-label" for="email">電子郵件</label>
            <input
              id="email"
              v-model="form.email"
              type="email"
              autocomplete="username"
              required
              class="form-input"
              placeholder="user@example.com"
            />
          </div>
          <div>
            <label class="form-label" for="password">密碼</label>
            <input
              id="password"
              v-model="form.password"
              type="password"
              autocomplete="current-password"
              required
              class="form-input"
              placeholder="••••••••"
            />
          </div>

          <!-- Error message -->
          <div v-if="error" class="bg-red-50 border border-red-200 rounded-lg px-3 py-2 text-sm text-red-700">
            {{ error }}
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="btn-primary w-full"
          >
            <span v-if="loading" class="mr-2">⏳</span>
            {{ loading ? '登入中...' : '登入' }}
          </button>
        </form>
      </div>

      <p class="text-center text-xs text-gray-400 mt-6">
        帳號由系統管理員建立，如需協助請聯繫管理員
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth    = useAuthStore()
const router  = useRouter()
const route   = useRoute()

const form    = ref({ email: '', password: '' })
const loading = ref(false)
const error   = ref('')

async function handleLogin() {
  loading.value = true
  error.value   = ''
  try {
    await auth.login(form.value.email, form.value.password)
    const redirect = route.query.redirect || '/elders'
    router.push(redirect)
  } catch (e) {
    error.value = '電子郵件或密碼錯誤，請重新確認。'
  } finally {
    loading.value = false
  }
}
</script>
