import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 前端所有接口请求统一以 /admin/api 为前缀：
// - 开发环境：下方 proxy 把 /admin/api 剥离后转发到后端 http://127.0.0.1:8000
// - 生产环境：nginx 将 /admin/api 剥离后代理到后端，得到 /admin/login 等
export default defineConfig({
  plugins: [vue()],
  base: '/admin/',
  server: {
    host: '0.0.0.0',
    port: 5174,
    proxy: {
      '/admin/api': {
        target: 'http://127.0.0.1:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/admin\/api/, '')
      }
    }
  }
})
