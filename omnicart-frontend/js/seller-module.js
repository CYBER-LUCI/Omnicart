/**
 * OmniCart SellerModule — Merchant Center & Warehouse Inventory Controller (seller-dashboard.html)
 * Real-time KPI metrics in INR (₹), inventory stock replenishment, dynamic price ledger updating,
 * and order fulfillment management.
 */

const SellerModule = {
  authMode: 'login', // 'login' | 'register'

  async init() {
    this.render();
  },

  setAuthMode(mode) {
    this.authMode = mode;
    this.renderAuthForm();
  },

  render() {
    const authContainer = document.getElementById('seller-auth-container');
    const dashboardContainer = document.getElementById('seller-dashboard-container');

    if (!DataStore.currentSeller || DataStore.currentUserRole !== 'seller') {
      if (authContainer) authContainer.classList.remove('hidden');
      if (dashboardContainer) dashboardContainer.classList.add('hidden');
      this.renderAuthForm();
      return;
    }

    if (authContainer) authContainer.classList.add('hidden');
    if (dashboardContainer) dashboardContainer.classList.remove('hidden');

    const seller = DataStore.currentSeller;
    const nameElem = document.getElementById('seller-store-name');
    const gstinElem = document.getElementById('seller-store-gstin');

    if (nameElem) nameElem.innerText = seller.CompanyName || 'Merchant Store';
    if (gstinElem) gstinElem.innerText = `GSTIN: ${seller.gstin || 'Unregistered'}`;

    this.renderKPIMetrics();
    this.renderInventoryTable();
    this.renderSellerOrders();
  },

  renderAuthForm() {
    const box = document.getElementById('seller-auth-form-box');
    const loginTab = document.getElementById('seller-tab-login');
    const regTab = document.getElementById('seller-tab-register');

    if (this.authMode === 'login') {
      if (loginTab) loginTab.className = 'py-2 rounded-lg font-semibold transition-all bg-white text-emerald-700 shadow-xs border border-slate-200';
      if (regTab) regTab.className = 'py-2 rounded-lg font-medium transition-all text-slate-500 hover:text-slate-800';

      if (box) {
        box.innerHTML = `
          <form onsubmit="SellerModule.handleLogin(event)" class="space-y-4 text-xs">
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Merchant Store Email</label>
              <input type="text" id="sell-login-id" required placeholder="contact@store.in" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Password</label>
              <input type="password" id="sell-login-pw" required placeholder="••••••••" class="clean-input text-xs" />
            </div>
            <button type="submit" class="btn-primary bg-emerald-600 hover:bg-emerald-700 w-full py-2.5 text-xs justify-center font-bold">
              Sign In to Merchant Center →
            </button>
          </form>
        `;
      }
    } else {
      if (regTab) regTab.className = 'py-2 rounded-lg font-semibold transition-all bg-white text-emerald-700 shadow-xs border border-slate-200';
      if (loginTab) loginTab.className = 'py-2 rounded-lg font-medium transition-all text-slate-500 hover:text-slate-800';

      if (box) {
        box.innerHTML = `
          <form onsubmit="SellerModule.handleRegister(event)" class="space-y-3 text-xs">
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Company / Store Name</label>
              <input type="text" id="sell-reg-name" required placeholder="e.g. Apex Hardware Pvt Ltd" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">GSTIN Number (15-digit)</label>
              <input type="text" id="sell-reg-gstin" required placeholder="29ABCDE1234F1Z5" class="clean-input text-xs uppercase" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Business Email</label>
              <input type="email" id="sell-reg-email" required placeholder="orders@company.in" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Password</label>
              <input type="password" id="sell-reg-pw" required placeholder="Set merchant password" class="clean-input text-xs" />
            </div>
            <button type="submit" class="btn-primary bg-emerald-600 hover:bg-emerald-700 w-full py-2.5 text-xs justify-center font-bold">
              Register Merchant Store →
            </button>
          </form>
        `;
      }
    }
  },

  async handleLogin(e) {
    e.preventDefault();
    const id = document.getElementById('sell-login-id').value.trim();
    const pw = document.getElementById('sell-login-pw').value;

    try {
      const seller = await DataStore.loginSeller(id, pw);
      UIModule.showToast(`Authenticated: ${seller.CompanyName}`, 'success');
      UIModule.renderHeader();
      this.render();
    } catch (err) {
      UIModule.showToast(err.message || 'Invalid merchant credentials.', 'error');
    }
  },

  async handleRegister(e) {
    e.preventDefault();
    const name = document.getElementById('sell-reg-name').value.trim();
    const gstin = document.getElementById('sell-reg-gstin').value.trim();
    const email = document.getElementById('sell-reg-email').value.trim();
    const pw = document.getElementById('sell-reg-pw').value;

    try {
      const seller = await DataStore.registerSeller({
        companyName: name,
        gstin: gstin,
        email: email,
        phone: '+91 800 555 1010',
        city: 'Bengaluru, Karnataka',
        password: pw
      });

      UIModule.showToast(`Merchant Store Registered: ${seller.CompanyName}`, 'success');
      UIModule.renderHeader();
      this.render();
    } catch (err) {
      UIModule.showToast(err.message || 'Merchant registration failed.', 'error');
    }
  },

  renderKPIMetrics() {
    const revElem = document.getElementById('seller-kpi-revenue');
    const unitsElem = document.getElementById('seller-kpi-units');
    const skusElem = document.getElementById('seller-kpi-skus');
    const alertsElem = document.getElementById('seller-kpi-alerts');

    const products = DataStore.products;
    const orders = DataStore.orders;

    let totalRevenue = orders.reduce((sum, o) => sum + (o.totalAmount || 0), 0);
    let totalUnitsSold = orders.reduce((sum, o) => {
      return sum + (o.items || []).reduce((itemSum, item) => itemSum + (item.quantity || 1), 0);
    }, 0);

    let lowStockCount = products.filter(p => p.stockQuantity <= 10).length;

    if (revElem) revElem.innerText = UIModule.formatCurrency(totalRevenue);
    if (unitsElem) unitsElem.innerText = `${totalUnitsSold} units`;
    if (skusElem) skusElem.innerText = `${products.length} items`;
    if (alertsElem) alertsElem.innerText = `${lowStockCount} items`;
  },

  renderInventoryTable() {
    const tbody = document.getElementById('seller-inventory-tbody');
    const filterInput = document.getElementById('inventory-filter-input');
    if (!tbody) return;

    const filterVal = filterInput ? filterInput.value.toLowerCase().trim() : '';

    const products = DataStore.products.filter(p => {
      if (!filterVal) return true;
      return `${p.name} ${p.code} ${p.categoryName}`.toLowerCase().includes(filterVal);
    });

    if (products.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="p-6 text-center text-slate-400">No products matching filter.</td></tr>';
      return;
    }

    tbody.innerHTML = products.map(p => {
      const isLowStock = p.stockQuantity <= 10;
      const isOutOfStock = p.stockQuantity <= 0;
      const safeName = UIModule.escapeHtml(p.name);
      const safeCode = UIModule.escapeHtml(p.code || `PROD-${p.id}`);
      const safeCategory = UIModule.escapeHtml(p.categoryName || 'General');

      let statusBadge = '<span class="badge badge-green text-[10px]">In Stock</span>';
      if (isOutOfStock) {
        statusBadge = '<span class="badge badge-red text-[10px]">Out of Stock</span>';
      } else if (isLowStock) {
        statusBadge = '<span class="badge badge-amber text-[10px]">Low Stock</span>';
      }

      return `
        <tr class="hover:bg-slate-50 transition-colors">
          <td class="p-3">
            <span class="font-bold text-slate-900 block text-xs">${safeName}</span>
            <span class="text-[10px] text-slate-400 font-mono">${safeCode}</span>
          </td>
          <td class="p-3 text-slate-600 text-xs">${safeCategory}</td>
          <td class="p-3 font-bold text-slate-900 text-xs">${UIModule.formatCurrency(p.currentPrice)}</td>
          <td class="p-3 font-semibold text-slate-800 text-xs">${p.stockQuantity} units</td>
          <td class="p-3">${statusBadge}</td>
          <td class="p-3 text-right">
            <div class="flex items-center justify-end gap-1.5">
              <button
                onclick="SellerModule.promptUpdateStock(${p.id}, ${p.stockQuantity})"
                class="btn-secondary py-1 px-2 text-[11px] hover:border-blue-500 hover:text-blue-600"
                title="Replenish warehouse inventory"
              >
                Stock
              </button>
              <button
                onclick="SellerModule.promptUpdatePrice(${p.id}, ${p.currentPrice})"
                class="btn-secondary py-1 px-2 text-[11px] hover:border-emerald-500 hover:text-emerald-600"
                title="Append new entry to Price Ledger"
              >
                Price
              </button>
            </div>
          </td>
        </tr>
      `;
    }).join('');
  },

  renderSellerOrders() {
    const container = document.getElementById('seller-orders-container');
    if (!container) return;

    const orders = DataStore.orders;

    if (orders.length === 0) {
      container.innerHTML = '<p class="text-xs text-slate-400 p-4 text-center">No customer orders recorded yet.</p>';
      return;
    }

    container.innerHTML = orders.map(o => {
      const safeOrderNum = UIModule.escapeHtml(o.orderNumber || `ORD-${o.id}`);
      const safeStatus = UIModule.escapeHtml(o.shippingStatus || 'ORDER_PLACED');
      const safeBuyer = UIModule.escapeHtml(o.customerName || 'Customer');

      return `
      <div class="p-3 rounded-xl border border-slate-100 bg-slate-50/50 space-y-2 text-xs">
        <div class="flex items-center justify-between">
          <span class="font-mono font-bold text-slate-900">${safeOrderNum}</span>
          <span class="badge badge-blue text-[10px]">${safeStatus}</span>
        </div>
        <div class="flex items-center justify-between text-slate-500 text-[11px]">
          <span>Buyer: <strong>${safeBuyer}</strong></span>
          <strong class="text-slate-900">${UIModule.formatCurrency(o.totalAmount || o.subtotal)}</strong>
        </div>
        <div class="pt-1 flex items-center justify-between border-t border-slate-200/60">
          <span class="text-[10px] text-slate-400">${(o.items || []).length} items</span>
          <select
            onchange="SellerModule.updateOrderStatus(${o.id}, this.value)"
            class="text-[11px] py-0.5 px-2 rounded-md border border-slate-200 bg-white font-medium text-slate-700"
          >
            <option value="ORDER_PLACED" ${o.shippingStatus === 'ORDER_PLACED' ? 'selected' : ''}>Order Placed</option>
            <option value="PROCESSING" ${o.shippingStatus === 'PROCESSING' ? 'selected' : ''}>Processing</option>
            <option value="SHIPPED" ${o.shippingStatus === 'SHIPPED' ? 'selected' : ''}>Shipped</option>
            <option value="OUT_FOR_DELIVERY" ${o.shippingStatus === 'OUT_FOR_DELIVERY' ? 'selected' : ''}>Out for Delivery</option>
            <option value="DELIVERED" ${o.shippingStatus === 'DELIVERED' ? 'selected' : ''}>Delivered</option>
          </select>
        </div>
      </div>
    `;
    }).join('');
  },

  openAddProductModal() {
    const modal = document.getElementById('add-product-modal');
    const catSelect = document.getElementById('new-prod-cat') || document.getElementById('prod-category');
    if (catSelect && DataStore.categories && DataStore.categories.length > 0) {
      catSelect.innerHTML = DataStore.categories.map(c => `
        <option value="${c.id}">${UIModule.escapeHtml(c.name)}</option>
      `).join('');
    }
    if (modal) modal.classList.remove('hidden');
  },

  closeAddProductModal() {
    const modal = document.getElementById('add-product-modal');
    if (modal) modal.classList.add('hidden');
  },

  async handleAddProductSubmit(e) {
    e.preventDefault();
    const name = (document.getElementById('new-prod-name') || document.getElementById('prod-name')).value.trim();
    const catId = (document.getElementById('new-prod-cat') || document.getElementById('prod-category')).value;
    const priceVal = (document.getElementById('new-prod-price') || document.getElementById('prod-price')).value;
    const stockVal = (document.getElementById('new-prod-stock') || document.getElementById('prod-stock')).value;
    const desc = (document.getElementById('new-prod-desc') || document.getElementById('prod-desc')).value.trim();
    const imgUrl = (document.getElementById('new-prod-img') || document.getElementById('prod-img-url')).value.trim();

    const price = parseFloat(priceVal);
    if (isNaN(price) || price <= 0) {
      UIModule.showToast('Please enter a valid positive price in INR (₹)', 'error');
      return;
    }

    const stock = parseInt(stockVal, 10);
    if (isNaN(stock) || stock < 0) {
      UIModule.showToast('Please enter a valid non-negative stock quantity', 'error');
      return;
    }

    const categoryObj = DataStore.categories.find(c => String(c.id) === String(catId));

    try {
      await DataStore.addProduct({
        name: name,
        categoryId: catId,
        categoryName: categoryObj ? categoryObj.name : 'Smart Electronics',
        currentPrice: price,
        initialPrice: price,
        stockQuantity: stock,
        description: desc,
        imageUrl: imgUrl || 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80'
      });

      this.closeAddProductModal();
      e.target.reset();
      UIModule.showToast(`Product "${name}" published to catalog and Price Ledger initialized!`, 'success');
      this.render();
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to add product.', 'error');
    }
  },

  async promptUpdateStock(productId, currentStock) {
    const input = prompt(`Update Warehouse Stock for Product #${productId}:`, currentStock);
    if (input !== null && input.trim() !== '') {
      const newQty = parseInt(input, 10);
      if (!isNaN(newQty) && newQty >= 0) {
        try {
          await DataStore.updateStock(productId, newQty);
          UIModule.showToast(`Stock updated to ${newQty} units`, 'success');
          this.render();
        } catch (err) {
          UIModule.showToast(err.message || 'Failed to update stock.', 'error');
        }
      } else {
        UIModule.showToast('Invalid stock quantity entered. Must be 0 or greater.', 'error');
      }
    }
  },

  async promptUpdatePrice(productId, currentPrice) {
    const input = prompt(`Append new Price Ledger entry in Rupees (₹) for Product #${productId}:`, currentPrice);
    if (input !== null && input.trim() !== '') {
      const newPrice = parseFloat(input);
      if (!isNaN(newPrice) && newPrice > 0) {
        const rawReason = prompt('Reason for price adjustment (Audit Trail):', 'Competitive Market Update') || 'Price Adjustment';
        const safeReason = rawReason.trim().substring(0, 200);
        try {
          await DataStore.updatePrice(productId, newPrice, safeReason);
          UIModule.showToast(`Price updated to ${UIModule.formatCurrency(newPrice)} and logged in Price Ledger`, 'success');
          this.render();
        } catch (err) {
          UIModule.showToast(err.message || 'Failed to update price.', 'error');
        }
      } else {
        UIModule.showToast('Invalid price entered. Must be a positive amount in INR (₹).', 'error');
      }
    }
  },

  async updateOrderStatus(orderId, newStatus) {
    try {
      await DataStore.updateOrderStatus(orderId, newStatus);
      UIModule.showToast(`Order #${orderId} status updated to ${newStatus}`, 'success');
      await this.fetchSellerOrders();
      this.render();
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to update order status.', 'error');
    }
  }
};

window.SellerModule = SellerModule;
