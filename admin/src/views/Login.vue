<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-brand">
        <div class="brand-logo">
          <el-icon><Food /></el-icon>
        </div>
        <h1 class="brand-title">FitFood PK</h1>
        <p class="brand-sub">管理后台</p>
      </div>

      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        size="large"
        class="login-form"
        @submit.prevent="handleLogin"
      >
        <el-form-item prop="username">
          <el-input
            v-model="form.username"
            placeholder="请输入用户名"
            :prefix-icon="User"
            clearable
          />
        </el-form-item>
        <el-form-item prop="password">
          <el-input
            v-model="form.password"
            type="password"
            placeholder="请输入密码"
            :prefix-icon="Lock"
            show-password
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            class="login-btn"
            :loading="loading"
            @click="handleLogin"
          >
            登 录
          </el-button>
        </el-form-item>
      </el-form>

      <p class="login-tip">FitFood PK Admin Console</p>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const auth = useAuthStore()

const formRef = ref()
const loading = ref(false)

const form = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

const handleLogin = async () => {
  if (!formRef.value) return
  try {
    await formRef.value.validate()
  } catch (e) {
    return
  }

  loading.value = true
  try {
    await auth.login(form.username.trim(), form.password)
    ElMessage.success('登录成功')
    router.push({ name: 'Dashboard' })
  } catch (e) {
    // 错误信息已在 request 拦截器中提示
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #2f6b39 0%, #1f4d2a 60%, #143a1e 100%);
  position: relative;
  overflow: hidden;
}

.login-page::before,
.login-page::after {
  content: '';
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.06);
}

.login-page::before {
  width: 420px;
  height: 420px;
  top: -120px;
  right: -100px;
}

.login-page::after {
  width: 300px;
  height: 300px;
  bottom: -80px;
  left: -80px;
}

.login-card {
  width: 380px;
  background: #fff;
  border-radius: 16px;
  padding: 40px 36px 28px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
  z-index: 1;
}

.login-brand {
  text-align: center;
  margin-bottom: 28px;
}

.brand-logo {
  width: 60px;
  height: 60px;
  border-radius: 16px;
  background: linear-gradient(135deg, #5bc47e, #2f9e54);
  color: #fff;
  font-size: 32px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 12px;
}

.brand-title {
  font-size: 24px;
  font-weight: 700;
  color: #2f6b39;
  margin: 0;
}

.brand-sub {
  font-size: 13px;
  color: #909399;
  margin: 6px 0 0;
  letter-spacing: 2px;
}

.login-btn {
  width: 100%;
  background: var(--ff-primary);
  border-color: var(--ff-primary);
}

.login-btn:hover,
.login-btn:focus {
  background: var(--ff-primary-dark);
  border-color: var(--ff-primary-dark);
}

.login-tip {
  text-align: center;
  font-size: 12px;
  color: #c0c4cc;
  margin: 0;
}
</style>
