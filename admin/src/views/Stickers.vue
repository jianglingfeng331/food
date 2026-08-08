<template>
  <div class="page-container">
    <div class="page-header">
      <h2 class="page-title">贴纸管理</h2>
      <p class="page-desc">管理用户生成的食物贴纸及其营养信息</p>
    </div>

    <div class="page-toolbar">
      <el-input
        v-model="keyword"
        placeholder="搜索 贴纸名 / 用户名"
        clearable
        style="width: 240px"
        :prefix-icon="Search"
        @keyup.enter="onSearch"
        @clear="onSearch"
      />
      <el-input
        v-model="userId"
        placeholder="按用户 ID 筛选"
        clearable
        style="width: 160px"
        :prefix-icon="User"
        @keyup.enter="onSearch"
        @clear="onSearch"
      />
      <el-button type="primary" :icon="Search" @click="onSearch">搜索</el-button>
      <el-button :icon="Refresh" @click="onReset">重置</el-button>
      <div class="spacer"></div>
      <span class="total-text">共 {{ total }} 张贴纸</span>
    </div>

    <el-card shadow="never" class="table-card">
      <el-table :data="list" stripe v-loading="loading" style="width: 100%">
        <el-table-column label="贴纸" min-width="180">
          <template #default="{ row }">
            <div class="sticker-cell">
              <el-image
                :src="stickerImage(row)"
                class="sticker-thumb"
                fit="cover"
                :preview-src-list="stickerImage(row) ? [stickerImage(row)] : []"
                :z-index="99999"
                preview-teleported
                hide-on-click-modal
              >
                <template #error>
                  <div class="thumb-fallback"><el-icon><Picture /></el-icon></div>
                </template>
                <template #placeholder>
                  <div class="thumb-fallback"><el-icon><Picture /></el-icon></div>
                </template>
              </el-image>
              <div class="sticker-meta">
                <div class="sticker-name">{{ row.name || '-' }}</div>
                <div class="sticker-sub">ID: {{ row.id }}</div>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="所属用户" width="140">
          <template #default="{ row }">
            {{ row.user_name || '-' }}
            <div class="sticker-sub">ID: {{ row.user_id }}</div>
          </template>
        </el-table-column>
        <el-table-column label="热量" width="110" align="center">
          <template #default="{ row }">
            {{ row.kcal_per_100g != null ? row.kcal_per_100g + ' kcal/100g' : '-' }}
          </template>
        </el-table-column>
        <el-table-column label="蛋白质" width="90" align="center">
          <template #default="{ row }">{{ fmt(row.protein_g) }} g</template>
        </el-table-column>
        <el-table-column label="碳水" width="90" align="center">
          <template #default="{ row }">{{ fmt(row.carb_g) }} g</template>
        </el-table-column>
        <el-table-column label="脂肪" width="90" align="center">
          <template #default="{ row }">{{ fmt(row.fat_g) }} g</template>
        </el-table-column>
        <el-table-column label="膳食纤维" width="100" align="center">
          <template #default="{ row }">{{ fmt(row.dietary_fiber_g) }} g</template>
        </el-table-column>
        <el-table-column label="创建时间" width="160">
          <template #default="{ row }">{{ formatTime(row.created_at) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" :icon="Edit" @click="openDialog(row)">编辑</el-button>
            <el-button link type="danger" :icon="Delete" @click="onDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pager">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="size"
          :total="total"
          :page-sizes="[20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          background
          @size-change="fetchList"
          @current-change="fetchList"
        />
      </div>
    </el-card>

    <!-- 编辑弹窗 -->
    <el-dialog v-model="dialog.visible" title="编辑贴纸" width="560px" destroy-on-close>
      <div v-if="dialog.id" class="dialog-preview">
        <el-image :src="dialog.previewImg" class="preview-img" fit="cover">
          <template #error><div class="thumb-fallback lg"><el-icon><Picture /></el-icon></div></template>
        </el-image>
        <div class="preview-info">
          <div class="sticker-name">{{ dialog.form.name }}</div>
          <div class="sticker-sub">所属用户：{{ dialog.userName || '-' }}（ID: {{ dialog.userId }}）</div>
        </div>
      </div>
      <el-divider />
      <el-form :model="dialog.form" label-width="96px">
        <el-form-item label="贴纸名称" required>
          <el-input v-model="dialog.form.name" placeholder="贴纸名称" />
        </el-form-item>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="热量">
              <el-input v-model="dialog.form.kcal_per_100g">
                <template #append>kcal/100g</template>
              </el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="建议份量">
              <el-input v-model="dialog.form.typical_portion_g">
                <template #append>g</template>
              </el-input>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="10">
          <el-col :span="8">
            <el-form-item label="蛋白质">
              <el-input v-model="dialog.form.protein_g"><template #append>g</template></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="碳水">
              <el-input v-model="dialog.form.carb_g"><template #append>g</template></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="脂肪">
              <el-input v-model="dialog.form.fat_g"><template #append>g</template></el-input>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="10">
          <el-col :span="12">
            <el-form-item label="膳食纤维">
              <el-input v-model="dialog.form.dietary_fiber_g"><template #append>g</template></el-input>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="钠">
              <el-input v-model="dialog.form.sodium_mg"><template #append>mg</template></el-input>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="健康小贴士">
          <el-input
            v-model="dialog.form.vitamin_tips"
            type="textarea"
            :rows="3"
            placeholder="如：富含维生素C，适合搭配..."
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialog.visible = false">取消</el-button>
        <el-button type="primary" :loading="dialog.saving" @click="onSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Search,
  Refresh,
  Edit,
  Delete,
  Picture,
  User
} from '@element-plus/icons-vue'
import request from '../utils/request'

const list = ref([])
const total = ref(0)
const loading = ref(false)
const keyword = ref('')
const userId = ref('')
const page = ref(1)
const size = ref(20)

const fmt = (n) => (n === null || n === undefined || n === '' ? '-' : n)
const formatTime = (t) => {
  if (!t) return '-'
  const d = new Date(t)
  if (isNaN(d.getTime())) return t
  const pad = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(
    d.getHours()
  )}:${pad(d.getMinutes())}`
}
const stickerImage = (row) => {
  const b64 = row.image_b64
  if (b64) return b64.startsWith('data:') ? b64 : `data:image/png;base64,${b64}`
  return row.image_url || ''
}

const fetchList = async () => {
  loading.value = true
  try {
    const data = await request.get('/admin/stickers', {
      params: {
        page: page.value,
        size: size.value,
        keyword: keyword.value || undefined,
        user_id: userId.value || undefined
      }
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
  userId.value = ''
  page.value = 1
  fetchList()
}

const dialog = reactive({
  visible: false,
  saving: false,
  id: null,
  userId: '',
  userName: '',
  previewImg: '',
  form: {
    name: '',
    kcal_per_100g: '',
    protein_g: '',
    carb_g: '',
    fat_g: '',
    dietary_fiber_g: '',
    sodium_mg: '',
    typical_portion_g: '',
    vitamin_tips: ''
  }
})

const openDialog = async (row) => {
  dialog.id = row.id
  dialog.userId = row.user_id
  dialog.userName = row.user_name
  dialog.previewImg = stickerImage(row)
  // 拉取详情以填充完整字段
  try {
    const data = await request.get(`/admin/stickers/${row.id}`)
    Object.assign(dialog.form, {
      name: data.name ?? '',
      kcal_per_100g: data.kcal_per_100g ?? '',
      protein_g: data.protein_g ?? '',
      carb_g: data.carb_g ?? '',
      fat_g: data.fat_g ?? '',
      dietary_fiber_g: data.dietary_fiber_g ?? '',
      sodium_mg: data.sodium_mg ?? '',
      typical_portion_g: data.typical_portion_g ?? '',
      vitamin_tips: data.vitamin_tips ?? ''
    })
  } catch (e) {
    Object.assign(dialog.form, {
      name: row.name ?? '',
      kcal_per_100g: row.kcal_per_100g ?? '',
      protein_g: row.protein_g ?? '',
      carb_g: row.carb_g ?? '',
      fat_g: row.fat_g ?? '',
      dietary_fiber_g: row.dietary_fiber_g ?? '',
      sodium_mg: row.sodium_mg ?? '',
      typical_portion_g: row.typical_portion_g ?? '',
      vitamin_tips: row.vitamin_tips ?? ''
    })
  }
  dialog.visible = true
}

const toNumOrUndef = (v) => {
  if (v === '' || v === null || v === undefined) return undefined
  const n = Number(v)
  return isNaN(n) ? v : n
}

const onSave = async () => {
  if (!dialog.form.name) {
    ElMessage.warning('请填写贴纸名称')
    return
  }
  dialog.saving = true
  try {
    await request.put(`/admin/stickers/${dialog.id}`, {
      name: dialog.form.name,
      kcal_per_100g: toNumOrUndef(dialog.form.kcal_per_100g),
      protein_g: toNumOrUndef(dialog.form.protein_g),
      carb_g: toNumOrUndef(dialog.form.carb_g),
      fat_g: toNumOrUndef(dialog.form.fat_g),
      dietary_fiber_g: toNumOrUndef(dialog.form.dietary_fiber_g),
      sodium_mg: toNumOrUndef(dialog.form.sodium_mg),
      typical_portion_g: toNumOrUndef(dialog.form.typical_portion_g),
      vitamin_tips: dialog.form.vitamin_tips
    })
    ElMessage.success('保存成功')
    dialog.visible = false
    fetchList()
  } catch (e) {
    /* 已提示 */
  } finally {
    dialog.saving = false
  }
}

const onDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除贴纸「${row.name || row.id}」吗？`,
      '删除确认',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' }
    )
    await request.delete(`/admin/stickers/${row.id}`)
    ElMessage.success('删除成功')
    if (list.value.length === 1 && page.value > 1) page.value--
    fetchList()
  } catch (e) {
    /* 已提示 */
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
.sticker-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}
.sticker-thumb {
  width: 52px;
  height: 52px;
  border-radius: 10px;
  flex-shrink: 0;
  border: 1px solid #ebeef5;
}
.thumb-fallback {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #c0c4cc;
  background: #f5f7fa;
  font-size: 20px;
}
.thumb-fallback.lg {
  font-size: 30px;
}
.sticker-meta {
  line-height: 1.4;
}
.sticker-name {
  font-weight: 600;
  color: #303133;
}
.sticker-sub {
  font-size: 12px;
  color: #909399;
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
.dialog-preview {
  display: flex;
  align-items: center;
  gap: 14px;
}
.preview-img {
  width: 88px;
  height: 88px;
  border-radius: 12px;
  border: 1px solid #ebeef5;
  flex-shrink: 0;
}
.preview-info {
  line-height: 1.6;
}
</style>
