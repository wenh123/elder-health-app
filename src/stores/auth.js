import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const session  = ref(null)
  const profile  = ref(null)   // users 資料表記錄
  const loading  = ref(true)

  const isLoggedIn = computed(() => !!session.value)
  const role       = computed(() => profile.value?.role || null)
  const siteId     = computed(() => profile.value?.site_id || null)
  const userName   = computed(() => profile.value?.name || session.value?.user?.email || '')

  const isAdmin    = computed(() => role.value === 'admin')
  const isManager  = computed(() => ['admin','manager'].includes(role.value))
  const canWrite   = computed(() => ['admin','instructor','caregiver'].includes(role.value))

  /** 初始化：從 Supabase 讀取目前 session */
  async function init() {
    loading.value = true
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    if (session.value) await fetchProfile()
    loading.value = false

    // 監聽 Auth 狀態變化
    supabase.auth.onAuthStateChange(async (_event, s) => {
      session.value = s
      if (s) {
        await fetchProfile()
      } else {
        profile.value = null
      }
    })
  }

  /** 讀取 users 資料表中的 profile */
  async function fetchProfile() {
    const { data } = await supabase
      .from('users')
      .select('*')
      .eq('id', session.value.user.id)
      .single()
    profile.value = data
  }

  /** 登入 */
  async function login(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    session.value = data.session
    await fetchProfile()
  }

  /** 登出 */
  async function logout() {
    await supabase.auth.signOut()
    session.value = null
    profile.value = null
  }

  return { session, profile, loading, isLoggedIn, role, siteId, userName,
           isAdmin, isManager, canWrite, init, login, logout, fetchProfile }
})
