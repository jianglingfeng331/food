import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '../router'

// baseURL: '/admin/api'
// - 开发：vite proxy 将 /admin/api 剥离转发到 http://127.0.0.1:8000
// - 生产：nginx 将 /admin/api 剥离转发到后端，得到 /admin/xxx
const request = axios.create({
  baseURL: '/admin/api',
  timeout: 30000
})

// 请求拦截器：自动携带 Token
request.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('admin_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 响应拦截器：统一处理错误，401 跳转登录
request.interceptors.response.use(
  (response) => response.data,
  (error) => {
    const status = error.response?.status
    const data = error.response?.data
    const message =
      data?.detail || data?.message || data?.msg || error.message || '请求失败'

    if (status === 401) {
      localStorage.removeItem('admin_token')
      ElMessage.error('登录已过期，请重新登录')
      if (router.currentRoute.value.name !== 'Login') {
        router.push({ name: 'Login' })
      }
    } else {
      ElMessage.error(message)
    }
    return Promise.reject(error)
  }
)

export default request
