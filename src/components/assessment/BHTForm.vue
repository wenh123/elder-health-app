<template>
  <div class="space-y-5">
    <div class="bg-blue-50 border border-blue-200 rounded-lg px-4 py-3 text-sm text-blue-800">
      <strong>BHT 認知量表</strong>：請依據施測結果輸入各子題分數
    </div>

    <div class="grid sm:grid-cols-2 gap-4">
      <div v-for="item in items" :key="item.key">
        <label class="form-label">
          {{ item.label }}
          <span class="text-gray-400 font-normal ml-1">（滿分 {{ item.max }} 分）</span>
        </label>
        <div class="flex items-center gap-2">
          <input
            type="number"
            :min="0"
            :max="item.max"
            :value="modelValue[item.key]"
            @input="update(item.key, $event.target.value)"
            class="form-input w-24"
            placeholder="0"
          />
          <span class="text-sm text-gray-400">/ {{ item.max }}</span>
        </div>
        <p class="mt-1 text-xs text-gray-500">{{ item.desc }}</p>
      </div>
    </div>

    <!-- BHT 總分即時預覽 -->
    <div class="flex items-center gap-3 pt-2 border-t border-gray-100">
      <span class="text-sm font-medium text-gray-700">BHT 總分：</span>
      <span class="text-2xl font-bold" :class="total < threshold ? 'text-red-600' : 'text-green-600'">
        {{ total }}
      </span>
      <span class="text-sm text-gray-400">/ 16</span>
      <span
        class="ml-2"
        :class="total < threshold ? 'badge-red' : 'badge-green'"
      >
        {{ total < threshold ? '🔴 認知異常' : '🟢 正常' }}
      </span>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: { type: Object, required: true },
  threshold:  { type: Number, default: 12 }
})
const emit = defineEmits(['update:modelValue'])

const items = [
  { key: 'bht_orientation',  label: '定向力',  max: 4, desc: '詢問：今天年、月、日、星期' },
  { key: 'bht_registration', label: '訊息登錄', max: 5, desc: '重述五個字詞' },
  { key: 'bht_fluency',      label: '思考流暢', max: 2, desc: '一分鐘內說出四隻腳動物（≥6 種得2分）' },
  { key: 'bht_recall',       label: '訊息回應', max: 5, desc: '回想剛才重述的五個字詞' }
]

const total = computed(() => {
  return items.reduce((sum, item) => sum + (Number(props.modelValue[item.key]) || 0), 0)
})

function update(key, val) {
  emit('update:modelValue', { ...props.modelValue, [key]: val })
}
</script>
