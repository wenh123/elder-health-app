<template>
  <AppLayout>
    <!-- Header -->
    <div class="flex items-center gap-4 mb-6">
      <button @click="$router.back()" class="text-gray-400 hover:text-gray-600 text-2xl">←</button>
      <div>
        <h1 class="text-xl font-bold text-gray-900">新增評估</h1>
        <p class="text-sm text-gray-500">{{ elder?.name }} ・ {{ today }}</p>
      </div>
    </div>

    <!-- Step indicator -->
    <div class="flex items-center gap-2 mb-6">
      <div
        v-for="(s, i) in steps"
        :key="i"
        class="flex items-center gap-2"
      >
        <div
          class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-colors"
          :class="step > i
            ? 'bg-green-500 text-white'
            : step === i
              ? 'bg-blue-600 text-white'
              : 'bg-gray-200 text-gray-500'"
        >
          {{ step > i ? '✓' : i + 1 }}
        </div>
        <span
          class="text-sm hidden sm:block"
          :class="step === i ? 'font-semibold text-blue-700' : 'text-gray-500'"
        >
          {{ s.label }}
        </span>
        <span v-if="i < steps.length - 1" class="text-gray-300 mx-1">›</span>
      </div>
    </div>

    <!-- Step content -->
    <div class="card mb-4">
      <!-- Step 0: 基本設定 + BHT -->
      <div v-if="step === 0">
        <h2 class="text-base font-semibold text-gray-800 mb-4">基本設定</h2>
        <div class="grid sm:grid-cols-2 gap-4 mb-6">
          <div>
            <label class="form-label">測驗類型 <span class="text-red-500">*</span></label>
            <select v-model="form.test_type" class="form-input">
              <option value="pre">前測</option>
              <option value="post">後測</option>
            </select>
          </div>
          <div>
            <label class="form-label">施測日期 <span class="text-red-500">*</span></label>
            <input v-model="form.test_date" type="date" class="form-input" />
          </div>
        </div>
        <hr class="my-4 border-gray-100" />
        <h2 class="text-base font-semibold text-gray-800 mb-4">步驟 1：BHT 認知量表</h2>
        <BHTForm v-model="form" :threshold="rules?.bht?.threshold ?? 12" />
      </div>

      <!-- Step 1: 體適能 -->
      <div v-if="step === 1">
        <h2 class="text-base font-semibold text-gray-800 mb-4">步驟 2：體適能功能檢測</h2>
        <FitnessForm v-model="form" />
      </div>

      <!-- Step 2: ICOPE -->
      <div v-if="step === 2">
        <h2 class="text-base font-semibold text-gray-800 mb-4">步驟 3：ICOPE 長者功能整合評估</h2>
        <ICOPEForm v-model="form" />
      </div>

      <!-- Step 3: 預覽與確認 -->
      <div v-if="step === 3">
        <h2 class="text-base font-semibold text-gray-800 mb-4">預覽評估結果</h2>
        <div v-if="previewResult" class="space-y-4">
          <TrafficLightPanel :flags="previewResult.flags" />
          <div class="flex items-center gap-3 mt-2">
            <span class="text-sm font-medium text-gray-700">整體風險等級：</span>
            <span
              class="px-3 py-1 rounded-full text-sm font-bold"
              :class="RISK_LABELS[previewResult.riskLevel].bg + ' ' + RISK_LABELS[previewResult.riskLevel].color"
            >
              {{ RISK_LABELS[previewResult.riskLevel].label }}
            </span>
          </div>
          <p class="text-xs text-gray-400">確認無誤後點擊「儲存評估」</p>
        </div>
      </div>
    </div>

    <!-- Navigation buttons -->
    <div class="flex gap-3">
      <button v-if="step > 0" @click="step--" class="btn-secondary">← 上一步</button>
      <div class="flex-1"></div>
      <button
        v-if="step < steps.length - 1"
        @click="nextStep"
        class="btn-primary"
      >
        下一步 →
      </button>
      <button
        v-if="step === steps.length - 1"
        @click="handleSave"
        :disabled="saving"
        class="btn-primary"
      >
        {{ saving ? '儲存中...' : '💾 儲存評估' }}
      </button>
    </div>

    <div v-if="saveError" class="mt-3 text-sm text-red-600">{{ saveError }}</div>
  </AppLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppLayout from '@/components/layout/AppLayout.vue'
import BHTForm from '@/components/assessment/BHTForm.vue'
import FitnessForm from '@/components/assessment/FitnessForm.vue'
import ICOPEForm from '@/components/assessment/ICOPEForm.vue'
import TrafficLightPanel from '@/components/assessment/TrafficLightPanel.vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { evaluate, RISK_LABELS } from '@/lib/trafficLight'

const auth   = useAuthStore()
const route  = useRoute()
const router = useRouter()

const elder    = ref(null)
const rules    = ref(null)
const step     = ref(0)
const saving   = ref(false)
const saveError = ref('')
const today    = new Date().toLocaleDateString('zh-TW')

const steps = [
  { label: 'BHT 認知' },
  { label: '體適能' },
  { label: 'ICOPE' },
  { label: '確認儲存' }
]

// 表單初始值
const form = ref({
  test_type: 'pre',
  test_date: new Date().toISOString().split('T')[0],
  // BHT
  bht_orientation: '', bht_registration: '', bht_fluency: '', bht_recall: '',
  // Fitness
  fitness_chair_stand: '', fitness_bicep_curl: '', fitness_step_march: '',
  icope_mobility: false,
  // ICOPE
  icope_nutrition1: false, icope_nutrition2: false,
  icope_vision1: false, icope_vision2: false,
  icope_hearing: false,
  icope_depression1: false, icope_depression2: false,
  notes: ''
})

const previewResult = computed(() => {
  if (!elder.value || !rules.value) return null
  return evaluate(form.value, rules.value, elder.value)
})

function nextStep() {
  if (step.value < steps.length - 1) step.value++
}

async function handleSave() {
  if (!previewResult.value || !elder.value) return
  saving.value    = true
  saveError.value = ''

  const { flags, riskLevel } = previewResult.value

  try {
    const payload = {
      elder_id:     elder.value.id,
      assessor_id:  auth.session?.user?.id,
      test_type:    form.value.test_type,
      test_date:    form.value.test_date,
      // BHT
      bht_orientation:  Number(form.value.bht_orientation)  || 0,
      bht_registration: Number(form.value.bht_registration) || 0,
      bht_fluency:      Number(form.value.bht_fluency)      || 0,
      bht_recall:       Number(form.value.bht_recall)       || 0,
      // Fitness
      fitness_chair_stand: form.value.fitness_chair_stand !== '' ? Number(form.value.fitness_chair_stand) : null,
      fitness_bicep_curl:  form.value.fitness_bicep_curl  !== '' ? Number(form.value.fitness_bicep_curl)  : null,
      fitness_step_march:  form.value.fitness_step_march  !== '' ? Number(form.value.fitness_step_march)  : null,
      // ICOPE
      icope_mobility:    form.value.icope_mobility,
      icope_nutrition1:  form.value.icope_nutrition1,
      icope_nutrition2:  form.value.icope_nutrition2,
      icope_vision1:     form.value.icope_vision1,
      icope_vision2:     form.value.icope_vision2,
      icope_hearing:     form.value.icope_hearing,
      icope_depression1: form.value.icope_depression1,
      icope_depression2: form.value.icope_depression2,
      // Flags
      flag_cognitive:  flags.cognitive,
      flag_mobility:   flags.mobility,
      flag_nutrition:  flags.nutrition,
      flag_vision:     flags.vision,
      flag_hearing:    flags.hearing,
      flag_depression: flags.depression,
      risk_level:      riskLevel,
      notes:           form.value.notes
    }

    const { data, error } = await supabase
      .from('assessments')
      .insert(payload)
      .select()
      .single()

    if (error) throw error
    router.push(`/assessments/${data.id}/result`)
  } catch (e) {
    saveError.value = '儲存失敗：' + (e.message || '請重試')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  const [elderRes, rulesRes] = await Promise.all([
    supabase.from('elders').select('*').eq('id', route.params.elderId).single(),
    fetch('/config/icope_rules.json').then(r => r.json())
  ])
  elder.value = elderRes.data
  rules.value = rulesRes
})
</script>
