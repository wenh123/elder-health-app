import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// base 設定說明：
//   GitHub Pages（子目錄）→ '/elder-health-app/'（已設為預設）
//   自訂網域根目錄       → 改為 '/'
export default defineConfig({
  plugins: [vue()],
  base: process.env.VITE_BASE_URL || '/elder-health-app/',
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  build: {
    outDir: 'dist'
  }
})
