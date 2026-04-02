<template>
  <div class="space-y-5">
    <div class="bg-green-50 border border-green-200 rounded-lg px-4 py-3 text-sm text-green-800">
      <strong>體適能功能檢測</strong>：請輸入實測次數，若未施測請留空
    </div>

    <div class="space-y-4">
      <div v-for="item in items" :key="item.key">
        <label class="form-label">{{ item.label }}</label>
        <div class="flex items-center gap-2">
          <input
            type="number"
            min="0"
            :value="modelValue[item.key]"
            @input="update(item.key, $event.target.value)"
            class="form-input w-28"
            :placeholder="item.placeholder"
          />
          <span class="text-sm text-gray-400">次</span>
        </div>
        <p class="mt-1 text-xs text-gray-500">{{ item.desc }}</p>
      </div>
    </div>

    <!-- 行動能力 ICOPE 篩檢補充 -->
    <div class="pt-3 border-t border-gray-100">
      <label class="flex items-start gap-3 cursor-pointer">
        <input
          type="checkbox"
          :checked="modelValue.icope_mobility"
          @change="update('icope_mobility', $event.target.checked)"
          class="mt-0.5 h-4 w-4 text-blue-600 rounded"
        />
        <div>
          <span class="text-sm font-medium text-gray-700">ICOPE 行動能力異常</span>
          <p class="text-xs text-gray-500 mt-0.5">
            擔心跌倒、一年內曾跌倒，或起床/起站需要抓握東西
          </p>
        </div>
      </label>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  modelValue: { type: Object, required: true }
})
const emit = defineEmits(['update:modelValue'])

const items = [
  {
    key: 'fitness_chair_stand',
    label: '30 秒椅子坐站（次）',
    placeholder: '輸入次數',
    desc: '從坐姿起立至完全站立，計算 30 秒內完成次數'
  },
  {
    key: 'fitness_bicep_curl',
    label: '30 秒肱二頭肌屈舉（次）',
    placeholder: '輸入次數',
    desc: '手持啞鈴（男 8 磅 / 女 5 磅），計算 30 秒內完成次數'
  },
  {
    key: 'fitness_step_march',
    label: '2 分鐘原地站立抬膝（次）',
    placeholder: '輸入次數',
    desc: '原地抬膝至髕骨與髂前上棘中點高度，計算 2 分鐘內右膝抬起次數'
  }
]

function update(key, val) {
  emit('update:modelValue', { ...props.modelValue, [key]: val })
}
</script>
