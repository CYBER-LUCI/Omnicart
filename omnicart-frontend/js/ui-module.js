/**
 * OmniCart UIModule — Shared Visual Components, Toast Notifications,
 * Header State Synchronizer, and Modal Managers.
 */

const UIModule = {
  // Format numbers to Indian Rupee (₹)
  formatCurrency(amount) {
    const num = Number(amount) || 0;
    return `₹${num.toLocaleString('en-IN')}`;
  },

  // Escape HTML entities to prevent Cross-Site Scripting (XSS)
  escapeHtml(str) {
    if (str === null || str === undefined) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  },

  // Toast Notification System (XSS-safe)
  showToast(message, type = 'info', duration = 3500) {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;

    let icon = 'ℹ️';
    if (type === 'success') icon = '✅';
    else if (type === 'error') icon = '⚠️';

    const safeMessage = this.escapeHtml(message);

    toast.innerHTML = `
      <span class="text-base">${icon}</span>
      <span class="flex-1 leading-snug">${safeMessage}</span>
      <button type="button" class="text-white/70 hover:text-white text-xs ml-2 cursor-pointer" onclick="this.parentElement.remove()">✕</button>
    `;

    container.appendChild(toast);

    setTimeout(() => {
      toast.style.animation = 'fadeOut 0.3s ease forwards';
      setTimeout(() => toast.remove(), 300);
    }, duration);
  },

  // Render Rating Stars HTML
  renderRatingStars(rating = 4.8) {
    const score = Math.min(5, Math.max(1, Number(rating) || 4.5));
    const fullStars = Math.floor(score);
    let starsHtml = '';
    for (let i = 0; i < 5; i++) {
      if (i < fullStars) {
        starsHtml += '<span class="text-amber-400">★</span>';
      } else {
        starsHtml += '<span class="text-slate-300">★</span>';
      }
    }
    return `<div class="flex items-center gap-0.5 text-sm">${starsHtml} <span class="text-xs font-bold text-slate-700 ml-1">${score.toFixed(1)}</span></div>`;
  },

  // Header State Renderer (Badges, Login/Logout Dropdown)
  renderHeader() {
    // Badges
    const cartCount = DataStore.getCartCount();
    const savedCount = DataStore.getSavedProducts().length;

    const cartBadge = document.getElementById('header-cart-badge');
    if (cartBadge) {
      cartBadge.innerText = cartCount;
      cartBadge.className = cartCount > 0 ? 'badge badge-blue text-[11px]' : 'badge badge-slate text-[11px]';
    }

    const savedBadge = document.getElementById('header-saved-badge');
    if (savedBadge) {
      savedBadge.innerText = savedCount;
      savedBadge.className = savedCount > 0 ? 'badge badge-blue text-[11px]' : 'badge badge-slate text-[11px]';
    }

    // Guest vs Logged in
    const guestAuth = document.getElementById('header-guest-auth');
    const userAuth = document.getElementById('header-user-auth');
    const userNameElem = document.getElementById('header-user-name');
    const dropdownItems = document.getElementById('auth-dropdown-items');

    if (DataStore.currentUser && DataStore.currentUserRole === 'buyer') {
      if (guestAuth) guestAuth.classList.add('hidden');
      if (userAuth) userAuth.classList.remove('hidden');
      if (userNameElem) userNameElem.innerText = DataStore.currentUser.FirstName || 'My Account';

      if (dropdownItems) {
        const safeFirst = this.escapeHtml(DataStore.currentUser.FirstName || '');
        const safeLast = this.escapeHtml(DataStore.currentUser.LastName || '');
        const safeEmail = this.escapeHtml(DataStore.currentUser.email || '');

        dropdownItems.innerHTML = `
          <div class="px-3 py-2 border-b border-slate-100">
            <p class="font-bold text-slate-900 text-sm">${safeFirst} ${safeLast}</p>
            <p class="text-xs text-slate-500 truncate">${safeEmail}</p>
          </div>
          <div class="py-1">
            <a href="customer-profile.html" class="flex items-center gap-2 px-3 py-2 text-xs text-slate-700 hover:bg-slate-50 rounded-lg">
              <span>👤</span> My Profile & Addresses
            </a>
            <a href="orders.html" class="flex items-center gap-2 px-3 py-2 text-xs text-slate-700 hover:bg-slate-50 rounded-lg">
              <span>📦</span> Track Orders & History
            </a>
            <a href="saved-products.html" class="flex items-center gap-2 px-3 py-2 text-xs text-slate-700 hover:bg-slate-50 rounded-lg">
              <span>❤️</span> Saved Wishlist (${savedCount})
            </a>
          </div>
          <div class="pt-1 border-t border-slate-100">
            <button onclick="AuthModule.logout()" class="w-full text-left flex items-center gap-2 px-3 py-2 text-xs text-red-600 hover:bg-red-50 rounded-lg font-medium cursor-pointer">
              <span>🚪</span> Sign Out
            </button>
          </div>
        `;
      }
    } else if (DataStore.currentSeller && DataStore.currentUserRole === 'seller') {
      if (guestAuth) guestAuth.classList.add('hidden');
      if (userAuth) userAuth.classList.remove('hidden');
      if (userNameElem) userNameElem.innerText = DataStore.currentSeller.CompanyName || 'Merchant';

      if (dropdownItems) {
        const safeCompany = this.escapeHtml(DataStore.currentSeller.CompanyName || 'Merchant Store');
        const safeGstin = this.escapeHtml(DataStore.currentSeller.gstin || 'Unregistered');

        dropdownItems.innerHTML = `
          <div class="px-3 py-2 border-b border-slate-100">
            <p class="font-bold text-slate-900 text-sm">${safeCompany}</p>
            <p class="text-xs text-slate-500 truncate">GSTIN: ${safeGstin}</p>
          </div>
          <div class="py-1">
            <a href="seller-dashboard.html" class="flex items-center gap-2 px-3 py-2 text-xs text-emerald-700 font-semibold hover:bg-emerald-50 rounded-lg">
              <span>🏪</span> Seller Dashboard
            </a>
            <a href="products.html" class="flex items-center gap-2 px-3 py-2 text-xs text-slate-700 hover:bg-slate-50 rounded-lg">
              <span>🛒</span> View Buyer Catalog
            </a>
          </div>
          <div class="pt-1 border-t border-slate-100">
            <button onclick="AuthModule.logout()" class="w-full text-left flex items-center gap-2 px-3 py-2 text-xs text-red-600 hover:bg-red-50 rounded-lg font-medium cursor-pointer">
              <span>🚪</span> Sign Out
            </button>
          </div>
        `;
      }
    } else {
      if (guestAuth) guestAuth.classList.remove('hidden');
      if (userAuth) userAuth.classList.add('hidden');
    }
  },

  // Open Visual Search Trigger
  openVisualSearchModal(mode = 'camera') {
    if (window.VisualSearchModule) {
      window.VisualSearchModule.openModal(mode);
    }
  }
};

window.UIModule = UIModule;
