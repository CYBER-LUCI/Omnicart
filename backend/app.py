"""
OmniCart Visual Search Backend API
Flask REST service implementing image-based visual similarity search using
pre-computed deep feature embeddings according to the DBMS ERD:
ProductEmbeddings(EmbeddingsID, ProductID, FeatureVector, ModelName, Dimensions).
"""

import sys
import os
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import json
from flask import Flask, request, jsonify
try:
    from visual_search_model import visual_engine
except ImportError:
    from backend.visual_search_model import visual_engine

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB max payload limit

# Enable CORS for local file:// access or local server origins
@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    return response

# Load catalog embeddings
EMBEDDINGS_FILE = os.path.join(os.path.dirname(__file__), "product_embeddings.json")
CATALOG_EMBEDDINGS = []
PRODUCT_METADATA = {}

def load_embeddings():
    global CATALOG_EMBEDDINGS, PRODUCT_METADATA
    if os.path.exists(EMBEDDINGS_FILE):
        try:
            with open(EMBEDDINGS_FILE, "r", encoding="utf-8") as f:
                CATALOG_EMBEDDINGS = json.load(f)
            print(f"[API] Loaded {len(CATALOG_EMBEDDINGS)} product embeddings from {EMBEDDINGS_FILE}")
            for emb in CATALOG_EMBEDDINGS:
                p_id = emb.get("ProductID")
                if p_id and emb.get("Name"):
                    PRODUCT_METADATA[p_id] = {
                        "id": p_id,
                        "name": emb.get("Name", f"Product {p_id}"),
                        "category": emb.get("Category", "General"),
                        "price": float(emb.get("Price", 999.0)),
                        "origPrice": float(emb.get("OrigPrice", round(float(emb.get("Price", 999.0)) * 1.35))),
                        "rating": float(emb.get("Rating", 4.8)),
                        "reviews": int(emb.get("Reviews", 1)),
                        "img": emb.get("Image", ""),
                        "desc": emb.get("Description", "")
                    }
        except Exception as e:
            print(f"[API] Error loading embeddings file: {e}")
            CATALOG_EMBEDDINGS = []
    else:
        CATALOG_EMBEDDINGS = []
        try:
            with open(EMBEDDINGS_FILE, "w", encoding="utf-8") as f:
                json.dump([], f)
        except Exception:
            pass

# Initialize embeddings immediately on startup
load_embeddings()

@app.route("/api/health", methods=["GET"])
def health_check():
    return jsonify({
        "status": "online",
        "engine": visual_engine.model_name,
        "dimensions": visual_engine.dim,
        "device": str(visual_engine.device),
        "embedded_products_count": len(CATALOG_EMBEDDINGS),
        "table_name": "ProductEmbeddings",
        "schema": "(EmbeddingsID, ProductID, FeatureVector, ModelName, Dimensions)"
    })

@app.route("/api/embeddings", methods=["GET"])
def get_all_embeddings():
    """Returns the full ProductEmbeddings table records (ERD compliant)"""
    return jsonify({
        "status": "success",
        "total": len(CATALOG_EMBEDDINGS),
        "schema": "ProductEmbeddings(EmbeddingsID, ProductID, FeatureVector)",
        "data": CATALOG_EMBEDDINGS
    })

@app.route("/api/embeddings/index", methods=["POST", "OPTIONS"])
def index_product_embedding():
    """Dynamically extract and index a 512-dim embedding for a newly published product"""
    global CATALOG_EMBEDDINGS
    if request.method == "OPTIONS":
        return "", 200

    data = request.get_json(silent=True) or {}
    product_id = data.get("product_id") or data.get("ProductID") or f"PROD-{len(CATALOG_EMBEDDINGS) + 1:03d}"
    name = str(data.get("name") or data.get("Name") or "New Product")[:150]
    category = str(data.get("category") or data.get("Category") or "Electronics")[:100]
    try:
        price = max(0.01, float(data.get("price") or data.get("CurrentPrice") or 999.0))
    except (ValueError, TypeError):
        price = 999.0
    image_source = data.get("image") or data.get("Image") or data.get("image_url")
    desc = str(data.get("desc") or data.get("Description") or "")[:1000]

    if not image_source:
        return jsonify({"status": "error", "message": "Image URL or data is required for embedding extraction"}), 400

    try:
        # Extract 512-dim feature vector via CLIP visual engine
        vector = visual_engine.extract_embedding(image_source)

        emb_record = {
            "EmbeddingsID": f"EMB-{len(CATALOG_EMBEDDINGS) + 1:04d}",
            "ProductID": product_id,
            "FeatureVector": vector,
            "ModelName": visual_engine.model_name,
            "Dimensions": len(vector),
            "Name": name,
            "Category": category,
            "Price": price,
            "Image": image_source if (isinstance(image_source, str) and not image_source.startswith("data:")) else "",
            "Description": desc
        }

        # Update in-memory list (replace if already present for this product)
        CATALOG_EMBEDDINGS = [e for e in CATALOG_EMBEDDINGS if e.get("ProductID") != product_id]
        CATALOG_EMBEDDINGS.append(emb_record)

        # Update metadata dictionary
        PRODUCT_METADATA[product_id] = {
            "id": product_id,
            "name": name,
            "category": category,
            "price": price,
            "origPrice": round(price * 1.35),
            "rating": 5.0,
            "reviews": 1,
            "img": emb_record["Image"] or image_source,
            "desc": desc
        }

        # Persist to product_embeddings.json
        try:
            with open(EMBEDDINGS_FILE, "w", encoding="utf-8") as f:
                json.dump(CATALOG_EMBEDDINGS, f)
        except Exception as file_err:
            print(f"[API] Warning saving embeddings file: {file_err}")

        return jsonify({
            "status": "success",
            "message": f"Product {product_id} successfully indexed in visual search engine",
            "embeddings_id": emb_record["EmbeddingsID"],
            "dimensions": len(vector),
            "vector_sample": vector[:5]
        }), 201
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Failed to extract embedding: {str(e)}"}), 500

@app.route("/api/products", methods=["GET"])
def get_products():
    return jsonify({
        "status": "success",
        "total": len(PRODUCT_METADATA),
        "products": list(PRODUCT_METADATA.values())
    })

@app.route("/api/search/visual", methods=["POST", "OPTIONS"])
def visual_search():
    """
    Main Visual Search Endpoint
    Accepts:
      - Multipart file: 'image'
      - JSON body: {'image': 'data:image/...;base64,...'}
    Extracts dense 512-dim embedding via AI model, computes cosine similarity against
    ProductEmbeddings database, and returns top matched products.
    """
    if request.method == "OPTIONS":
        return "", 200

    image_source = None

    # 1. Check if multipart file upload
    if "image" in request.files:
        image_source = request.files["image"].read()
    # 2. Check if JSON with base64 data
    elif request.is_json:
        data = request.get_json()
        image_source = data.get("image") or data.get("image_url")
    # 3. Check if raw body
    elif request.data:
        image_source = request.data

    if not image_source:
        return jsonify({
            "status": "error",
            "message": "No visual input provided. Please provide an image file or base64 data URL from camera/gallery."
        }), 400

    try:
        # If catalog has 0 embeddings, return clean empty match without error
        if len(CATALOG_EMBEDDINGS) == 0:
            return jsonify({
                "status": "success",
                "model_used": visual_engine.model_name,
                "vector_dimension": visual_engine.dim,
                "total_candidates_searched": 0,
                "results": [],
                "message": "No products registered in catalog yet. Publish products with images to search visually."
            })

        # Extract query vector from input image
        query_vector = visual_engine.extract_embedding(image_source)

        # Rank against catalog embeddings with category gating and 68% threshold
        try:
            top_k = max(1, min(50, int(request.args.get("top_k", 6))))
        except (ValueError, TypeError):
            top_k = 6
        try:
            min_threshold = max(0.0, min(1.0, float(request.args.get("min_threshold", 0.68))))
        except (ValueError, TypeError):
            min_threshold = 0.68

        raw_matches = visual_engine.rank_catalog(query_vector, CATALOG_EMBEDDINGS, top_k=top_k, min_threshold=min_threshold)

        # Enrich matches with product details
        enriched_results = []
        for match in raw_matches:
            prod_id = match["ProductID"]
            meta = PRODUCT_METADATA.get(prod_id, {
                "id": prod_id,
                "name": match.get("Name", f"Product {prod_id}"),
                "category": match.get("Category", "General"),
                "price": match.get("Price", 999.0),
                "rating": 4.8,
                "reviews": 1,
                "img": match.get("Image", ""),
                "desc": match.get("Description", "Catalog product item")
            })
            enriched_results.append({
                **meta,
                "embeddings_id": match["EmbeddingsID"],
                "similarity_score": match["similarity_score"],
                "match_percentage": match["match_percentage"]
            })

        return jsonify({
            "status": "success",
            "model_used": visual_engine.model_name,
            "vector_dimension": len(query_vector),
            "query_embedding_sample": query_vector[:8],
            "total_candidates_searched": len(CATALOG_EMBEDDINGS),
            "results": enriched_results
        })

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({
            "status": "error",
            "message": f"Visual search model failed: {str(e)}"
        }), 500

@app.route("/api/search/text", methods=["GET"])
def text_search():
    """Text-based search for the global search bar suggestions"""
    query = request.args.get("q", "")[:100].strip().lower()
    if not query:
        return jsonify({"results": []})

    results = []
    for p in PRODUCT_METADATA.values():
        if query in p["name"].lower() or query in p["category"].lower() or query in p.get("desc", "").lower():
            results.append(p)

    return jsonify({
        "status": "success",
        "query": query,
        "count": len(results),
        "results": results[:8]
    })

if __name__ == "__main__":
    load_embeddings()
    print("\n=======================================================")
    print("OmniCart Smart Visual Search Backend Server Running")
    print("AI Model: OpenAI CLIP (clip-ViT-B-32) with Zero-Shot Category Gating")
    print("Vector Dimensions: 512 | Schema: ProductEmbeddings")
    print("Confidence Filter: Strict >= 68% (No Category Mismatch)")
    print("API Endpoint: http://127.0.0.1:5000/api/search/visual")
    print("Health Check: http://127.0.0.1:5000/api/health")
    print("=======================================================\n")
    app.run(host="0.0.0.0", port=5000, debug=False)
