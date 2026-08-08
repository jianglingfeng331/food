<template>
  <div class="page-container">
    <div class="page-header">
      <h2 class="page-title">总览</h2>
      <p class="page-desc">平台核心运营数据概览</p>
    </div>

    <el-row :gutter="20" v-loading="loading">
      <el-col :xs="24" :sm="12" :lg="8" :xl="Math.ceil(24 / stats.length) || 8" v-for="(s, i) in stats" :key="i">
        <div class="stat-card">
          <div class="stat-icon" :class="s.bg">
            <el-icon><component :is="s.icon" /></el-icon>
          </div>
          <div class="stat-info">
            <div class="stat-value">{{ formatNum(s.value) }}</div>
            <div class="stat-label">{{ s.label }}</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <el-card class="overview-card" shadow="never" v-loading="loading">
      <template #header>
        <div class="card-header">
          <span>数据说明</span>
        </div>
      </template>
      <ul class="overview-list">
        <li><b>总用户数</b>：平台累计注册的用户数量。</li>
        <li><b>总贴纸数</b>：用户生成并保存的食物贴纸总数。</li>
        <li><b>总记录数</b>：所有用户产生健康记录（饮食/运动/饮水/体重）的总数。</li>
        <li><b>今日新增贴纸</b>：当天新生成的食物贴纸数量。</li>
        <li><b>今日记录数</b>：当天新增的健康记录数量。</li>
      </ul>
    </el-card>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import {
  User,
  Picture,
  Document,
  Calendar,
  TrendCharts
} from '@element-plus/icons-vue'
import request from '../utils/request'

const loading = ref(false)
const overview = ref({
  user_count: 0,
  sticker_count: 0,
  record_count: 0,
  today_stickers: 0,
  today_records: 0
})

const stats = ref([
  { label: '总用户数', value: 0, icon: 'User', bg: 'bg-blue' },
  { label: '总贴纸数', value: 0, icon: 'Picture', bg: 'bg-green' },
  { label: '总记录数', value: 0, icon: 'Document', bg: 'bg-orange' },
  { label: '今日新增贴纸', value: 0, icon: 'TrendCharts', bg: 'bg-purple' },
  { label: '今日记录数', value: 0, icon: 'Calendar', bg: 'bg-pink' }
])

const formatNum = (n) => {
  if (n === null || n === undefined) return 0
  return Number(n).toLocaleString('zh-CN')
}

const fetchOverview = async () => {
  loading.value = true
  try {
    const data = await request.get('/admin/overview')
    overview.value = {
      user_count: data.user_count ?? 0,
      sticker_count: data.sticker_count ?? 0,
      record_count: data.record_count ?? 0,
      today_stickers: data.today_stickers ?? 0,
      today_records: data.today_records ?? 0
    }
    stats.value[0].value = overview.value.user_count
    stats.value[1].value = overview.value.sticker_count
    stats.value[2].value = overview.value.record_count
    stats.value[3].value = overview.value.today_stickers
    stats.value[4].value = overview.value.today_records
  } catch (e) {
    /* 错误已提示 */
  } finally {
    loading.value = false
  }
}

onMounted(fetchOverview)
</script>

<style scoped>
.page-header {
  margin-bottom: 20px;
}

.page-title {
  margin: 0 0 4px;
  font-size: 22px;
  font-weight: 700;
  color: #303133;
}

.page-desc {
  margin: 0;
  font-size: 13px;
  color: #909399;
}

.overview-card {
  margin-top: 20px;
  border-radius: 10px;
}

.card-header {
  font-weight: 600;
}

.overview-list {
  margin: 0;
  padding-left: 18px;
  line-height: 2;
  color: #606266;
  font-size: 14px;
}

.overview-list b {
  color: #303133;
}
</style>
