import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// IMPORTANT: 部署到 GitHub Pages 時，請將 base 改為你的倉庫名稱
// 例如：base: '/elder-health-app/'
// 若使用自訂網域則保持 base: '/'
export default defineConfig({
  plugins: [vue()],
  base: process.env.VITE_BASE_URL || '/',
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  build: {
    outDir: 'dist'
  }
})
