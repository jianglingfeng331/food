<template>
  <div class="page-container">
    <div class="page-header">
      <h2 class="page-title">用户管理</h2>
      <p class="page-desc">管理平台所有用户信息</p>
    </div>

    <div class="page-toolbar">
      <el-input
        v-model="keyword"
        placeholder="搜索 手机号 / 昵称 / 用户名"
        clearable
        style="width: 280px"
        :prefix-icon="Search"
        @keyup.enter="onSearch"
        @clear="onSearch"
      />
      <el-button type="primary" :icon="Search" @click="onSearch">搜索</el-button>
      <el-button :icon="Refresh" @click="onReset">重置</el-button>
      <div class="spacer"></div>
      <span class="total-text">共 {{ total }} 位用户</span>
    </div>

    <el-card shadow="never" class="table-card">
      <el-table
        v-loading="loading"
        :data="list"
        stripe
        style="width: 100%"
        :default-sort="{ prop: 'created_at', order: 'descending' }"
      >
        <el-table-column label="用户" min-width="200">
          <template #default="{ row }">
            <div class="user-cell">
              <el-avatar :size="40" :src="avatarOf(row)">
                <el-icon><UserFilled /></el-icon>
              </el-avatar>
              <div class="user-meta">
                <div class="user-name">{{ row.name || row.username || '-' }}</div>
                <div class="user-sub">@{{ row.username || '-' }}</div>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="phone" label="手机号" width="140">
          <template #default="{ row }">{{ row.phone || '-' }}</template>
        </el-table-column>
        <el-table-column label="当前体重" width="100" align="center">
          <template #default="{ row }">
            {{ row.current_weight != null ? row.current_weight + ' kg' : '-' }}
          </template>
        </el-table-column>
        <el-table-column label="目标体重" width="100" align="center">
          <template #default="{ row }">
            {{ row.target_weight != null ? row.target_weight + ' kg' : '-' }}
          </template>
        </el-table-column>
        <el-table-column label="身高" width="90" align="center">
          <template #default="{ row }">
            {{ row.height != null ? row.height + ' cm' : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="record_count" label="记录数" width="90" align="center" />
        <el-table-column prop="sticker_count" label="贴纸数" width="90" align="center" />
        <el-table-column label="PK 伙伴" width="130">
          <template #default="{ row }">
            <el-tag v-if="row.partner_name" type="success" size="small">
              {{ row.partner_name }}
            </el-tag>
            <span v-else class="muted">未绑定</span>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="注册时间" width="170" sortable>
          <template #default="{ row }">{{ formatTime(row.created_at) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" :icon="View" @click="goDetail(row)">
              详情
            </el-button>
            <el-button link type="danger" :icon="Delete" @click="onDelete(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="size"
          :page-sizes="[20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          background
          @size-change="fetchList"
          @current-change="fetchList"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Search,
  Refresh,
  View,
  Delete,
  UserFilled
} from '@element-plus/icons-vue'
import request from '../utils/request'

const router = useRouter()

const list = ref([])
const total = ref(0)
const loading = ref(false)
const keyword = ref('')
const page = ref(1)
const size = ref(20)

const avatarOf = (row) => {
  const b64 = row.avatar_b64
  if (b64) return b64.startsWith('data:') ? b64 : `data:image/png;base64,${b64}`
  return row.avatar || ''
}

const formatTime = (t) => {
  if (!t) return '-'
  const d = new Date(t)
  if (isNaN(d.getTime())) return t
  const pad = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(
    d.getHours()
  )}:${pad(d.getMinutes())}`
}

const fetchList = async () => {
  loading.value = true
  try {
    const data = await request.get('/admin/users', {
      params: { page: page.value, size: size.value, keyword: keyword.value || undefined }
    })
    list.value = data.items || []
    total.value = data.total || 0
  } catch (e) {
    /* 已提示 */
  } finally {
    loading.value = false
  }
}

const onSearch = () => {
  page.value = 1
  fetchList()
}

const onReset = () => {
  keyword.value = ''
  page.value = 1
  fetchList()
}

const goDetail = (row) => {
  router.push({ name: 'UserDetail', params: { id: row.id } })
}

const onDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除用户「${row.name || row.username || row.id}」吗？该操作不可恢复。`,
      '删除确认',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' }
    )
    await request.delete(`/admin/users/${row.id}`)
    ElMessage.success('删除成功')
    if (list.value.length === 1 && page.value > 1) page.value--
    fetchList()
  } catch (e) {
    /* 取消或已提示 */
  }
}

onMounted(fetchList)
</script>

<style scoped>
.page-header {
  margin-bottom: 20px;
}

.page-title {
  margin: 0 0 4px;
  font-size: 22px;
  font-weight: 700;
}

.page-desc {
  margin: 0;
  font-size: 13px;
  color: #909399;
}

.table-card {
  border-radius: 10px;
}

.user-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.user-meta {
  line-height: 1.3;
}

.user-name {
  font-weight: 600;
  color: #303133;
}

.user-sub {
  font-size: 12px;
  color: #909399;
}

.muted {
  color: #c0c4cc;
  font-size: 13px;
}

.total-text {
  color: #909399;
  font-size: 13px;
}

.pager {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
</style>
