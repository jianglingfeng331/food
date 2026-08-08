import { defineStore } from 'pinia'
import request from '../utils/request'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('admin_token') || ''
  }),
  getters: {
    isLoggedIn: (state) => !!state.token
  },
  actions: {
    async login(username, password) {
      const data = await request.post('/admin/login', { username, password })
      const token = data.token || data.access_token
      this.token = token
      localStorage.setItem('admin_token', token)
      return token
    },
    logout() {
      this.token = ''
      localStorage.removeItem('admin_token')
    }
  }
})
