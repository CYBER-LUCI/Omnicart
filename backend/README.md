# OmniCart — Visual Search Engine & Backend API

This backend module implements the **Visual Search AI Pipeline** as specified in the DBMS Project Entity-Relationship Diagram (ERD):
$$\text{ProductEmbeddings}(\text{EmbeddingsID}, \text{ProductID}, \text{FeatureVector}, \text{ModelName}, \text{Dimensions})$$

---

## 1. Architectural Highlights

- **Visual Search Input**: Accepts images strictly from **Camera (live webcam stream with snapshot shutter)** or **Device Gallery / File Upload (Drag & Drop)**.
- **Deep Feature Extractor Model**:
  - Primary AI Backbone: **TorchVision MobileNetV3 Large Feature Extractor** (L2-normalized 512-dimensional penultimate feature representation) and **OpenAI CLIP (ViT-B/32)** compatible.
  - Zero-overhead, pre-installed Python CPU/GPU execution.
- **Vector Metric**: Cosine Similarity:
  $$\text{Cosine Sim}(A, B) = \frac{A \cdot B}{\|A\| \|B\|}$$
- **Relational DBMS Storage**:
  - `backend/schema.sql`: Complete MySQL DDL schema.
  - `backend/seed_embeddings.sql`: Auto-generated SQL `INSERT` statements with real 512-dimensional vectors for all catalog products.
  - `backend/product_embeddings.json`: JSON format for offline frontend cache and in-browser fallback.

---

## 2. API Endpoints Reference

Base URL: `http://127.0.0.1:5000`

### `GET /api/health`
Returns system status, active vision model name, embedding dimension count, and total embedded catalog products.

### `GET /api/embeddings`
Returns all records from the `ProductEmbeddings` table according to ERD specifications.

### `POST /api/search/visual`
Accepts:
- `multipart/form-data`: `image` file
- `application/json`: `{ "image": "data:image/jpeg;base64,..." }`

Processing:
1. Passes visual input to `VisualEmbeddingEngine`.
2. Extracts 512-dimensional query vector.
3. Ranks all items in `ProductEmbeddings` using cosine similarity.
4. Returns top-$k$ products with match confidence percentage (e.g., `96.8% Match`) and EmbeddingsID.

### `GET /api/search/text?q={query}`
Provides real-time product autocomplete suggestions for the global search bar.

---

## 3. How to Run the Backend

```bash
# 1. (Optional) Re-generate catalog embeddings from scratch
python backend/generate_embeddings.py

# 2. Launch the Flask Visual Search server (Runs on port 5000)
python backend/app.py
```

The server automatically enables CORS, allowing all frontend pages (`index.html`, `products.html`, etc.) to communicate with the visual search engine seamlessly.
