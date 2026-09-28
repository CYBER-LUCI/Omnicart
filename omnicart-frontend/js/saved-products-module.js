/**
 * OmniCart SavedProductsModule — Wishlist Controller (saved-products.html)
 * Displays saved items with live stock, move to cart actions, and removal triggers.
 */

const SavedProductsModule = {
  init() {
    this.render();
  },

  render() {
    const authPrompt = document.getElementById('saved-products-auth-prompt');
    const listWrapper = document.getElementById('saved-products-list-wrapper');
    const container = document.getElementById('saved-products-container');
    const countBadge = document.getElementById('saved-total-count');

    if (!DataStore.currentUser || DataStore.currentUserRole !== 'buyer') {
      if (authPrompt) authPrompt.classList.remove('hidden');
      if (listWrapper) listWrapper.classList.add('hidden');
      return;
    }

    if (authPrompt) authPrompt.classList.add('hidden');
    if (listWrapper) listWrapper.classList.remove('hidden');

    const savedIds = DataStore.getSavedProducts();
    const savedItems = DataStore.products.filter(p => savedIds.includes(Number(p.id)));

    if (countBadge) {
      countBadge.innerText = `${savedItems.length} item${savedItems.length === 1 ? '' : 's'}`;
    }

    if (!container) return;

    if (savedItems.length === 0) {
      container.innerHTML = `
        <div class="col-span-full clean-card p-12 text-center text-slate-400">
          <div class="text-5xl mb-3">❤️</div>
          <h3 class="text-base font-bold text-slate-700">Your wishlist is empty</h3>
          <p class="text-xs text-slate-400 mt-1 mb-5">Click the heart icon on any product in our catalog to save it for later.</p>
          <a href="products.html" class="btn-primary text-xs py-2 px-5">Browse Catalog →</a>
        </div>
      `;
      return;
    }

    container.innerHTML = savedItems.map(p => {
      const img = (p.images && p.images.length > 0) ? p.images[0].url : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80';
      const safeName = UIModule.escapeHtml(p.name);
      const safeCat = UIModule.escapeHtml(p.categoryName || 'General');
      const safeImg = UIModule.escapeHtml(img);
      const isOutOfStock = p.stockQuantity <= 0;

      return `
        <div class="clean-card product-card p-4 flex flex-col justify-between">
          <div>
            <div class="img-container h-44 w-full flex items-center justify-center p-2 mb-3 bg-slate-50 rounded-lg relative">
              <a href="product-detail.html?id=${encodeURIComponent(p.code || p.id)}" class="w-full h-full flex items-center justify-center">
                <img src="${safeImg}" alt="${safeName}" class="h-full object-contain" />
              </a>
              <button
                onclick="SavedProductsModule.removeFromSaved(${p.id})"
                class="absolute top-2 right-2 w-7 h-7 rounded-full bg-white/90 border border-slate-200 text-red-500 hover:text-red-700 flex items-center justify-center text-xs shadow-xs"
                title="Remove from saved"
              >
                ✕
              </button>
            </div>

            <span class="text-[11px] text-blue-600 font-semibold block">${safeCat}</span>
            <a href="product-detail.html?id=${encodeURIComponent(p.code || p.id)}" class="font-bold text-slate-900 text-xs hover:text-blue-600 block line-clamp-2 mt-1">
              ${safeName}
            </a>
          </div>

          <div class="pt-3 border-t border-slate-100 mt-3 flex items-center justify-between">
            <span class="font-extrabold text-slate-900 text-sm">${UIModule.formatCurrency(p.currentPrice)}</span>
            ${isOutOfStock ? `
              <span class="badge badge-red text-xs py-1 px-2.5">Sold Out</span>
            ` : `
              <button
                onclick="SavedProductsModule.moveToCart(${p.id})"
                class="btn-primary text-xs py-1.5 px-3"
              >
                Move to Cart
              </button>
            `}
          </div>
        </div>
      `;
    }).join('');
  },

  removeFromSaved(productId) {
    DataStore.toggleSavedProduct(productId);
    this.render();
    UIModule.renderHeader();
    UIModule.showToast('Item removed from wishlist', 'info');
  },

  moveToCart(productId) {
    const prod = DataStore.products.find(p => Number(p.id) === Number(productId));
    if (!prod) {
      UIModule.showToast('Product not found in catalog', 'error');
      return;
    }
    if (prod.stockQuantity <= 0) {
      UIModule.showToast(`"${prod.name}" is currently out of stock.`, 'error');
      return;
    }
    try {
      DataStore.addToCart(prod, 1);
      DataStore.toggleSavedProduct(productId);
      this.render();
      UIModule.renderHeader();
      UIModule.showToast(`Moved "${prod.name}" to your shopping cart!`, 'success');
    } catch (err) {
      UIModule.showToast(err.message || 'Could not move item to cart.', 'error');
    }
  }
};

window.SavedProductsModule = SavedProductsModule;
