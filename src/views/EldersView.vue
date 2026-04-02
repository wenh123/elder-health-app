<template>
  <AppLayout>
    <!-- Page header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-xl font-bold text-gray-900">長者清單</h1>
        <p class="text-sm text-gray-500 mt-0.5">{{ auth.profile?.site_id ? '本據點' : '所有' }}長者資料</p>
      </div>
      <button
        v-if="auth.canWrite"
        @click="showAddModal = true"
        class="btn-primary"
      >
        ＋ 新增長者
      </button>
    </div>

    <!-- Search & filter bar -->
    <div class="card mb-4 flex flex-col sm:flex-row gap-3">
      <input
        v-model="search"
        type="text"
        placeholder="搜尋姓名..."
        class="form-input flex-1"
      />
      <select v-model="filterGender" class="form-input w-full sm:w-32">
        <option value="">全部性別</option>
        <option value="M">男</option>
        <option value="F">女</option>
      </select>
    </div>

    <!-- Elders table -->
    <div class="card p-0 overflow-hidden">
      <div v-if="loading" class="py-12 text-center text-gray-400">載入中...</div>
      <div v-else-if="filtered.length === 0" class="py-12 text-center text-gray-400">
        {{ search ? '查無符合結果' : '尚無長者資料' }}
      </div>
      <table v-else class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr>
            <th class="px-4 py-3 text-left font-medium text-gray-600">姓名</th>
            <th class="px-4 py-3 text-left font-medium text-gray-600">性別</th>
            <th class="px-4 py-3 text-left font-medium text-gray-600 hidden sm:table-cell">年齡</th>
            <th class="px-4 py-3 text-left font-medium text-gray-600 hidden md:table-cell">教育程度</th>
            <th class="px-4 py-3 text-left font-medium text-gray-600">操作</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr
            v-for="elder in filtered"
            :key="elder.id"
            class="hover:bg-gray-50 transition-colors"
          >
            <td class="px-4 py-3 font-medium text-gray-900">{{ elder.name }}</td>
            <td class="px-4 py-3 text-gray-600">{{ elder.gender === 'M' ? '男' : '女' }}</td>
            <td class="px-4 py-3 text-gray-600 hidden sm:table-cell">{{ calcAge(elder.birth_date) }} 歲</td>
            <td class="px-4 py-3 text-gray-600 hidden md:table-cell">{{ elder.education || '—' }}</td>
            <td class="px-4 py-3">
              <div class="flex gap-2">
                <RouterLink :to="`/elders/${elder.id}`" class="btn-secondary text-xs px-2.5 py-1">
                  查看
                </RouterLink>
                <RouterLink
                  v-if="auth.canWrite"
                  :to="`/assessments/new/${elder.id}`"
                  class="btn-primary text-xs px-2.5 py-1"
                >
                  新增評估
                </RouterLink>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Add Elder Modal -->
    <Teleport to="body">
      <div
        v-if="showAddModal"
        class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4"
        @click.self="showAddModal = false"
      >
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
          <h2 class="text-lg font-semibold mb-4">新增長者資料</h2>

          <form @submit.prevent="handleAddElder" class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
              <div class="col-span-2">
                <label class="form-label">姓名 <span class="text-red-500">*</span></label>
                <input v-model="newElder.name" type="text" required class="form-input" placeholder="王〇〇" />
              </div>
              <div>
                <label class="form-label">性別 <span class="text-red-500">*</span></label>
                <select v-model="newElder.gender" required class="form-input">
                  <option value="">請選擇</option>
                  <option value="M">男</option>
                  <option value="F">女</option>
                </select>
              </div>
              <div>
                <label class="form-label">出生年月日 <span class="text-red-500">*</span></label>
                <input v-model="newElder.birth_date" type="date" required class="form-input" />
              </div>
              <div class="col-span-2">
                <label class="form-label">教育程度</label>
                <select v-model="newElder.education" class="form-input">
                  <option value="">請選擇</option>
                  <option>不識字</option>
                  <option>國小</option>
                  <option>國中</option>
                  <option>高中/職</option>
                  <option>大學以上</option>
                </select>
              </div>
            </div>

            <div v-if="addError" class="text-sm text-red-600">{{ addError }}</div>

            <div class="flex gap-3 pt-2">
              <button type="submit" :disabled="addLoading" class="btn-primary flex-1">
                {{ addLoading ? '儲存中...' : '儲存' }}
              </button>
              <button type="button" @click="showAddModal = false" class="btn-secondary flex-1">取消</button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </AppLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const auth    = useAuthStore()
const elders  = ref([])
const loading = ref(true)
const search  = ref('')
const filterGender = ref('')
const showAddModal = ref(false)
const addLoading   = ref(false)
const addError     = ref('')

const newElder = ref({ name: '', gender: '', birth_date: '', education: '' })

const filtered = computed(() => {
  return elders.value.filter(e => {
    const matchName   = !search.value || e.name.includes(search.value)
    const matchGender = !filterGender.value || e.gender === filterGender.value
    return matchName && matchGender
  })
})

function calcAge(birthDate) {
  const today = new Date()
  const birth = new Date(birthDate)
  return today.getFullYear() - birth.getFullYear()
}

async function fetchElders() {
  loading.value = true
  const { data, error } = await supabase
    .from('elders')
    .select('*')
    .eq('is_active', true)
    .order('name')
  if (!error) elders.value = data || []
  loading.value = false
}

async function handleAddElder() {
  addLoading.value = true
  addError.value   = ''
  try {
    const { error } = await supabase.from('elders').insert({
      ...newElder.value,
      site_id: auth.siteId
    })
    if (error) throw error
    showAddModal.value = false
    newElder.value = { name: '', gender: '', birth_date: '', education: '' }
    await fetchElders()
  } catch (e) {
    addError.value = '儲存失敗：' + (e.message || '請重試')
  } finally {
    addLoading.value = false
  }
}

onMounted(fetchElders)
</script>
