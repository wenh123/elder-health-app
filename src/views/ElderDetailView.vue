<template>
  <AppLayout>
    <div v-if="loading" class="py-16 text-center text-gray-400">載入中...</div>
    <div v-else-if="!elder" class="py-16 text-center text-gray-400">找不到此長者資料</div>
    <div v-else>

      <!-- Header -->
      <div class="flex items-start justify-between mb-6">
        <div class="flex items-center gap-4">
          <RouterLink to="/elders" class="text-gray-400 hover:text-gray-600 text-2xl">←</RouterLink>
          <div>
            <h1 class="text-xl font-bold text-gray-900">{{ elder.name }}</h1>
            <p class="text-sm text-gray-500">
              {{ elder.gender === 'M' ? '男' : '女' }}・{{ calcAge(elder.birth_date) }} 歲・{{ elder.education || '教育程度未填' }}
            </p>
          </div>
        </div>
        <RouterLink
          v-if="auth.canWrite"
          :to="`/assessments/new/${elder.id}`"
          class="btn-primary"
        >
          ＋ 新增評估
        </RouterLink>
      </div>

      <!-- Assessments history -->
      <h2 class="text-base font-semibold text-gray-800 mb-3">評估記錄</h2>

      <div v-if="assessments.length === 0" class="card text-center text-gray-400 py-8">
        尚無評估記錄，點擊「新增評估」開始施測
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="a in assessments"
          :key="a.id"
          class="card hover:shadow-md transition-shadow cursor-pointer"
          @click="$router.push(`/assessments/${a.id}/result`)"
        >
          <div class="flex items-start justify-between">
            <div>
              <span
                class="text-xs font-semibold px-2 py-0.5 rounded-full mr-2"
                :class="a.test_type === 'pre' ? 'bg-blue-100 text-blue-700' : 'bg-orange-100 text-orange-700'"
              >
                {{ a.test_type === 'pre' ? '前測' : '後測' }}
              </span>
              <span class="text-sm text-gray-600">{{ a.test_date }}</span>
            </div>
            <span
              class="text-xs font-semibold px-2 py-1 rounded-full"
              :class="{
                'bg-green-100 text-green-700':  a.risk_level === 'low',
                'bg-yellow-100 text-yellow-700': a.risk_level === 'medium',
                'bg-red-100 text-red-700':      a.risk_level === 'high'
              }"
            >
              {{ { low:'低度風險', medium:'中度風險', high:'高度風險' }[a.risk_level] || '—' }}
            </span>
          </div>

          <!-- Mini traffic lights -->
          <div class="mt-3 flex gap-1.5 flex-wrap">
            <span
              v-for="(flag, key) in getFlags(a)"
              :key="key"
              class="text-xs px-2 py-0.5 rounded-full border"
              :class="flag ? 'bg-red-50 border-red-200 text-red-700' : 'bg-green-50 border-green-200 text-green-700'"
            >
              {{ flag ? '🔴' : '🟢' }} {{ FLAG_LABELS[key] }}
            </span>
          </div>

          <p class="mt-2 text-xs text-gray-400">BHT 總分：{{ a.bht_total }} / 16</p>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { FLAG_LABELS } from '@/lib/trafficLight'

const auth  = useAuthStore()
const route = useRoute()
const elder = ref(null)
const assessments = ref([])
const loading = ref(true)

function calcAge(birthDate) {
  return new Date().getFullYear() - new Date(birthDate).getFullYear()
}

function getFlags(a) {
  return {
    cognitive:  a.flag_cognitive,
    mobility:   a.flag_mobility,
    nutrition:  a.flag_nutrition,
    vision:     a.flag_vision,
    hearing:    a.flag_hearing,
    depression: a.flag_depression
  }
}

onMounted(async () => {
  const id = route.params.id
  const [elderRes, assessRes] = await Promise.all([
    supabase.from('elders').select('*').eq('id', id).single(),
    supabase.from('assessments').select('*').eq('elder_id', id).order('test_date', { ascending: false })
  ])
  elder.value       = elderRes.data
  assessments.value = assessRes.data || []
  loading.value     = false
})
</script>
