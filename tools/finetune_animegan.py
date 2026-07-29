"""
AnimeGANv3 轻量化版 —— 食品贴纸风格微调 + 双端导出（FP16）

贴纸风格目标（与产品硬性标准对齐）:
  - 加粗黑色轮廓线、纯色平涂、弱化光影渐变
  - 严格保留原轮廓/配色/关键细节（identity 约束）

数据准备:
  A域: 食品实拍图（Food-101 抠图后主体，透明底填白，约2万张）
  B域: 目标贴纸风格图（用云端SD+固定提示词批量生成5千张，人工筛除变形样本）

依赖: pip install torch torchvision lpips coremltools onnx onnxsim
基座: AnimeGANv3 官方轻量 generator（~1.2M 参数）

用法:
  python finetune_animegan.py train  --dataA foodA/ --dataB stickerB/ --epochs 40
  python finetune_animegan.py export --ckpt g_best.pt --out ./out
"""
import argparse, os, subprocess, sys
import torch
import torch.nn as nn
import torch.nn.functional as F

SIZE = 512  # 端侧推理输入尺寸


# ---------------- 轻量生成器（AnimeGANv3-lite 结构） ----------------
class ConvBlock(nn.Sequential):
    def __init__(self, cin, cout, k=3, s=1):
        super().__init__(
            nn.Conv2d(cin, cout, k, s, k // 2, bias=False),
            nn.InstanceNorm2d(cout), nn.LeakyReLU(0.2, True))


class Generator(nn.Module):
    def __init__(self, nf=32):
        super().__init__()
        self.down = nn.Sequential(
            ConvBlock(3, nf), ConvBlock(nf, nf * 2, s=2),
            ConvBlock(nf * 2, nf * 2), ConvBlock(nf * 2, nf * 4, s=2))
        self.mid = nn.Sequential(*[ConvBlock(nf * 4, nf * 4) for _ in range(4)])
        self.up = nn.Sequential(
            nn.Upsample(scale_factor=2, mode="bilinear", align_corners=False),
            ConvBlock(nf * 4, nf * 2),
            nn.Upsample(scale_factor=2, mode="bilinear", align_corners=False),
            ConvBlock(nf * 2, nf),
            nn.Conv2d(nf, 3, 3, 1, 1), nn.Tanh())

    def forward(self, x):          # x in [-1,1]
        return self.up(self.mid(self.down(x)))


# ---------------- 训练（核心损失设计） ----------------
def train(args):
    import lpips
    from torchvision import transforms, datasets
    dev = "cuda" if torch.cuda.is_available() else "cpu"
    G, D = Generator().to(dev), nn.Sequential(  # PatchGAN 判别器
        nn.Conv2d(3, 64, 4, 2, 1), nn.LeakyReLU(0.2, True),
        nn.Conv2d(64, 128, 4, 2, 1), nn.LeakyReLU(0.2, True),
        nn.Conv2d(128, 1, 4, 1, 1)).to(dev)
    lp = lpips.LPIPS(net="vgg").to(dev)
    optG = torch.optim.Adam(G.parameters(), 2e-4, betas=(0.5, 0.999))
    optD = torch.optim.Adam(D.parameters(), 2e-4, betas=(0.5, 0.999))

    tf = transforms.Compose([transforms.Resize(SIZE), transforms.CenterCrop(SIZE),
                             transforms.ToTensor(),
                             transforms.Normalize([0.5] * 3, [0.5] * 3)])
    dlA = torch.utils.data.DataLoader(datasets.ImageFolder(args.dataA, tf),
                                      batch_size=8, shuffle=True, drop_last=True)
    dlB = torch.utils.data.DataLoader(datasets.ImageFolder(args.dataB, tf),
                                      batch_size=8, shuffle=True, drop_last=True)

    def edge(x):  # Sobel 边缘，用于“轮廓不变形”强约束
        kx = torch.tensor([[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]], dtype=x.dtype,
                          device=x.device).view(1, 1, 3, 3).repeat(3, 1, 1, 1)
        gray = x.mean(1, keepdim=True).repeat(1, 3, 1, 1)
        gx = F.conv2d(gray, kx, padding=1, groups=3)
        gy = F.conv2d(gray, kx.transpose(2, 3), padding=1, groups=3)
        return (gx ** 2 + gy ** 2).sqrt()

    for ep in range(args.epochs):
        for (a, _), (b, _) in zip(dlA, dlB):
            a, b = a.to(dev), b.to(dev)
            fake = G(a)
            # --- D ---
            optD.zero_grad()
            (F.mse_loss(D(b), torch.ones_like(D(b))) +
             F.mse_loss(D(fake.detach()), torch.zeros_like(D(fake)))).backward()
            optD.step()
            # --- G: 对抗 + 内容(LPIPS) + 颜色保持(L1) + 轮廓保持(edge) ---
            optG.zero_grad()
            loss_g = (F.mse_loss(D(fake), torch.ones_like(D(fake)))
                      + 1.5 * lp(fake, a).mean()          # 保留结构细节
                      + 8.0 * F.l1_loss(fake.mean([2, 3]), a.mean([2, 3]))  # 还原配色
                      + 4.0 * F.l1_loss(edge(fake), edge(a)))               # 轮廓不变形
            loss_g.backward()
            optG.step()
        torch.save(G.state_dict(), "g_best.pt")
        print(f"epoch {ep} G_loss={loss_g.item():.3f}")


# ---------------- 导出（FP16 双端） ----------------
def export(args):
    import coremltools as ct
    G = Generator().eval()
    G.load_state_dict(torch.load(args.ckpt, map_location="cpu"))
    os.makedirs(args.out, exist_ok=True)
    dummy = torch.randn(1, 3, SIZE, SIZE)
    onnx_path = os.path.join(args.out, "animeganv3.onnx")
    torch.onnx.export(G, dummy, onnx_path, opset_version=17,
                      input_names=["image"], output_names=["cartoon"])
    subprocess.run(["python", "-m", "onnxsim", onnx_path, onnx_path], check=True)

    ml = ct.convert(onnx_path,
                    inputs=[ct.ImageType(name="image", shape=(1, 3, SIZE, SIZE),
                                         scale=2 / 255.0, bias=[-1, -1, -1],
                                         color_layout=ct.colorlayout.RGB)],
                    compute_precision=ct.precision.FLOAT16,
                    compute_units=ct.ComputeUnit.ALL,
                    minimum_deployment_target=ct.target.iOS16)
    ml.save(os.path.join(args.out, "AnimeGANv3.mlpackage"))

    subprocess.run(["onnx2ncnn", onnx_path,
                    f"{args.out}/animeganv3.param", f"{args.out}/animeganv3.bin"], check=True)
    subprocess.run(["ncnnoptimize", f"{args.out}/animeganv3.param", f"{args.out}/animeganv3.bin",
                    f"{args.out}/animeganv3.param", f"{args.out}/animeganv3.bin", "65536"], check=True)
    print("done ->", args.out)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["train", "export"])
    ap.add_argument("--dataA"), ap.add_argument("--dataB")
    ap.add_argument("--epochs", type=int, default=40)
    ap.add_argument("--ckpt"), ap.add_argument("--out", default="./out")
    args = ap.parse_args()
    train(args) if args.cmd == "train" else export(args)
