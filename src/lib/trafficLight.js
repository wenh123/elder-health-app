/**
 * 紅綠燈判讀引擎
 * 規則來源：/public/config/icope_rules.json
 *
 * 使用方式：
 *   import { evaluate } from '@/lib/trafficLight'
 *   const result = evaluate(formData, rules, elder)
 */

/**
 * 取得長者年齡區間 key
 * @param {Date|string} birthDate
 * @returns {string}  e.g. '65-69'
 */
function getAgeGroup(birthDate) {
  const today = new Date()
  const birth = new Date(birthDate)
  const age = today.getFullYear() - birth.getFullYear()
  if (age < 60) return '60-64'
  if (age < 65) return '60-64'
  if (age < 70) return '65-69'
  if (age < 75) return '70-74'
  if (age < 80) return '75-79'
  return '80+'
}

/**
 * 評估所有面向，回傳紅燈旗標與風險等級
 *
 * @param {Object} form   - 表單資料（來自評估輸入）
 * @param {Object} rules  - icope_rules.json 內容
 * @param {Object} elder  - 長者基本資料（含 birth_date, gender）
 * @returns {Object}
 */
export function evaluate(form, rules, elder) {
  const flags = {}

  // ── 認知（BHT）────────────────────────────────────────────────
  const bhtTotal =
    (Number(form.bht_orientation)  || 0) +
    (Number(form.bht_registration) || 0) +
    (Number(form.bht_fluency)      || 0) +
    (Number(form.bht_recall)       || 0)

  flags.cognitive = bhtTotal < (rules.bht?.threshold ?? 12)

  // ── 行動能力 ──────────────────────────────────────────────────
  const ageGroup   = getAgeGroup(elder.birth_date)
  const genderKey  = elder.gender === 'M' ? 'male' : 'female'
  const chairMin   = rules.fitness?.chair_stand?.[genderKey]?.[ageGroup] ?? 10
  const stepMin    = rules.fitness?.step_march?.[genderKey]?.[ageGroup]  ?? 60

  const chairAbnormal = form.fitness_chair_stand !== '' &&
    Number(form.fitness_chair_stand) < chairMin
  const stepAbnormal  = form.fitness_step_march !== '' &&
    Number(form.fitness_step_march) < stepMin
  const icopeMobility = Boolean(form.icope_mobility)

  flags.mobility = chairAbnormal || stepAbnormal || icopeMobility

  // ── 營養 ──────────────────────────────────────────────────────
  flags.nutrition = Boolean(form.icope_nutrition1) || Boolean(form.icope_nutrition2)

  // ── 視力 ──────────────────────────────────────────────────────
  flags.vision = Boolean(form.icope_vision1)  // vision1=困難 才是紅燈

  // ── 聽力 ──────────────────────────────────────────────────────
  flags.hearing = Boolean(form.icope_hearing)

  // ── 憂鬱 ──────────────────────────────────────────────────────
  flags.depression = Boolean(form.icope_depression1) || Boolean(form.icope_depression2)

  // ── 風險等級 ──────────────────────────────────────────────────
  const redCount = Object.values(flags).filter(Boolean).length
  let riskLevel = 'low'
  if (redCount >= 3) riskLevel = 'high'
  else if (redCount >= 1) riskLevel = 'medium'

  return { flags, riskLevel, bhtTotal, redCount }
}

/** 風險等級中文 */
export const RISK_LABELS = {
  low:    { label: '低度風險', color: 'text-green-700', bg: 'bg-green-100' },
  medium: { label: '中度風險', color: 'text-yellow-700', bg: 'bg-yellow-100' },
  high:   { label: '高度風險', color: 'text-red-700',   bg: 'bg-red-100'   }
}

/** 面向顯示名稱 */
export const FLAG_LABELS = {
  cognitive:  '認知',
  mobility:   '行動',
  nutrition:  '營養',
  vision:     '視力',
  hearing:    '聽力',
  depression: '憂鬱'
}
