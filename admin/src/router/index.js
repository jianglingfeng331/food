import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { title: '登录' }
  },
  {
    path: '/',
    component: () => import('../layouts/AdminLayout.vue'),
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('../views/Dashboard.vue'),
        meta: { title: '总览' }
      },
      {
        path: 'users',
        name: 'Users',
        component: () => import('../views/Users.vue'),
        meta: { title: '用户管理' }
      },
      {
        path: 'users/:id',
        name: 'UserDetail',
        component: () => import('../views/UserDetail.vue'),
        meta: { title: '用户详情' }
      },
      {
        path: 'stickers',
        name: 'Stickers',
        component: () => import('../views/Stickers.vue'),
        meta: { title: '贴纸管理' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory('/admin/'),
  routes
})

router.beforeEach((to, from, next) => {
  const auth = useAuthStore()
  document.title = to.meta.title
    ? `${to.meta.title} · FitFood PK 管理后台`
    : 'FitFood PK 管理后台'

  if (to.name !== 'Login' && !auth.isLoggedIn) {
    next({ name: 'Login' })
  } else if (to.name === 'Login' && auth.isLoggedIn) {
    next({ name: 'Dashboard' })
  } else {
    next()
  }
})

export default router
