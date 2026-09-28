/**
 * OmniCart CatalogModule — Catalog Filtering & Search Controller (products.html)
 * Category Filtering, Seller Filtering, In-Stock Toggling, Price Sorting, and Grid Rendering.
 */

const CatalogModule = {
  selectedCategoryId: null,
  selectedSellerId: null,
  stockOnly: false,
  searchKeyword: '',
  sortOption: 'recommended', // 'recommended' | 'price-low' | 'price-high' | 'rating'

  init() {
    // Parse URL parameters
    const params = new URLSearchParams(window.location.search);
    const reqCat = params.get('category');
    const reqSearch = params.get('search');
    const reqSeller = params.get('seller');

    if (reqCat) this.selectedCategoryId = Number(reqCat);
    if (reqSearch) this.searchKeyword = reqSearch;
    if (reqSeller) this.selectedSellerId = Number(reqSeller);

    const searchInput = document.querySelector('.global-search-input') || document.querySelector('input[placeholder*="Search"]');
    if (searchInput && this.searchKeyword) {
      searchInput.value = this.searchKeyword;
    }

    this.renderCategoryFilters();
    this.renderProductsGrid();
  },

  renderCategoryFilters() {
    const container = document.getElementById('catalog-category-filter');
    if (!container) return;

    const allActive = !this.selectedCategoryId ? 'font-bold text-blue-600 bg-blue-50' : 'text-slate-600 hover:bg-slate-50';

    let html = `
      <button
        onclick="CatalogModule.handleCategoryFilter(null)"
        class="w-full text-left px-3 py-2 rounded-lg text-xs transition-colors flex items-center justify-between ${allActive}"
      >
        <span>All Categories</span>
        <span class="badge badge-slate text-[10px]">${DataStore.products.length}</span>
      </button>
    `;

    DataStore.categories.forEach(cat => {
      const isSelected = this.selectedCategoryId === Number(cat.id);
      const activeClass = isSelected ? 'font-bold text-blue-600 bg-blue-50' : 'text-slate-600 hover:bg-slate-50';
      const count = DataStore.products.filter(p => Number(p.categoryId) === Number(cat.id)).length;

      html += `
        <button
          onclick="CatalogModule.handleCategoryFilter(${cat.id})"
          class="w-full text-left px-3 py-2 rounded-lg text-xs transition-colors flex items-center justify-between ${activeClass}"
        >
          <span>${UIModule.escapeHtml(cat.name)}</span>
          <span class="badge badge-slate text-[10px]">${count}</span>
        </button>
      `;
    });

    container.innerHTML = html;
  },

  handleCategoryFilter(catId) {
    this.selectedCategoryId = catId ? Number(catId) : null;
    this.renderCategoryFilters();
    this.renderProductsGrid();
  },

  handleSellerChange(sellerId) {
    this.selectedSellerId = sellerId ? Number(sellerId) : null;
    this.renderProductsGrid();
  },

  toggleStockOnly(checked) {
    this.stockOnly = Boolean(checked);
    this.renderProductsGrid();
  },

  handleSearchInput(keyword) {
    this.searchKeyword = keyword.trim().toLowerCase();
    this.renderProductsGrid();
  },

  handleSortChange(sortKey) {
    this.sortOption = sortKey;
    this.renderProductsGrid();
  },

  getFilteredProducts() {
    return DataStore.products.filter(p => {
      // Category filter
      if (this.selectedCategoryId && Number(p.categoryId) !== Number(this.selectedCategoryId)) {
        return false;
      }
      // Seller filter
      if (this.selectedSellerId && Number(p.sellerId) !== Number(this.selectedSellerId)) {
        return false;
      }
      // In-stock filter
      if (this.stockOnly && p.stockQuantity <= 0) {
        return false;
      }
      // Search keyword
      if (this.searchKeyword) {
        const text = `${p.name} ${p.description} ${p.categoryName} ${p.code}`.toLowerCase();
        if (!text.includes(this.searchKeyword)) {
          return false;
        }
      }
      return true;
    }).sort((a, b) => {
      if (this.sortOption === 'price-low') return a.currentPrice - b.currentPrice;
      if (this.sortOption === 'price-high') return b.currentPrice - a.currentPrice;
      if (this.sortOption === 'rating') return (b.rating || 4.5) - (a.rating || 4.5);
      return 0; // Default recommended
    });
  },

  renderProductsGrid() {
    const container = document.getElementById('catalog-products-container') || document.getElementById('products-grid-container');
    const countBadge = document.getElementById('catalog-results-count') || document.getElementById('catalog-count');

    if (!container) return;

    const filtered = this.getFilteredProducts();

    if (countBadge) {
      countBadge.innerText = `${filtered.length} Product${filtered.length === 1 ? '' : 's'}`;
    }

    if (filtered.length === 0) {
      container.innerHTML = `
        <div class="col-span-full clean-card p-12 text-center text-slate-400">
          <div class="text-4xl mb-2">🔍</div>
          <h3 class="text-base font-bold text-slate-700">No products found</h3>
          <p class="text-xs text-slate-400 mt-1">Try relaxing your search filters or browse all categories.</p>
          <button onclick="CatalogModule.handleCategoryFilter(null); CatalogModule.searchKeyword='';" class="btn-secondary text-xs mt-4 py-2 px-4">
            Reset Filters
          </button>
        </div>
      `;
      return;
    }

    container.innerHTML = filtered.map(p => {
      const primaryImg = (p.images && p.images.length > 0) ? p.images[0].url : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80';
      const isSaved = DataStore.isSaved(p.id);
      const discountPercent = Math.round(((p.originalPrice - p.currentPrice) / p.originalPrice) * 100);
      const safeName = UIModule.escapeHtml(p.name);
      const safeCat = UIModule.escapeHtml(p.categoryName || 'General');
      const isOutOfStock = (p.stockQuantity ?? 1) <= 0;

      return `
        <div class="clean-card product-card flex flex-col justify-between overflow-hidden group">
          
          <div class="p-4 pb-0">
            <!-- Image Frame -->
            <div class="img-container relative h-48 w-full flex items-center justify-center p-3">
              <a href="product-detail.html?id=${encodeURIComponent(p.code || p.id)}" class="w-full h-full flex items-center justify-center">
                <img src="${primaryImg}" alt="${safeName}" class="w-full h-full object-contain" />
              </a>

              <!-- Wishlist Floating Button -->
              <button
                type="button"
                onclick="DataStore.toggleSavedProduct(${p.id}); CatalogModule.renderProductsGrid(); UIModule.showToast('${isSaved ? 'Removed from wishlist' : 'Added to wishlist'}', 'info');"
                class="absolute top-2.5 right-2.5 w-8 h-8 rounded-full bg-white/90 backdrop-blur-xs border border-slate-200 hover:bg-white flex items-center justify-center text-xs shadow-xs transition-transform hover:scale-110 cursor-pointer"
              >
                ${isSaved ? '❤️' : '🤍'}
              </button>

              <!-- Express Delivery Tag -->
              ${p.fastDeliveryAvailable ? `
                <span class="absolute bottom-2 left-2 badge badge-green text-[10px] font-bold">
                  ⚡ 20-min hub
                </span>
              ` : ''}
            </div>

            <!-- Meta Details -->
            <div class="mt-3 space-y-1">
              <div class="flex items-center justify-between text-[11px]">
                <span class="text-blue-600 font-semibold">${safeCat}</span>
                <span class="text-slate-400 font-medium">★ ${p.rating || 4.8}</span>
              </div>

              <a href="product-detail.html?id=${encodeURIComponent(p.code || p.id)}" class="font-bold text-slate-900 text-sm block leading-snug line-clamp-2 hover:text-blue-600 transition-colors">
                ${safeName}
              </a>
            </div>
          </div>

          <!-- Price & Actions Footer -->
          <div class="p-4 pt-3 border-t border-slate-100 mt-3 flex items-center justify-between">
            <div>
              <div class="flex items-baseline gap-1.5">
                <span class="text-lg font-extrabold text-slate-900">${UIModule.formatCurrency(p.currentPrice)}</span>
                <span class="text-xs text-slate-400 line-through">${UIModule.formatCurrency(p.originalPrice)}</span>
              </div>
              <span class="text-[10px] text-emerald-600 font-semibold">${discountPercent}% OFF</span>
            </div>

            ${isOutOfStock ? `
              <span class="badge badge-red text-xs py-1.5 px-3">Out of Stock</span>
            ` : `
              <button
                type="button"
                onclick="try { DataStore.addToCart(DataStore.products.find(prod => prod.id === ${p.id}), 1); UIModule.showToast('Added to cart!', 'success'); } catch(e){ UIModule.showToast(e.message, 'error'); }"
                class="btn-primary text-xs py-2 px-3.5 shadow-xs cursor-pointer"
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

window.CatalogModule = CatalogModule;
