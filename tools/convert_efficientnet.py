"""
EfficientNet-Lite4 —— Food-101 + UEC-Food256 微调（1000类）+ 双端导出（FP16）

数据: Food-101(101类) + UEC-Food256(256类) + 自采/开源补充至 1000 类，
      类别索引与 nutrition.db 的 food.class_id 一一对应（labels_1000.txt 行号即 class_id）。

依赖: pip install torch torchvision timm coremltools onnx onnxsim

用法:
  python convert_efficientnet.py train  --data ./food1000 --epochs 30
  python convert_efficientnet.py export --ckpt cls_best.pt --out ./out
"""
import argparse, os, subprocess
import torch
import timm

SIZE = 300  # EfficientNet-Lite4 标准输入
NUM_CLASSES = 1000


def build_model(pretrained=True):
    return timm.create_model("tf_efficientnet_lite4", pretrained=pretrained,
                             num_classes=NUM_CLASSES)


def train(args):
    from torchvision import transforms, datasets
    dev = "cuda" if torch.cuda.is_available() else "cpu"
    model = build_model().to(dev)

    tf_train = transforms.Compose([
        transforms.RandomResizedCrop(SIZE, scale=(0.6, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.ColorJitter(0.2, 0.2, 0.2),   # 光照鲁棒性（餐厅/家庭多光源）
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])])
    ds = datasets.ImageFolder(os.path.join(args.data, "train"), tf_train)
    dl = torch.utils.data.DataLoader(ds, batch_size=64, shuffle=True, num_workers=8)

    opt = torch.optim.AdamW(model.parameters(), lr=3e-4, weight_decay=1e-4)
    sched = torch.optim.lr_scheduler.CosineAnnealingLR(opt, args.epochs)
    crit = torch.nn.CrossEntropyLoss(label_smoothing=0.1)

    for ep in range(args.epochs):
        model.train()
        for x, y in dl:
            x, y = x.to(dev), y.to(dev)
            opt.zero_grad()
            crit(model(x), y).backward()
            opt.step()
        sched.step()
        torch.save(model.state_dict(), "cls_best.pt")
        print(f"epoch {ep} done")
    # 类别标签文件（行号=class_id，与营养库对齐）
    with open("labels_1000.txt", "w") as f:
        f.write("\n".join(ds.classes))


def export(args):
    import coremltools as ct
    model = build_model(pretrained=False).eval()
    model.load_state_dict(torch.load(args.ckpt, map_location="cpu"))
    os.makedirs(args.out, exist_ok=True)

    # 导出带 softmax 的推理图（端侧直接拿概率）
    class Infer(torch.nn.Module):
        def __init__(self, m): super().__init__(); self.m = m
        def forward(self, x): return torch.softmax(self.m(x), dim=1)

    dummy = torch.randn(1, 3, SIZE, SIZE)
    onnx_path = os.path.join(args.out, "food_classifier.onnx")
    torch.onnx.export(Infer(model), dummy, onnx_path, opset_version=17,
                      input_names=["image"], output_names=["probs"])
    subprocess.run(["python", "-m", "onnxsim", onnx_path, onnx_path], check=True)

    ml = ct.convert(onnx_path,
                    inputs=[ct.ImageType(name="image", shape=(1, 3, SIZE, SIZE),
                                         scale=1 / (255.0 * 0.226),
                                         bias=[-0.485 / 0.229, -0.456 / 0.224, -0.406 / 0.225],
                                         color_layout=ct.colorlayout.RGB)],
                    compute_precision=ct.precision.FLOAT16,
                    compute_units=ct.ComputeUnit.ALL,
                    minimum_deployment_target=ct.target.iOS16)
    ml.save(os.path.join(args.out, "FoodClassifier.mlpackage"))

    subprocess.run(["onnx2ncnn", onnx_path,
                    f"{args.out}/food_classifier.param", f"{args.out}/food_classifier.bin"], check=True)
    subprocess.run(["ncnnoptimize", f"{args.out}/food_classifier.param",
                    f"{args.out}/food_classifier.bin",
                    f"{args.out}/food_classifier.param",
                    f"{args.out}/food_classifier.bin", "65536"], check=True)
    print("done ->", args.out)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["train", "export"])
    ap.add_argument("--data"), ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--ckpt"), ap.add_argument("--out", default="./out")
    args = ap.parse_args()
    train(args) if args.cmd == "train" else export(args)
