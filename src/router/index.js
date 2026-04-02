import { createRouter, createWebHashHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// 使用 Hash 模式：URL 格式為 /#/elders，不需 GitHub Pages 額外設定
const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    // ── 公開頁面 ────────────────────────────────────────────────
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { public: true }
    },

    // ── 需要登入 ─────────────────────────────────────────────────
    {
      path: '/',
      redirect: '/elders'
    },
    {
      path: '/elders',
      name: 'elders',
      component: () => import('@/views/EldersView.vue'),
      meta: { title: '長者清單' }
    },
    {
      path: '/elders/:id',
      name: 'elder-detail',
      component: () => import('@/views/ElderDetailView.vue'),
      meta: { title: '長者資料' }
    },
    {
      path: '/assessments/new/:elderId',
      name: 'assessment-new',
      component: () => import('@/views/AssessmentNewView.vue'),
      meta: { title: '新增評估' }
    },
    {
      path: '/assessments/:id/result',
      name: 'assessment-result',
      component: () => import('@/views/AssessmentResultView.vue'),
      meta: { title: '評估結果' }
    },

    // 404
    {
      path: '/:pathMatch(.*)*',
      redirect: '/elders'
    }
  ]
})

// ── 導航守衛：未登入跳轉至登入頁 ──────────────────────────────────
router.beforeEach(async (to) => {
  const auth = useAuthStore()

  // 等待 auth 初始化完成
  if (auth.loading) {
    await new Promise(resolve => {
      const stop = auth.$subscribe(() => {
        if (!auth.loading) { stop(); resolve() }
      })
      setTimeout(() => { stop(); resolve() }, 3000) // 最多等 3 秒
    })
  }

  if (!to.meta.public && !auth.isLoggedIn) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (to.name === 'login' && auth.isLoggedIn) {
    return { name: 'elders' }
  }
})

export default router
