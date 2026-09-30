/**
 * OmniCart BuyerModule — Home Page Controller (index.html)
 * Category Pills, Deal of the Day Countdown, Recommendations, and 20-Min Delivery Hub.
 */

const BuyerModule = {
  currentDealProduct: null,
  timerInterval: null,

  init() {
    this.renderCategoryPills();
    this.renderDealOfTheDay();
    this.renderRecommendedProducts();
    this.renderFastDeliveryProducts();
    this.startDealTimer();
    this.initGlobalSearch();
  },

  renderCategoryPills() {
    const container = document.getElementById('category-pills-container');
    if (!container) return;

    const categoryIcons = {
      1: '💻', // Smart Electronics
      2: '🎧', // Audio & Wearables
      3: '👟', // Footwear & Fashion
      4: '🏋️', // Fitness & Sports
      5: '🍳'  // Home & Kitchen
    };

    container.innerHTML = DataStore.categories.map(cat => `
      <a
        href="products.html?category=${cat.id}"
        class="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-slate-200 bg-white hover:border-blue-500 hover:bg-blue-50/40 text-slate-800 text-xs font-semibold whitespace-nowrap transition-all shadow-xs shrink-0"
      >
        <span class="text-base">${categoryIcons[cat.id] || '📦'}</span>
        <span>${UIModule.escapeHtml(cat.name)}</span>
      </a>
    `).join('');
  },

  renderDealOfTheDay() {
    const dealSection = document.getElementById('featured-deal-section');
    const dealProduct = DataStore.products.find(p => p.isDealOfTheDay) || DataStore.products[0];
    if (!dealProduct) {
      if (dealSection) dealSection.classList.add('hidden');
      return;
    }
    if (dealSection) dealSection.classList.remove('hidden');

    this.currentDealProduct = dealProduct;

    const imgElem = document.getElementById('featured-img');
    const thumbsContainer = document.getElementById('featured-thumbs-container');
    const catElem = document.getElementById('featured-category');
    const titleElem = document.getElementById('featured-title');
    const descElem = document.getElementById('featured-desc');
    const priceElem = document.getElementById('featured-price');
    const origPriceElem = document.getElementById('featured-orig-price');
    const discountElem = document.getElementById('featured-discount');
    const stockElem = document.getElementById('featured-stock');
    const link1 = document.getElementById('featured-detail-link');
    const link2 = document.getElementById('featured-detail-link-2');

    const primaryImg = (dealProduct.images && dealProduct.images.length > 0)
      ? (dealProduct.images.find(img => img.isPrimary) || dealProduct.images[0]).url
      : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80';

    if (imgElem) {
      imgElem.src = primaryImg;
      imgElem.alt = dealProduct.name;
    }

    if (thumbsContainer && dealProduct.images && dealProduct.images.length > 1) {
      thumbsContainer.innerHTML = dealProduct.images.map((img, idx) => `
        <button
          onclick="document.getElementById('featured-img').src = '${img.url}'"
          class="w-12 h-12 rounded-lg border border-slate-200 hover:border-blue-600 overflow-hidden p-1 bg-white"
        >
          <img src="${img.url}" class="w-full h-full object-contain" />
        </button>
      `).join('');
    }

    if (catElem) catElem.innerText = dealProduct.categoryName;
    if (titleElem) titleElem.innerText = dealProduct.name;
    if (descElem) descElem.innerText = dealProduct.description;
    if (priceElem) priceElem.innerText = UIModule.formatCurrency(dealProduct.currentPrice);
    if (origPriceElem) origPriceElem.innerText = UIModule.formatCurrency(dealProduct.originalPrice);

    const discountPercent = Math.round(((dealProduct.originalPrice - dealProduct.currentPrice) / dealProduct.originalPrice) * 100);
    if (discountElem) discountElem.innerText = `-${discountPercent}% OFF`;

    if (stockElem) {
      stockElem.innerHTML = `
        <span class="inline-flex items-center gap-1.5 font-bold ${dealProduct.stockQuantity <= 10 ? 'text-amber-600' : 'text-emerald-700'}">
          <span class="pulse-indicator"></span>
          ${dealProduct.stockQuantity} units available in local hub
        </span>
      `;
    }

    const detailUrl = `product-detail.html?id=${dealProduct.code || dealProduct.id}`;
    if (link1) link1.href = detailUrl;
    if (link2) link2.href = detailUrl;
  },

  startDealTimer() {
    const timerElem = document.getElementById('deal-timer');
    if (!timerElem) return;

    let totalSeconds = 3 * 3600 + 42 * 60 + 15; // 03:42:15

    if (this.timerInterval) clearInterval(this.timerInterval);

    this.timerInterval = setInterval(() => {
      totalSeconds--;
      if (totalSeconds < 0) totalSeconds = 4 * 3600;

      const hrs = Math.floor(totalSeconds / 3600).toString().padStart(2, '0');
      const mins = Math.floor((totalSeconds % 3600) / 60).toString().padStart(2, '0');
      const secs = (totalSeconds % 60).toString().padStart(2, '0');

      timerElem.innerText = `${hrs}:${mins}:${secs}`;
    }, 1000);
  },

  addCurrentDealToCart() {
    if (!this.currentDealProduct) return;
    try {
      DataStore.addToCart(this.currentDealProduct, 1);
      UIModule.showToast(`Added ${this.currentDealProduct.name} to cart!`, 'success');
    } catch (err) {
      UIModule.showToast(err.message, 'error');
    }
  },

  renderRecommendedProducts() {
    const container = document.getElementById('recommended-products-container');
    if (!container) return;

    const recommended = DataStore.products.slice(0, 3);
    if (recommended.length === 0) {
      container.innerHTML = `
        <div class="p-6 text-center text-slate-400 bg-white rounded-xl border border-dashed border-slate-200">
          <p class="text-xs">No products listed yet. Products will appear here shortly.</p>
        </div>
      `;
      return;
    }

    container.innerHTML = recommended.map(p => {
      const img = (p.images && p.images.length > 0) ? p.images[0].url : '';
      const isSaved = DataStore.isSaved(p.id);
      const safeName = UIModule.escapeHtml(p.name);
      const safeCat = UIModule.escapeHtml(p.categoryName || 'General');
      const isOutOfStock = (p.stockQuantity ?? 1) <= 0;

      return `
        <div class="flex items-center justify-between gap-4 p-3 rounded-xl border border-slate-100 hover:border-slate-300 bg-white transition-all">
          <a href="product-detail.html?id=${encodeURIComponent(p.code || p.id)}" class="flex items-center gap-3 min-w-0 flex-1">
            <img src="${img}" alt="${safeName}" class="w-14 h-14 object-contain rounded-lg bg-slate-50 p-1 shrink-0" />
            <div class="min-w-0">
              <span class="text-[11px] text-blue-600 font-semibold block">${safeCat}</span>
              <h4 class="text-xs font-bold text-slate-900 truncate hover:text-blue-600">${safeName}</h4>
              <div class="flex items-baseline gap-2 mt-0.5">
                <span class="text-sm font-extrabold text-slate-900">${UIModule.formatCurrency(p.currentPrice)}</span>
                <span class="text-xs text-slate-400 line-through">${UIModule.formatCurrency(p.originalPrice)}</span>
              </div>
            </div>
          </a>

          <div class="flex items-center gap-1.5 shrink-0">
            <button
              type="button"
              onclick="DataStore.toggleSavedProduct(${p.id}); BuyerModule.renderRecommendedProducts(); UIModule.showToast('${isSaved ? 'Removed from saved' : 'Saved to wishlist'}', 'info');"
              class="w-8 h-8 rounded-lg border border-slate-200 hover:bg-slate-50 flex items-center justify-center text-xs transition-colors cursor-pointer"
              title="Save to wishlist"
            >
              ${isSaved ? '❤️' : '🤍'}
            </button>
            ${isOutOfStock ? `
              <span class="badge badge-red text-[11px] py-1.5 px-2.5">Sold Out</span>
            ` : `
              <button
                type="button"
                onclick="try { DataStore.addToCart(DataStore.products.find(prod => prod.id === ${p.id}), 1); UIModule.showToast('Added to cart!', 'success'); } catch(e){ UIModule.showToast(e.message, 'error'); }"
                class="btn-primary text-xs py-1.5 px-3 cursor-pointer"
              >
                + Add
              </button>
            `}
          </div>
        </div>
      `;
    }).join('');
  },

  renderFastDeliveryProducts() {
    const container = document.getElementById('fast-delivery-container');
    if (!container) return;

    const fastList = DataStore.products.filter(p => p.fastDeliveryAvailable).slice(0, 3);
    if (fastList.length === 0) {
      container.innerHTML = `
        <div class="p-6 text-center text-slate-400 bg-white rounded-xl border border-dashed border-slate-200">
          <p class="text-xs">No express delivery items available right now.</p>
        </div>
      `;
      return;
    }

    container.innerHTML = fastList.map(p => {
      const img = (p.images && p.images.length > 0) ? p.images[0].url : '';
      const safeName = UIModule.escapeHtml(p.name);
      const isOutOfStock = (p.stockQuantity ?? 1) <= 0;

      return `
        <div class="flex items-center justify-between gap-4 p-3 rounded-xl border border-slate-100 hover:border-slate-300 bg-white transition-all">
          <a href="product-detail.html?id=${encodeURIComponent(p.code || p.id)}" class="flex items-center gap-3 min-w-0 flex-1">
            <img src="${img}" alt="${safeName}" class="w-14 h-14 object-contain rounded-lg bg-slate-50 p-1 shrink-0" />
            <div class="min-w-0">
              <div class="flex items-center gap-1.5 text-[11px] text-emerald-700 font-semibold">
                <span class="pulse-indicator"></span> 20-min Express Hub
              </div>
              <h4 class="text-xs font-bold text-slate-900 truncate hover:text-blue-600 mt-0.5">${safeName}</h4>
              <div class="text-sm font-extrabold text-slate-900 mt-0.5">${UIModule.formatCurrency(p.currentPrice)}</div>
            </div>
          </a>

          <div class="shrink-0">
            ${isOutOfStock ? `
              <span class="badge badge-red text-[11px] py-1.5 px-2.5">Sold Out</span>
            ` : `
              <button
                type="button"
                onclick="try { DataStore.addToCart(DataStore.products.find(prod => prod.id === ${p.id}), 1); UIModule.showToast('Added for 20-min delivery!', 'success'); } catch(e){ UIModule.showToast(e.message, 'error'); }"
                class="btn-primary bg-emerald-600 hover:bg-emerald-700 text-xs py-1.5 px-3 font-semibold cursor-pointer"
              >
                ⚡ Order
              </button>
            `}
          </div>
        </div>
      `;
    }).join('');
  },

  initGlobalSearch() {
    const inputs = document.querySelectorAll('.global-search-input');
    inputs.forEach(input => {
      input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
          const val = e.target.value.trim();
          if (val) {
            window.location.href = `products.html?search=${encodeURIComponent(val)}`;
          }
        }
      });
    });
  }
};

window.BuyerModule = BuyerModule;
