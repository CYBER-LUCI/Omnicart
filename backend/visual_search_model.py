"""
Visual Search AI Model Engine for OmniCart
Extracts high-dimensional dense feature vectors (embeddings) from product images
as specified in the DBMS Project ERD: ProductEmbeddings(EmbeddingsID, ProductID, FeatureVector).
"""

import os
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

import io
import base64
import numpy as np
from PIL import Image
import torch
import torchvision.transforms as transforms
import torchvision.models as models

CATEGORY_ANCHORS = {
    'PROD-001': 'a smartwatch, wristwatch, or digital chrono watch',
    'PROD-002': 'a flying quadcopter drone with camera propellers',
    'PROD-003': 'a computer mechanical keyboard with keys and RGB lights',
    'PROD-004': 'over-ear audio studio headphones with headband',
    'PROD-005': 'a gaming desk mat or mousepad',
    'PROD-006': 'in-ear wireless bluetooth earbuds in charging case',
    'PROD-007': 'a kitchen air fryer appliance or deep fryer cooker',
    'PROD-008': 'an LED ambient gradient desk light bar tube lamp',
    'PROD-009': 'a wall fast power charger block plug adapter',
    'PROD-010': 'an electric sonic toothbrush or dental wand',
    'PROD-011': 'a braided USB-C power charging data cable cord'
}

class VisualEmbeddingEngine:
    def __init__(self, preferred_model="clip"):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model_name = "torchvision-mobilenetv3"
        self.clip_model = None
        self.torch_model = None
        self.dim = 512
        self.anchor_keys = list(CATEGORY_ANCHORS.keys())
        self.anchor_embs = None

        # 1. Try to initialize OpenAI CLIP if sentence-transformers is available
        if preferred_model == "clip":
            try:
                from sentence_transformers import SentenceTransformer
                print("[AI Engine] Loading OpenAI CLIP (clip-ViT-B-32) from Hugging Face...")
                self.clip_model = SentenceTransformer("clip-ViT-B-32")
                self.model_name = "openai/clip-vit-base-patch32"
                self.dim = 512
                anchor_texts = [CATEGORY_ANCHORS[k] for k in self.anchor_keys]
                self.anchor_embs = self.clip_model.encode(anchor_texts, normalize_embeddings=True)
                print(f"[AI Engine] CLIP Model loaded successfully on {self.device} with {len(self.anchor_keys)} category anchors!")
                return
            except Exception as e:
                print(f"[AI Engine] Notice: sentence-transformers not found or offline ({e}).")
                print("[AI Engine] Seamlessly using high-performance TorchVision vision backbone...")

        # 2. Built-in TorchVision Feature Extractor (Zero download requirement, pre-installed)
        print("[AI Engine] Initializing TorchVision Deep Feature Extractor...")
        try:
            base_model = models.mobilenet_v3_large(weights=models.MobileNet_V3_Large_Weights.DEFAULT)
            # Remove final classifier to extract the dense penultimate embedding (960-dim -> projected to 512-dim)
            self.torch_model = base_model.features
            self.torch_model.eval()
            self.torch_model.to(self.device)
            self.model_name = "torchvision-mobilenetv3-feature-extractor"
            self.dim = 512
            print(f"[AI Engine] TorchVision Feature Extractor ready on {self.device}!")
        except Exception as e:
            print(f"[AI Engine] Fallback to standard feature weights: {e}")
            base_model = models.mobilenet_v3_large(weights=None)
            self.torch_model = base_model.features
            self.torch_model.eval()
            self.model_name = "torchvision-mobilenetv3-standard"

        # Standard Preprocessing Transform for 224x224 input
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])

    def load_image(self, image_input):
        """Converts bytes, file path, PIL image, or base64 data URL to PIL RGB Image."""
        if isinstance(image_input, Image.Image):
            return image_input.convert("RGB")

        if isinstance(image_input, str):
            # Check if base64 data URL
            if image_input.startswith("data:image"):
                header, encoded = image_input.split(",", 1)
                data = base64.b64decode(encoded)
                return Image.open(io.BytesIO(data)).convert("RGB")
            # Check if HTTP/HTTPS URL
            if image_input.startswith("http://") or image_input.startswith("https://"):
                import urllib.request
                req = urllib.request.Request(image_input, headers={"User-Agent": "OmniCart/1.0"})
                with urllib.request.urlopen(req, timeout=10) as resp:
                    return Image.open(io.BytesIO(resp.read())).convert("RGB")
            # Or file path
            return Image.open(image_input).convert("RGB")

        if isinstance(image_input, (bytes, bytearray)):
            return Image.open(io.BytesIO(image_input)).convert("RGB")

        # Assume file-like object
        return Image.open(image_input).convert("RGB")

    def extract_embedding(self, image_input) -> list:
        """
        Extracts a dense 512-dimensional L2-normalized feature vector from an image.
        Returns: list of 512 floats matching the MySQL ProductEmbeddings(FeatureVector) schema.
        """
        img = self.load_image(image_input)

        if self.clip_model is not None:
            # CLIP embedding
            embedding = self.clip_model.encode(img, normalize_embeddings=True)
            return [round(float(x), 6) for x in embedding]

        # TorchVision Feature Extractor
        with torch.no_grad():
            tensor = self.transform(img).unsqueeze(0).to(self.device)
            features = self.torch_model(tensor)
            # Global Average Pooling across spatial dimensions (1, 960, 7, 7) -> (1, 960)
            pooled = torch.nn.functional.adaptive_avg_pool2d(features, (1, 1)).flatten()
            # Linear projection or slice to 512-dim
            vec = pooled[:512] if pooled.shape[0] >= 512 else torch.nn.functional.pad(pooled, (0, 512 - pooled.shape[0]))
            # L2 Normalization
            norm_vec = torch.nn.functional.normalize(vec, p=2, dim=0)
            return [round(float(x), 6) for x in norm_vec.cpu().numpy()]

    @staticmethod
    def compute_cosine_similarity(vec_a: list, vec_b: list) -> float:
        """
        Computes cosine similarity between two unit-normalized embedding vectors:
        Cosine Sim = (A . B) / (||A|| * ||B||)
        """
        a = np.array(vec_a, dtype=np.float32)
        b = np.array(vec_b, dtype=np.float32)

        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)

        if norm_a == 0 or norm_b == 0:
            return 0.0

        dot = np.dot(a, b)
        similarity = float(dot / (norm_a * norm_b))
        return float(np.clip(similarity, 0.0, 1.0))

    def rank_catalog(self, query_vector: list, catalog_embeddings: list, top_k: int = 5, min_threshold: float = 0.68) -> list:
        """
        Smart Visual Catalog Ranking with Category Gating:
        - Prevents cross-category contamination (e.g. watch queries won't show chargers or earbuds).
        - Enforces strict minimum similarity threshold (>= 68%).
        - If query does not match any catalog product resemblance, returns empty list (No Results).
        """
        q_vec = np.array(query_vector, dtype=np.float32)

        # 1. Zero-shot Category Classification
        best_cat_pid = None
        best_cat_conf = 1.0
        cat_dots = None

        if hasattr(self, 'anchor_embs') and self.anchor_embs is not None:
            cat_dots = np.dot(self.anchor_embs, q_vec)
            best_cat_idx = int(np.argmax(cat_dots))
            best_cat_pid = self.anchor_keys[best_cat_idx]
            best_cat_conf = float(cat_dots[best_cat_idx])

            # Reject non-catalog items (e.g. coffee, pets, fruit)
            if best_cat_conf < 0.22:
                return []

        results = []
        for item in catalog_embeddings:
            prod_id = item.get("ProductID")
            emb_id = item.get("EmbeddingsID")
            feat_vec = item.get("FeatureVector", [])

            sim = self.compute_cosine_similarity(query_vector, feat_vec)

            # Prevent Category Mismatch:
            # Only keep products that belong to or strongly resemble the detected query category
            if best_cat_pid is not None and cat_dots is not None:
                cat_idx = self.anchor_keys.index(prod_id) if prod_id in self.anchor_keys else -1
                cat_sim = float(cat_dots[cat_idx]) if cat_idx >= 0 else 0.0
                if prod_id != best_cat_pid and (best_cat_conf - cat_sim) > 0.035:
                    continue

            # Strict 68% - 70% Confidence Threshold (Discard low confidence resemblance)
            if sim < min_threshold:
                continue

            results.append({
                "ProductID": prod_id,
                "EmbeddingsID": emb_id,
                "similarity_score": round(sim, 4),
                "match_percentage": f"{round(sim * 100, 1)}%"
            })

        # Sort descending by similarity
        results.sort(key=lambda x: x["similarity_score"], reverse=True)
        return results[:top_k]

# Global Singleton Engine
visual_engine = VisualEmbeddingEngine()
