"""
MobileSAM → 端侧模型转换（FP16）
产物:
  iOS    : MobileSAMEncoder.mlpackage / MobileSAMDecoder.mlpackage
  Android: mobilesam_encoder.param/.bin  mobilesam_decoder.param/.bin

依赖: pip install torch coremltools onnx onnxsim mobile_sam
权重: https://github.com/ChaoningZhang/MobileSAM  (mobile_sam.pt)

用法:
  python convert_mobilesam.py --ckpt mobile_sam.pt --out ./out
"""
import argparse, os, subprocess
import torch
import coremltools as ct
from mobile_sam import sam_model_registry
from mobile_sam.utils.onnx import SamOnnxModel

IMG_SIZE = 1024  # SAM 标准输入；低端机端侧运行时降级到 512（等比 pad）

def export_encoder(sam, out_dir):
    """图像编码器 TinyViT: (1,3,1024,1024) -> (1,256,64,64)"""
    class Encoder(torch.nn.Module):
        def __init__(self, sam):
            super().__init__()
            self.model = sam.image_encoder
        def forward(self, x):
            return self.model(x)

    enc = Encoder(sam).eval()
    dummy = torch.randn(1, 3, IMG_SIZE, IMG_SIZE)
    onnx_path = os.path.join(out_dir, "mobilesam_encoder.onnx")
    torch.onnx.export(enc, dummy, onnx_path, opset_version=17,
                      input_names=["image"], output_names=["image_embeddings"])
    subprocess.run(["python", "-m", "onnxsim", onnx_path, onnx_path], check=True)

    # --- Core ML (FP16, ANE/GPU 自动调度) ---
    mlmodel = ct.convert(
        onnx_path,
        inputs=[ct.ImageType(name="image", shape=(1, 3, IMG_SIZE, IMG_SIZE),
                             scale=1 / 255.0, color_layout=ct.colorlayout.RGB)],
        compute_precision=ct.precision.FLOAT16,
        compute_units=ct.ComputeUnit.ALL,
        minimum_deployment_target=ct.target.iOS16,
    )
    mlmodel.save(os.path.join(out_dir, "MobileSAMEncoder.mlpackage"))
    return onnx_path


def export_decoder(sam, out_dir):
    """提示解码器: embeddings + 点提示 -> 低分辨率mask (1,1,256,256)"""
    onnx_model = SamOnnxModel(sam, return_single_mask=True)
    dummy = {
        "image_embeddings": torch.randn(1, 256, 64, 64),
        "point_coords": torch.randint(0, IMG_SIZE, (1, 2, 2), dtype=torch.float),
        "point_labels": torch.tensor([[1.0, -1.0]]),
        "mask_input": torch.zeros(1, 1, 256, 256),
        "has_mask_input": torch.zeros(1),
        "orig_im_size": torch.tensor([IMG_SIZE, IMG_SIZE], dtype=torch.float),
    }
    onnx_path = os.path.join(out_dir, "mobilesam_decoder.onnx")
    torch.onnx.export(onnx_model, tuple(dummy.values()), onnx_path, opset_version=17,
                      input_names=list(dummy.keys()),
                      output_names=["masks", "iou_predictions", "low_res_masks"])
    subprocess.run(["python", "-m", "onnxsim", onnx_path, onnx_path], check=True)

    mlmodel = ct.convert(onnx_path,
                         compute_precision=ct.precision.FLOAT16,
                         compute_units=ct.ComputeUnit.ALL,
                         minimum_deployment_target=ct.target.iOS16)
    mlmodel.save(os.path.join(out_dir, "MobileSAMDecoder.mlpackage"))
    return onnx_path


def to_ncnn(onnx_path, out_dir, name):
    """ONNX → NCNN，并做 fp16 优化（需已编译 ncnn tools: onnx2ncnn / ncnnoptimize）"""
    param = os.path.join(out_dir, f"{name}.param")
    bin_ = os.path.join(out_dir, f"{name}.bin")
    subprocess.run(["onnx2ncnn", onnx_path, param, bin_], check=True)
    # 末位参数 65536 = fp16 存储与运算
    subprocess.run(["ncnnoptimize", param, bin_, param, bin_, "65536"], check=True)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--ckpt", required=True)
    ap.add_argument("--out", default="./out")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    sam = sam_model_registry["vit_t"](checkpoint=args.ckpt).eval()
    enc_onnx = export_encoder(sam, args.out)
    dec_onnx = export_decoder(sam, args.out)
    to_ncnn(enc_onnx, args.out, "mobilesam_encoder")
    to_ncnn(dec_onnx, args.out, "mobilesam_decoder")
    print("done ->", args.out)
