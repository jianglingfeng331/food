"""
占位 Core ML 模型生成器（PyTorch → coremltools）
→ 产出 Xcode 编译所需的 4 个 .mlpackage 文件

依赖：pip3 install --user torch coremltools
"""
import os, sys
import torch
import torch.nn as nn
import coremltools as ct

OUT = os.path.join(os.path.dirname(__file__), "../ios/FoodSticker/Resources")
os.makedirs(OUT, exist_ok=True)

def save_mlmodel(traced, name, inputs=None, outputs=None):
    path = os.path.join(OUT, f"{name}.mlpackage")
    if os.path.exists(path):
        import shutil; shutil.rmtree(path)
    kwargs = {"compute_precision": ct.precision.FLOAT16,
              "compute_units": ct.ComputeUnit.ALL,
              "minimum_deployment_target": ct.target.iOS16}
    if inputs: kwargs["inputs"] = inputs
    if outputs: kwargs["outputs"] = outputs
    mlmodel = ct.convert(traced, source="pytorch", **kwargs)
    mlmodel.save(path)
    print(f"  ✓ {name}.mlpackage")

# ─── 1. MobileSAMEncoder (1,3,1024,1024) → (1,256,64,64) ───
class DummyEncoder(nn.Module):
    def forward(self, x):
        return torch.zeros(1, 256, 64, 64)

enc = torch.jit.trace(DummyEncoder().eval(), torch.randn(1, 3, 1024, 1024))
save_mlmodel(enc, "MobileSAMEncoder",
    inputs=[ct.ImageType(name="image", shape=(1, 3, 1024, 1024),
                         scale=1/255.0, color_layout=ct.colorlayout.RGB)])

# ─── 2. MobileSAMDecoder （6 入 3 出） ───
class DummyDecoder(nn.Module):
    def forward(self, image_embeddings, point_coords, point_labels,
                mask_input, has_mask_input, orig_im_size):
        return (torch.randn(1, 1, 256, 256),
                torch.tensor([[0.5]]),
                torch.randn(1, 1, 256, 256))

dec = torch.jit.trace(DummyDecoder().eval(),
    (torch.randn(1, 256, 64, 64),
     torch.randint(0, 1024, (1, 5, 2), dtype=torch.float),
     torch.randint(0, 2, (1, 5), dtype=torch.float),
     torch.zeros(1, 1, 256, 256),
     torch.zeros(1),
     torch.tensor([1024.0, 1024.0])))

save_mlmodel(dec, "MobileSAMDecoder",
    inputs=[ct.TensorType(name="image_embeddings", shape=(1, 256, 64, 64)),
            ct.TensorType(name="point_coords", shape=(1, 5, 2)),
            ct.TensorType(name="point_labels", shape=(1, 5)),
            ct.TensorType(name="mask_input", shape=(1, 1, 256, 256)),
            ct.TensorType(name="has_mask_input", shape=(1,)),
            ct.TensorType(name="orig_im_size", shape=(2,))],
    outputs=[ct.TensorType(name="masks"),
             ct.TensorType(name="iou_predictions"),
             ct.TensorType(name="low_res_masks")])

# ─── 3. AnimeGANv3 (1,3,512,512) → tanh style ───
class DummyAnimeGAN(nn.Module):
    def forward(self, x):
        return torch.tanh(torch.randn(1, 3, 512, 512) * 0.1)

ag = torch.jit.trace(DummyAnimeGAN().eval(), torch.randn(1, 3, 512, 512))
save_mlmodel(ag, "AnimeGANv3",
    inputs=[ct.ImageType(name="image", shape=(1, 3, 512, 512),
             scale=2/255.0, bias=[-1, -1, -1], color_layout=ct.colorlayout.RGB)])

# ─── 4. FoodClassifierModel (1,3,300,300) → 1000 类 softmax ───
class DummyFoodCls(nn.Module):
    def forward(self, x):
        return torch.softmax(torch.randn(1, 1000), dim=1)

fc = torch.jit.trace(DummyFoodCls().eval(), torch.randn(1, 3, 300, 300))
save_mlmodel(fc, "FoodClassifierModel",
    inputs=[ct.ImageType(name="image", shape=(1, 3, 300, 300),
             scale=1/(255.0*0.226),
             bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225],
             color_layout=ct.colorlayout.RGB)])

print(f"\n✅ 全部占位模型 → {OUT}")
cd /Users/jianglingfeng/Documents/AI编辑/pknew/food-sticker-app/ios && bash build_ipa.sh
