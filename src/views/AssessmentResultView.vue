<template>
  <AppLayout>
    <div v-if="loading" class="py-16 text-center text-gray-400">載入中...</div>
    <div v-else-if="!assessment" class="py-16 text-center text-gray-400">找不到評估資料</div>
    <div v-else class="space-y-5">

      <!-- Header -->
      <div class="flex items-start justify-between">
        <div class="flex items-center gap-3">
          <button @click="$router.back()" class="text-gray-400 hover:text-gray-600 text-2xl">←</button>
          <div>
            <h1 class="text-xl font-bold text-gray-900">評估結果</h1>
            <p class="text-sm text-gray-500">
              {{ elder?.name }} ・
              <span
                class="font-medium"
                :class="assessment.test_type === 'pre' ? 'text-blue-600' : 'text-orange-600'"
              >
                {{ assessment.test_type === 'pre' ? '前測' : '後測' }}
              </span>
              ・ {{ assessment.test_date }}
            </p>
          </div>
        </div>
        <span
          class="px-3 py-1 rounded-full text-sm font-bold"
          :class="{
            'bg-green-100 text-green-700':  assessment.risk_level === 'low',
            'bg-yellow-100 text-yellow-700': assessment.risk_level === 'medium',
            'bg-red-100 text-red-700':      assessment.risk_level === 'high'
          }"
        >
          {{ riskLabel }}
        </span>
      </div>

      <!-- Traffic lights -->
      <div class="card">
        <h2 class="text-sm font-semibold text-gray-700 mb-3">六大面向評估結果</h2>
        <TrafficLightPanel :flags="flags" />
      </div>

      <!-- BHT score -->
      <div class="card">
        <h2 class="text-sm font-semibold text-gray-700 mb-3">BHT 認知量表</h2>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
          <div v-for="item in bhtItems" :key="item.key" class="bg-gray-50 rounded-lg p-3">
            <p class="text-gray-500 text-xs">{{ item.label }}</p>
            <p class="text-lg font-bold text-gray-800">{{ assessment[item.key] ?? '—' }}</p>
            <p class="text-xs text-gray-400">滿分 {{ item.max }}</p>
          </div>
          <div class="bg-blue-50 rounded-lg p-3 border border-blue-200">
            <p class="text-blue-600 text-xs font-medium">BHT 總分</p>
            <p class="text-xl font-bold" :class="assessment.flag_cognitive ? 'text-red-600' : 'text-green-600'">
              {{ assessment.bht_total }}
            </p>
            <p class="text-xs text-gray-400">滿分 16</p>
          </div>
        </div>
      </div>

      <!-- Teaching suggestions -->
      <div v-if="redFlags.length > 0" class="card">
        <h2 class="text-sm font-semibold text-gray-700 mb-3">💡 教學調整建議</h2>
        <div class="space-y-4">
          <div v-for="key in redFlags" :key="key" class="border border-gray-100 rounded-xl p-4">
            <h3 class="text-sm font-semibold text-red-700 mb-2">
              🔴 {{ FLAG_LABELS[key] }} 面向異常
            </h3>
            <div class="grid sm:grid-cols-2 gap-3">
              <div>
                <p class="text-xs font-medium text-gray-500 mb-1.5">個人建議</p>
                <ul class="space-y-1">
                  <li v-for="s in suggestions[key]?.personal" :key="s" class="text-xs text-gray-700 flex gap-1.5">
                    <span class="text-blue-400 flex-shrink-0">•</span>{{ s }}
                  </li>
                </ul>
              </div>
              <div>
                <p class="text-xs font-medium text-gray-500 mb-1.5">課程調整</p>
                <ul class="space-y-1">
                  <li v-for="s in suggestions[key]?.course" :key="s" class="text-xs text-gray-700 flex gap-1.5">
                    <span class="text-orange-400 flex-shrink-0">•</span>{{ s }}
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Action buttons -->
      <div class="flex flex-wrap gap-3">
        <RouterLink :to="`/elders/${elder?.id}`" class="btn-secondary">
          查看長者資料
        </RouterLink>
        <RouterLink
          v-if="auth.canWrite"
          :to="`/assessments/new/${elder?.id}`"
          class="btn-primary"
        >
          新增另一筆評估
        </RouterLink>
        <button
          v-if="redFlags.length > 0 && auth.canWrite"
          @click="goCreateReferral"
          class="btn-danger"
        >
          ⚠️ 建立轉介單
        </button>
      </div>
    </div>
  </AppLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import AppLayout from '@/components/layout/AppLayout.vue'
import TrafficLightPanel from '@/components/assessment/TrafficLightPanel.vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { FLAG_LABELS } from '@/lib/trafficLight'

const auth   = useAuthStore()
const route  = useRoute()
const router = useRouter()

const assessment  = ref(null)
const elder       = ref(null)
const suggestions = ref({})
const loading     = ref(true)

const flags = computed(() => ({
  cognitive:  assessment.value?.flag_cognitive,
  mobility:   assessment.value?.flag_mobility,
  nutrition:  assessment.value?.flag_nutrition,
  vision:     assessment.value?.flag_vision,
  hearing:    assessment.value?.flag_hearing,
  depression: assessment.value?.flag_depression
}))

const redFlags = computed(() =>
  Object.entries(flags.value)
    .filter(([, v]) => v)
    .map(([k]) => k)
)

const riskLabel = computed(() => ({
  low:    '低度風險',
  medium: '中度風險',
  high:   '高度風險'
}[assessment.value?.risk_level] || '—'))

const bhtItems = [
  { key: 'bht_orientation',  label: '定向力',  max: 4 },
  { key: 'bht_registration', label: '訊息登錄', max: 5 },
  { key: 'bht_fluency',      label: '思考流暢', max: 2 },
  { key: 'bht_recall',       label: '訊息回應', max: 5 }
]

function goCreateReferral() {
  // Phase 3 功能：轉介系統（待開發）
  alert('轉介系統將於 Phase 3 完成開發')
}

onMounted(async () => {
  const id = route.params.id
  const [aRes, sugRes] = await Promise.all([
    supabase.from('assessments').select('*').eq('id', id).single(),
    fetch(import.meta.env.BASE_URL + 'config/teaching_suggestions.json').then(r => r.json())
  ])
  assessment.value = aRes.data
  suggestions.value = sugRes

  if (assessment.value?.elder_id) {
    const { data } = await supabase
      .from('elders').select('*')
      .eq('id', assessment.value.elder_id).single()
    elder.value = data
  }
  loading.value = false
})
</script>
