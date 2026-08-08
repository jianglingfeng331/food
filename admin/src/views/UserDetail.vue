<template>
  <div class="page-container">
    <!-- 顶部操作栏 -->
    <div class="detail-top">
      <el-button :icon="ArrowLeft" @click="$router.push('/users')">返回列表</el-button>
      <div class="spacer"></div>
      <el-button type="success" :icon="Download" :loading="exporting" @click="onExport">
        导出全量数据
      </el-button>
    </div>

    <el-row :gutter="20" v-loading="loading">
      <!-- 左侧：用户信息 -->
      <el-col :xs="24" :md="9" :lg="8">
        <el-card shadow="never" class="info-card">
          <template #header>
            <div class="card-title">
              <el-icon><User /></el-icon>
              <span>用户信息</span>
              <el-tag v-if="form.id" size="small" class="uid-tag">ID: {{ form.id }}</el-tag>
            </div>
          </template>

          <div class="avatar-area">
            <el-avatar :size="84" :src="avatarSrc" shape="square">
              <el-icon :size="36"><UserFilled /></el-icon>
            </el-avatar>
            <el-upload
              :show-file-list="false"
              :auto-upload="false"
              accept="image/*"
              :on-change="onAvatarChange"
            >
              <el-button size="small" :icon="Picture">更换头像</el-button>
            </el-upload>
            <el-button v-if="form.avatar_b64" size="small" link @click="form.avatar_b64 = ''">
              清除
            </el-button>
          </div>

          <el-form :model="form" label-width="92px" class="info-form" size="default">
            <el-form-item label="昵称">
              <el-input v-model="form.name" placeholder="昵称" />
            </el-form-item>
            <el-form-item label="手机号">
              <el-input v-model="form.phone" placeholder="手机号" />
            </el-form-item>
            <el-row :gutter="10">
              <el-col :span="12">
                <el-form-item label="当前体重">
                  <el-input v-model="form.current_weight" placeholder="kg">
                    <template #append>kg</template>
                  </el-input>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="目标体重">
                  <el-input v-model="form.target_weight" placeholder="kg">
                    <template #append>kg</template>
                  </el-input>
                </el-form-item>
              </el-col>
            </el-row>
            <el-form-item label="身高">
              <el-input v-model="form.height" placeholder="cm">
                <template #append>cm</template>
              </el-input>
            </el-form-item>
            <el-form-item label="用户名">
              <el-input :model-value="form.username" disabled />
            </el-form-item>
            <el-form-item label="注册时间">
              <el-input :model-value="formatTime(form.created_at)" disabled />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="saving" :icon="Check" @click="onSaveInfo">
                保存修改
              </el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <!-- PK 绑定 -->
        <el-card shadow="never" class="info-card">
          <template #header>
            <div class="card-title">
              <el-icon><Connection /></el-icon>
              <span>PK 绑定</span>
            </div>
          </template>
          <div v-if="binding.partner_id" class="binding-info">
            <el-avatar :size="36" :src="partnerAvatar">
              <el-icon><UserFilled /></el-icon>
            </el-avatar>
            <div class="binding-meta">
              <div class="binding-name">{{ binding.partner_name || 'PK 伙伴' }}</div>
              <div class="binding-sub">ID: {{ binding.partner_id }}</div>
              <div class="binding-sub">绑定于 {{ formatTime(binding.bound_at) }}</div>
            </div>
          </div>
          <el-empty v-else description="未绑定 PK 伙伴" :image-size="60" />
          <div v-if="binding.partner_id" class="binding-actions">
            <el-button type="danger" plain :icon="Switch" :loading="unbinding" @click="onUnbind">
              解除绑定
            </el-button>
          </div>
        </el-card>
      </el-col>

      <!-- 右侧：健康数据 -->
      <el-col :xs="24" :md="15" :lg="16">
        <el-card shadow="never" class="info-card">
          <template #header>
            <div class="card-title">
              <el-icon><Document /></el-icon>
              <span>健康数据</span>
            </div>
          </template>

          <div class="page-toolbar">
            <el-select v-model="recordType" placeholder="记录类型" style="width: 140px" @change="onRecordSearch">
              <el-option label="全部" value="" />
              <el-option label="饮食" value="food" />
              <el-option label="运动" value="exercise" />
              <el-option label="饮水" value="water" />
              <el-option label="体重" value="weight" />
            </el-select>
            <div class="spacer"></div>
            <el-button type="primary" :icon="Plus" @click="openRecordDialog()">新增记录</el-button>
          </div>

          <el-table :data="records" stripe v-loading="recordLoading" row-key="id">
            <el-table-column type="expand">
              <template #default="{ row }">
                <div class="nutrition-detail">
                  <el-descriptions :column="4" border size="small">
                    <el-descriptions-item label="蛋白质">
                      {{ fmtNum(row.protein_g) }} g
                    </el-descriptions-item>
                    <el-descriptions-item label="碳水">
                      {{ fmtNum(row.carb_g) }} g
                    </el-descriptions-item>
                    <el-descriptions-item label="脂肪">
                      {{ fmtNum(row.fat_g) }} g
                    </el-descriptions-item>
                    <el-descriptions-item label="膳食纤维">
                      {{ fmtNum(row.dietary_fiber_g) }} g
                    </el-descriptions-item>
                    <el-descriptions-item label="糖">
                      {{ fmtNum(row.sugar_g) }} g
                    </el-descriptions-item>
                    <el-descriptions-item label="钠">
                      {{ fmtNum(row.sodium_mg) }} mg
                    </el-descriptions-item>
                    <el-descriptions-item label="健康小贴士" :span="2">
                      {{ row.vitamin_tips || '-' }}
                    </el-descriptions-item>
                    <el-descriptions-item label="图片" :span="2">
                      <el-image
                        v-if="row.image_path || row.image_b64"
                        :src="recordImage(row)"
                        class="record-img"
                        :preview-src-list="[recordImage(row)]"
                        :z-index="99999"
                        preview-teleported
                        fit="cover"
                        hide-on-click-modal
                      />
                      <span v-else class="muted">无</span>
                    </el-descriptions-item>
                  </el-descriptions>
                </div>
              </template>
            </el-table-column>
            <el-table-column label="类型" width="90">
              <template #default="{ row }">
                <el-tag :type="typeTag(row.type)" effect="light" size="small">
                  {{ typeLabel(row.type) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="name" label="名称" min-width="130" />
            <el-table-column label="热量" width="100" align="center">
              <template #default="{ row }">
                {{ row.calories != null ? row.calories + ' kcal' : '-' }}
              </template>
            </el-table-column>
            <el-table-column label="数量" width="120">
              <template #default="{ row }">
                {{ row.amount != null ? row.amount : '-' }}
                {{ row.unit || '' }}
              </template>
            </el-table-column>
            <el-table-column label="时间" width="160">
              <template #default="{ row }">{{ formatTime(row.time) }}</template>
            </el-table-column>
            <el-table-column label="创建时间" width="160">
              <template #default="{ row }">{{ formatTime(row.created_at) }}</template>
            </el-table-column>
            <el-table-column label="操作" width="140" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" :icon="Edit" @click="openRecordDialog(row)">编辑</el-button>
                <el-button link type="danger" :icon="Delete" @click="onDeleteRecord(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>

          <div class="pager">
            <el-pagination
              v-model:current-page="recordPage"
              v-model:page-size="recordSize"
              :total="recordTotal"
              :page-sizes="[20, 50, 100]"
              layout="total, sizes, prev, pager, next, jumper"
              background
              @size-change="fetchRecords"
              @current-change="fetchRecords"
            />
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 新增/编辑记录 弹窗 -->
    <el-dialog
      v-model="recordDialog.visible"
      :title="recordDialog.isEdit ? '编辑记录' : '新增记录'"
      width="520px"
      destroy-on-close
    >
      <el-form :model="recordDialog.form" label-width="84px">
        <el-form-item label="类型" required>
          <el-select v-model="recordDialog.form.type" placeholder="选择类型" style="width: 100%">
            <el-option label="饮食" value="food" />
            <el-option label="运动" value="exercise" />
            <el-option label="饮水" value="water" />
            <el-option label="体重" value="weight" />
          </el-select>
        </el-form-item>
        <el-form-item label="名称" required>
          <el-input v-model="recordDialog.form.name" placeholder="如：苹果 / 跑步" />
        </el-form-item>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="热量">
              <el-input v-model="recordDialog.form.calories" placeholder="kcal">
                <template #append>kcal</template>
              </el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="时间">
              <el-date-picker
                v-model="recordDialog.form.time"
                type="datetime"
                placeholder="选择时间"
                value-format="YYYY-MM-DDTHH:mm:ss"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="数量">
              <el-input v-model="recordDialog.form.amount" placeholder="数量" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="单位">
              <el-input v-model="recordDialog.form.unit" placeholder="g / ml / 分钟" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-divider content-position="left">营养成分</el-divider>
        <el-row :gutter="10">
          <el-col :span="8">
            <el-form-item label="蛋白质">
              <el-input v-model="recordDialog.form.protein_g"><template #append>g</template></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="碳水">
              <el-input v-model="recordDialog.form.carb_g"><template #append>g</template></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="脂肪">
              <el-input v-model="recordDialog.form.fat_g"><template #append>g</template></el-input>
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button @click="recordDialog.visible = false">取消</el-button>
        <el-button type="primary" :loading="recordDialog.saving" @click="onSaveRecord">
          保存
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  ArrowLeft,
  Download,
  User,
  UserFilled,
  Picture,
  Check,
  Connection,
  Switch,
  Document,
  Plus,
  Edit,
  Delete
} from '@element-plus/icons-vue'
import request from '../utils/request'

const route = useRoute()
const uid = computed(() => route.params.id)

const loading = ref(false)
const saving = ref(false)
const exporting = ref(false)
const unbinding = ref(false)

const form = reactive({
  id: '',
  name: '',
  phone: '',
  username: '',
  current_weight: '',
  target_weight: '',
  height: '',
  avatar_b64: '',
  created_at: ''
})

const binding = reactive({
  partner_id: null,
  partner_name: '',
  bound_at: '',
  partner_avatar_b64: ''
})

const avatarSrc = computed(() => {
  const b64 = form.avatar_b64
  if (b64) return b64.startsWith('data:') ? b64 : `data:image/png;base64,${b64}`
  return ''
})
const partnerAvatar = computed(() => {
  const b64 = binding.partner_avatar_b64
  if (b64) return b64.startsWith('data:') ? b64 : `data:image/png;base64,${b64}`
  return ''
})

const formatTime = (t) => {
  if (!t) return '-'
  const d = new Date(t)
  if (isNaN(d.getTime())) return t
  const pad = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(
    d.getHours()
  )}:${pad(d.getMinutes())}`
}
const fmtNum = (n) => (n === null || n === undefined || n === '' ? '-' : n)

const TYPE_MAP = {
  food: { label: '饮食', tag: 'success' },
  exercise: { label: '运动', tag: 'warning' },
  water: { label: '饮水', tag: 'primary' },
  weight: { label: '体重', tag: 'info' }
}
const typeLabel = (t) => TYPE_MAP[t]?.label || t || '-'
const typeTag = (t) => TYPE_MAP[t]?.tag || ''

const recordImage = (row) => {
  const b64 = row.image_b64
  if (b64) return b64.startsWith('data:') ? b64 : `data:image/png;base64,${b64}`
  return row.image_path || ''
}

const fetchUser = async () => {
  loading.value = true
  try {
    const data = await request.get(`/admin/users/${uid.value}`)
    Object.assign(form, {
      id: data.id,
      name: data.name ?? '',
      phone: data.phone ?? '',
      username: data.username ?? '',
      current_weight: data.current_weight ?? '',
      target_weight: data.target_weight ?? '',
      height: data.height ?? '',
      avatar_b64: data.avatar_b64 ?? '',
      created_at: data.created_at ?? ''
    })
    binding.partner_id = data.partner_id ?? null
    binding.partner_name = data.partner_name ?? ''
  } catch (e) {
    /* 已提示 */
  } finally {
    loading.value = false
  }
}

const fetchBinding = async () => {
  try {
    const data = await request.get(`/admin/users/${uid.value}/binding`)
    binding.partner_id = data.partner_id ?? null
    binding.partner_name = data.partner_name ?? ''
    binding.bound_at = data.bound_at ?? ''
    binding.partner_avatar_b64 = data.partner_avatar_b64 ?? ''
  } catch (e) {
    /* 已提示 */
  }
}

const onAvatarChange = (file) => {
  const raw = file.raw
  if (!raw) return
  if (raw.size > 5 * 1024 * 1024) {
    ElMessage.warning('图片不能超过 5MB')
    return
  }
  const reader = new FileReader()
  reader.onload = (e) => {
    form.avatar_b64 = e.target.result
  }
  reader.readAsDataURL(raw)
}

const onSaveInfo = async () => {
  saving.value = true
  try {
    await request.put(`/admin/users/${uid.value}`, {
      name: form.name,
      phone: form.phone,
      current_weight: form.current_weight,
      target_weight: form.target_weight,
      height: form.height,
      avatar_b64: form.avatar_b64
    })
    ElMessage.success('保存成功')
  } catch (e) {
    /* 已提示 */
  } finally {
    saving.value = false
  }
}

const onUnbind = async () => {
  try {
    await ElMessageBox.confirm(
      `确定要解除与「${binding.partner_name || 'PK 伙伴'}」的绑定吗？`,
      '解绑确认',
      { confirmButtonText: '解绑', cancelButtonText: '取消', type: 'warning' }
    )
    unbinding.value = true
    await request.post(`/admin/users/${uid.value}/unbind`)
    ElMessage.success('已解除绑定')
    binding.partner_id = null
    binding.partner_name = ''
    binding.bound_at = ''
  } catch (e) {
    /* 已提示 */
  } finally {
    unbinding.value = false
  }
}

const onExport = async () => {
  exporting.value = true
  try {
    // 通过 axios 直接拿 blob
    const axios = (await import('axios')).default
    const token = localStorage.getItem('admin_token')
    const resp = await axios.get(`/admin/api/admin/export/users/${uid.value}`, {
      responseType: 'blob',
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
    const blob = new Blob([resp.data], { type: 'application/json;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `user_${form.id || uid.value}_${Date.now()}.json`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    ElMessage.success('导出成功')
  } catch (e) {
    ElMessage.error('导出失败')
  } finally {
    exporting.value = false
  }
}

/* ---- 健康记录 ---- */
const records = ref([])
const recordTotal = ref(0)
const recordLoading = ref(false)
const recordType = ref('')
const recordPage = ref(1)
const recordSize = ref(20)

const fetchRecords = async () => {
  recordLoading.value = true
  try {
    const data = await request.get(`/admin/users/${uid.value}/records`, {
      params: {
        page: recordPage.value,
        size: recordSize.value,
        type: recordType.value || undefined
      }
    })
    records.value = data.items || []
    recordTotal.value = data.total || 0
  } catch (e) {
    /* 已提示 */
  } finally {
    recordLoading.value = false
  }
}

const onRecordSearch = () => {
  recordPage.value = 1
  fetchRecords()
}

const recordDialog = reactive({
  visible: false,
  isEdit: false,
  saving: false,
  rid: null,
  form: {
    type: 'food',
    name: '',
    calories: '',
    amount: '',
    unit: '',
    time: '',
    protein_g: '',
    carb_g: '',
    fat_g: ''
  }
})

const openRecordDialog = (row) => {
  recordDialog.isEdit = !!row
  recordDialog.rid = row ? row.id : null
  recordDialog.form = {
    type: row?.type || 'food',
    name: row?.name ?? '',
    calories: row?.calories ?? '',
    amount: row?.amount ?? '',
    unit: row?.unit ?? '',
    time: row?.time ? toLocalInput(row.time) : toLocalInput(new Date()),
    protein_g: row?.protein_g ?? '',
    carb_g: row?.carb_g ?? '',
    fat_g: row?.fat_g ?? ''
  }
  recordDialog.visible = true
}

const toLocalInput = (d) => {
  const date = new Date(d)
  if (isNaN(date.getTime())) return ''
  const pad = (n) => String(n).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(
    date.getHours()
  )}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
}

const onSaveRecord = async () => {
  if (!recordDialog.form.name) {
    ElMessage.warning('请填写名称')
    return
  }
  recordDialog.saving = true
  try {
    const payload = {
      type: recordDialog.form.type,
      name: recordDialog.form.name,
      calories: toNumOrUndef(recordDialog.form.calories),
      amount: toNumOrUndef(recordDialog.form.amount),
      unit: recordDialog.form.unit,
      time: recordDialog.form.time,
      protein_g: toNumOrUndef(recordDialog.form.protein_g),
      carb_g: toNumOrUndef(recordDialog.form.carb_g),
      fat_g: toNumOrUndef(recordDialog.form.fat_g)
    }
    if (recordDialog.isEdit) {
      await request.put(`/admin/records/${recordDialog.rid}`, payload)
      ElMessage.success('修改成功')
    } else {
      await request.post(`/admin/users/${uid.value}/records`, payload)
      ElMessage.success('新增成功')
    }
    recordDialog.visible = false
    fetchRecords()
  } catch (e) {
    /* 已提示 */
  } finally {
    recordDialog.saving = false
  }
}

const toNumOrUndef = (v) => {
  if (v === '' || v === null || v === undefined) return undefined
  const n = Number(v)
  return isNaN(n) ? v : n
}

const onDeleteRecord = async (row) => {
  try {
    await ElMessageBox.confirm(`确定要删除记录「${row.name}」吗？`, '删除确认', {
      confirmButtonText: '删除',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await request.delete(`/admin/records/${row.id}`)
    ElMessage.success('删除成功')
    if (records.value.length === 1 && recordPage.value > 1) recordPage.value--
    fetchRecords()
  } catch (e) {
    /* 已提示 */
  }
}

onMounted(async () => {
  await fetchUser()
  fetchBinding()
  fetchRecords()
})
</script>

<style scoped>
.detail-top {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}
.spacer {
  flex: 1;
}
.info-card {
  border-radius: 10px;
  margin-bottom: 20px;
}
.card-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
}
.uid-tag {
  margin-left: auto;
}
.avatar-area {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 18px;
}
.info-form :deep(.el-form-item) {
  margin-bottom: 14px;
}
.binding-info {
  display: flex;
  align-items: center;
  gap: 12px;
}
.binding-meta {
  line-height: 1.5;
}
.binding-name {
  font-weight: 600;
}
.binding-sub {
  font-size: 12px;
  color: #909399;
}
.binding-actions {
  margin-top: 14px;
}
.nutrition-detail {
  padding: 8px 16px;
}
.record-img {
  width: 64px;
  height: 64px;
  border-radius: 6px;
}
.muted {
  color: #c0c4cc;
}
.pager {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
</style>
