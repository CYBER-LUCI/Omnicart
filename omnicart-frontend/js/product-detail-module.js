/**
 * OmniCart ProductDetailModule — Single Product View Controller (product-detail.html)
 * Gallery Switcher, Dynamic Price Ledger History Table, Quantity Controls,
 * Direct Add to Cart, Instant Buy Now, and Wishlist Integration.
 */

const ProductDetailModule = {
  product: null,
  quantity: 1,

  async init() {
    const params = new URLSearchParams(window.location.search);
    const idParam = params.get('id');

    if (!idParam) {
      this.product = DataStore.products[0];
    } else {
      this.product = DataStore.products.find(p => p.code === idParam || String(p.id) === idParam) || DataStore.products[0];
    }

    if (!this.product) {
      UIModule.showToast('Product not found in catalog', 'error');
      const container = document.querySelector('main');
      if (container) {
        container.innerHTML = `
          <div class="max-w-4xl mx-auto py-20 px-4 text-center">
            <div class="text-5xl mb-4">📦</div>
            <h2 class="text-xl font-bold text-slate-800">Product Not Found</h2>
            <p class="text-sm text-slate-500 mt-2">No product is currently selected or the product is no longer available in the catalog.</p>
            <div class="mt-6 flex items-center justify-center gap-4">
              <a href="products.html" class="btn-primary py-2.5 px-6 text-sm">Browse Products →</a>
            </div>
          </div>
        `;
      }
      return;
    }

    // Try fetching latest price ledger & details from backend if available
    try {
      const priceRes = await DataStore.apiRequest(`/products/${this.product.id}/prices`);
      if (priceRes && priceRes.success && Array.isArray(priceRes.data) && priceRes.data.length > 0) {
        this.product.priceLedger = priceRes.data;
      }
    } catch (e) {
      console.warn('[ProductDetail] Local price ledger in use.');
    }

    this.render();
    this.renderRelatedProducts();
  },

  updateQty(delta) {
    if (!this.product) return;
    const maxStock = typeof this.product.stockQuantity === 'number' ? this.product.stockQuantity : 50;
    if (maxStock <= 0) {
      this.quantity = 0;
      const input = document.getElementById('detail-qty-input') || document.querySelector('input[type="number"]');
      if (input) input.value = 0;
      return;
    }
    const nextQty = this.quantity + Number(delta);
    if (nextQty >= 1 && nextQty <= maxStock) {
      this.quantity = nextQty;
      const input = document.getElementById('detail-qty-input') || document.querySelector('input[type="number"]');
      if (input) input.value = this.quantity;
    }
  },

  switchImage(imgUrl) {
    const mainImg = document.getElementById('detail-main-img');
    if (mainImg) {
      mainImg.src = imgUrl;
    }
  },

  addToCart() {
    if (!this.product) return;
    if ((this.product.stockQuantity ?? 1) <= 0) {
      UIModule.showToast('This product is currently out of stock.', 'error');
      return;
    }
    try {
      DataStore.addToCart(this.product, this.quantity);
      UIModule.showToast(`Added ${this.quantity} × ${this.product.name} to your cart!`, 'success');
    } catch (err) {
      UIModule.showToast(err.message, 'error');
    }
  },

  buyNow() {
    if (!this.product) return;
    if ((this.product.stockQuantity ?? 1) <= 0) {
      UIModule.showToast('This product is currently out of stock.', 'error');
      return;
    }
    try {
      DataStore.addToCart(this.product, this.quantity);
      window.location.href = 'checkout.html';
    } catch (err) {
      UIModule.showToast(err.message, 'error');
    }
  },

  toggleSave() {
    this.toggleSaved();
  },

  toggleSaved() {
    if (!this.product) return;
    try {
      const added = DataStore.toggleSavedProduct(this.product.id);
      this.updateWishlistButton();
      UIModule.showToast(added ? 'Saved to your Wishlist!' : 'Removed from Wishlist', 'info');
    } catch (e) {
      // DataStore handles redirect and toast
    }
  },

  updateWishlistButton() {
    if (!this.product) return;
    const isSaved = DataStore.isSaved(this.product.id);

    const btn = document.getElementById('detail-wishlist-btn');
    if (btn) {
      btn.innerHTML = isSaved ? '<span>❤️</span> Saved in Wishlist' : '<span>🤍</span> Save to Wishlist';
    }

    const saveIcon = document.getElementById('detail-save-icon');
    const saveText = document.getElementById('detail-save-text');
    if (saveIcon) saveIcon.innerText = isSaved ? '❤️' : '🤍';
    if (saveText) saveText.innerText = isSaved ? 'Saved' : 'Save';
  },

  render() {
    const p = this.product;
    if (!p) return;

    const primaryImg = (p.images && p.images.length > 0)
      ? (p.images.find(img => img.isPrimary) || p.images[0]).url
      : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80';

    // Main Image & Thumbs
    const mainImg = document.getElementById('detail-main-img');
    if (mainImg) {
      mainImg.src = primaryImg;
      mainImg.alt = p.name;
    }

    const thumbsContainer = document.getElementById('detail-thumbs-container');
    if (thumbsContainer && p.images && p.images.length > 0) {
      thumbsContainer.innerHTML = p.images.map(img => `
        <button
          type="button"
          onclick="ProductDetailModule.switchImage('${img.url}')"
          class="w-16 h-16 rounded-xl border border-slate-200 hover:border-blue-600 bg-white p-1.5 overflow-hidden transition-all shadow-2xs"
        >
          <img src="${img.url}" class="w-full h-full object-contain" />
        </button>
      `).join('');
    }

    // Texts & Badges
    const catBadge = document.getElementById('detail-category-badge');
    const titleElem = document.getElementById('detail-title');
    const codeElem = document.getElementById('detail-code');
    const descElem = document.getElementById('detail-description');
    const priceElem = document.getElementById('detail-price');
    const origPriceElem = document.getElementById('detail-orig-price');
    const discountElem = document.getElementById('detail-discount');
    const stockBadge = document.getElementById('detail-stock-badge');
    const sellerNameElem = document.getElementById('detail-seller-name');
    const sellerGstinElem = document.getElementById('detail-seller-gstin');

    if (catBadge) catBadge.innerText = p.categoryName || 'General';
    if (titleElem) titleElem.innerText = p.name;
    if (codeElem) codeElem.innerText = p.code || `PROD-${p.id}`;
    if (descElem) descElem.innerText = p.description;

    if (priceElem) priceElem.innerText = UIModule.formatCurrency(p.currentPrice);
    if (origPriceElem) origPriceElem.innerText = UIModule.formatCurrency(p.originalPrice);

    const discountPercent = Math.round(((p.originalPrice - p.currentPrice) / p.originalPrice) * 100);
    if (discountElem) discountElem.innerText = `Save ${discountPercent}% (${UIModule.formatCurrency(p.originalPrice - p.currentPrice)})`;

    if (stockBadge) {
      if (p.stockQuantity > 10) {
        stockBadge.className = 'badge badge-green text-xs';
        stockBadge.innerHTML = `<span class="pulse-indicator mr-1"></span> In Stock (${p.stockQuantity} units available)`;
      } else if (p.stockQuantity > 0) {
        stockBadge.className = 'badge badge-amber text-xs';
        stockBadge.innerText = `⚠️ Only ${p.stockQuantity} left — Order soon`;
      } else {
        stockBadge.className = 'badge badge-red text-xs';
        stockBadge.innerText = 'Out of Stock';
      }
    }

    if (sellerNameElem) sellerNameElem.innerText = p.sellerName || 'Verified Merchant';
    if (sellerGstinElem) sellerGstinElem.innerText = p.sellerGstin || 'Verified Seller';

    this.updateWishlistButton();
    this.renderPriceLedgerTable();
  },

  renderPriceLedgerTable() {
    const tbody = document.getElementById('detail-price-ledger-tbody') || document.getElementById('price-ledger-tbody');
    if (!tbody) return;

    const ledger = this.product.priceLedger || [
      { id: 1, price: this.product.currentPrice, changedAt: '2026-09-20 18:00:00', changeReason: 'Current Catalog Price' }
    ];

    tbody.innerHTML = ledger.map((entry, idx) => `
      <tr class="hover:bg-slate-50 transition-colors text-xs">
        <td class="p-3 font-semibold text-slate-800">
          ${idx === 0 ? '<span class="badge badge-green text-[10px] mr-1.5">Active</span>' : ''}
          ${UIModule.formatCurrency(entry.price)}
        </td>
        <td class="p-3 text-slate-500 font-mono text-[11px]">${UIModule.escapeHtml(entry.changedAt || '2026-09-01')}</td>
        <td class="p-3 text-slate-600">${UIModule.escapeHtml(entry.changeReason || 'Verified Price Adjustment')}</td>
      </tr>
    `).join('');
  },

  renderRelatedProducts() {
    const container = document.getElementById('related-products-container');
    if (!container) return;

    const related = DataStore.products.filter(p => p.id !== this.product.id).slice(0, 4);

    container.innerHTML = related.map(p => {
      const img = (p.images && p.images.length > 0) ? p.images[0].url : '';
      const safeName = UIModule.escapeHtml(p.name);
      const isOutOfStock = (p.stockQuantity ?? 1) <= 0;

      return `
        <div class="clean-card p-4 flex flex-col justify-between">
          <a href="product-detail.html?id=${encodeURIComponent(p.code || p.id)}" class="block group">
            <div class="h-36 w-full flex items-center justify-center p-2 mb-3 bg-slate-50 rounded-lg">
              <img src="${img}" alt="${safeName}" class="h-full object-contain group-hover:scale-105 transition-transform" />
            </div>
            <h4 class="text-xs font-bold text-slate-900 line-clamp-2 hover:text-blue-600">${safeName}</h4>
          </a>
          <div class="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between">
            <span class="font-extrabold text-slate-900 text-sm">${UIModule.formatCurrency(p.currentPrice)}</span>
            ${isOutOfStock ? `
              <span class="badge badge-red text-[10px] py-1 px-2">Sold Out</span>
            ` : `
              <button
                type="button"
                onclick="try { DataStore.addToCart(DataStore.products.find(prod => prod.id === ${p.id}), 1); UIModule.showToast('Added to cart!', 'success'); } catch(e){ UIModule.showToast(e.message, 'error'); }"
                class="btn-primary text-xs py-1 px-2.5 cursor-pointer"
              >
                + Cart
              </button>
            `}
          </div>
        </div>
      `;
    }).join('');
  }
};

window.ProductDetailModule = ProductDetailModule;
