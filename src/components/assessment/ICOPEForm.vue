<template>
  <div class="space-y-5">
    <div class="bg-purple-50 border border-purple-200 rounded-lg px-4 py-3 text-sm text-purple-800">
      <strong>ICOPE 長者功能整合評估</strong>：若有一項為「是」，請勾選並觸發紅燈
    </div>

    <div class="space-y-5">
      <div v-for="section in sections" :key="section.key" class="border border-gray-100 rounded-xl p-4">
        <h3 class="text-sm font-semibold text-gray-800 mb-3 flex items-center gap-2">
          <span>{{ section.icon }}</span>
          <span>{{ section.label }}</span>
        </h3>
        <div class="space-y-3">
          <label
            v-for="q in section.questions"
            :key="q.key"
            class="flex items-start gap-3 cursor-pointer"
          >
            <input
              type="checkbox"
              :checked="modelValue[q.key]"
              @change="update(q.key, $event.target.checked)"
              class="mt-0.5 h-4 w-4 text-blue-600 rounded"
            />
            <div>
              <span class="text-sm text-gray-700">{{ q.label }}</span>
            </div>
          </label>
        </div>
      </div>
    </div>

    <!-- 指導員記錄 -->
    <div>
      <label class="form-label">指導員備註</label>
      <textarea
        :value="modelValue.notes"
        @input="update('notes', $event.target.value)"
        rows="3"
        class="form-input"
        placeholder="其他觀察或補充說明..."
      ></textarea>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  modelValue: { type: Object, required: true }
})
const emit = defineEmits(['update:modelValue'])

const sections = [
  {
    key: 'nutrition',
    icon: '🥗',
    label: '2. 營養不良',
    questions: [
      { key: 'icope_nutrition1', label: '在非刻意減重下，過去三個月體重是否減輕 3 公斤以上？' },
      { key: 'icope_nutrition2', label: '過去三個月，您是否曾經食慾不好？' }
    ]
  },
  {
    key: 'vision',
    icon: '👁️',
    label: '3. 視力障礙',
    questions: [
      { key: 'icope_vision1', label: '您的眼睛看遠、看近或閱讀是否有困難？' },
      { key: 'icope_vision2', label: '過去 1 年是否曾接受眼睛檢查？（是＝正常，否＝注意）' }
    ]
  },
  {
    key: 'hearing',
    icon: '👂',
    label: '4. 聽力障礙',
    questions: [
      { key: 'icope_hearing', label: '電話聽不清楚、電視音量開太大聲、交談需對方提高音量或不想參加聚會？' }
    ]
  },
  {
    key: 'depression',
    icon: '💙',
    label: '5. 憂鬱情緒',
    questions: [
      { key: 'icope_depression1', label: '過去兩週，您是否常感到厭煩（心煩）或覺得生活沒有希望？' },
      { key: 'icope_depression2', label: '過去兩週，您是否減少很多原本感興趣的事？' }
    ]
  }
]

function update(key, val) {
  emit('update:modelValue', { ...props.modelValue, [key]: val })
}
</script>
