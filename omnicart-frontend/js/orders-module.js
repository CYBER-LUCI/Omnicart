/**
 * OmniCart OrdersModule — Order History & 20-Min Delivery Tracking Controller (orders.html)
 * Real-time shipment status tracker, multi-item order breakdown, and cancellation logic.
 */

const OrdersModule = {
  async init() {
    // Try fetching customer orders from backend
    if (DataStore.currentUser) {
      try {
        const res = await DataStore.apiRequest(`/customers/${DataStore.currentUser.id}/orders`);
        if (res && res.success && res.data && Array.isArray(res.data.content)) {
          DataStore.orders = res.data.content;
          localStorage.setItem('omnicart_orders', JSON.stringify(DataStore.orders));
        }
      } catch (e) {
        console.warn('[OrdersModule] Using cached orders.');
      }
    }

    this.renderOrdersList();
  },

  renderOrdersList() {
    const container = document.getElementById('orders-list-container');
    if (!container) return;

    const orders = DataStore.orders;

    if (!orders || orders.length === 0) {
      container.innerHTML = `
        <div class="clean-card p-12 text-center text-slate-400">
          <div class="text-5xl mb-3">📦</div>
          <h3 class="text-lg font-bold text-slate-700">No orders placed yet</h3>
          <p class="text-xs text-slate-400 mt-1 mb-5">When you place orders, live shipment tracking and invoice details will appear here.</p>
          <a href="products.html" class="btn-primary text-xs py-2.5 px-6">Start Shopping →</a>
        </div>
      `;
      return;
    }

    container.innerHTML = orders.map(order => {
      const isCancelled = order.shippingStatus === 'CANCELLED';
      const isDelivered = order.shippingStatus === 'DELIVERED';
      const isOutForDelivery = order.shippingStatus === 'OUT_FOR_DELIVERY';

      const statusMap = {
        'ORDER_PLACED': { text: 'Order Placed', badge: 'badge-blue', step: 1 },
        'PROCESSING': { text: 'Verified at Hub', badge: 'badge-blue', step: 2 },
        'SHIPPED': { text: 'Dispatched', badge: 'badge-blue', step: 3 },
        'OUT_FOR_DELIVERY': { text: 'Out for Delivery (20-Min)', badge: 'badge-green', step: 4 },
        'DELIVERED': { text: 'Delivered', badge: 'badge-green', step: 5 },
        'CANCELLED': { text: 'Cancelled', badge: 'badge-red', step: 0 }
      };

      const statusInfo = statusMap[order.shippingStatus] || statusMap['ORDER_PLACED'];
      const activeStep = statusInfo.step;
      const safeOrderNum = UIModule.escapeHtml(order.orderNumber || `ORD-${order.id}`);
      const safeOrderDate = UIModule.escapeHtml(order.orderDate || 'Today');
      const safePayMethod = UIModule.escapeHtml(order.paymentMethod || 'UPI');
      const safeAddress = UIModule.escapeHtml(order.deliveryAddress || 'Bengaluru, Karnataka');

      return `
        <div class="clean-card p-6 sm:p-7 space-y-6 mb-6">
          
          <!-- Order Card Header -->
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-100">
            <div>
              <div class="flex items-center gap-2.5">
                <span class="font-extrabold text-slate-900 text-base font-mono">${safeOrderNum}</span>
                <span class="badge ${statusInfo.badge}">${statusInfo.text}</span>
              </div>
              <p class="text-xs text-slate-500 mt-1">Placed on <strong>${safeOrderDate}</strong> • Paid via ${safePayMethod}</p>
            </div>

            <div class="text-left sm:text-right">
              <span class="text-xs text-slate-400 block font-medium">Total Paid</span>
              <span class="text-xl font-extrabold text-blue-600">${UIModule.formatCurrency(order.totalAmount || order.subtotal)}</span>
            </div>
          </div>

          <!-- Live Shipment Tracker (5 Steps) -->
          ${!isCancelled ? `
            <div class="py-2">
              <div class="flex items-center justify-between">
                <div class="tracker-step ${activeStep >= 1 ? (activeStep > 1 ? 'completed' : 'active') : ''}">
                  <div class="tracker-step-icon">${activeStep > 1 ? '✓' : '1'}</div>
                  <span class="text-[11px] font-semibold text-slate-700 mt-1.5 text-center">Placed</span>
                </div>
                <div class="tracker-step ${activeStep >= 2 ? (activeStep > 2 ? 'completed' : 'active') : ''}">
                  <div class="tracker-step-icon">${activeStep > 2 ? '✓' : '2'}</div>
                  <span class="text-[11px] font-semibold text-slate-700 mt-1.5 text-center">Packed</span>
                </div>
                <div class="tracker-step ${activeStep >= 3 ? (activeStep > 3 ? 'completed' : 'active') : ''}">
                  <div class="tracker-step-icon">${activeStep > 3 ? '✓' : '3'}</div>
                  <span class="text-[11px] font-semibold text-slate-700 mt-1.5 text-center">Dispatched</span>
                </div>
                <div class="tracker-step ${activeStep >= 4 ? (activeStep > 4 ? 'completed' : 'active') : ''}">
                  <div class="tracker-step-icon">${activeStep > 4 ? '✓' : '4'}</div>
                  <span class="text-[11px] font-semibold text-slate-700 mt-1.5 text-center">Near You (20m)</span>
                </div>
                <div class="tracker-step ${activeStep >= 5 ? 'completed' : ''}">
                  <div class="tracker-step-icon">${activeStep >= 5 ? '✓' : '5'}</div>
                  <span class="text-[11px] font-semibold text-slate-700 mt-1.5 text-center">Delivered</span>
                </div>
              </div>
            </div>
          ` : `
            <div class="p-3.5 bg-red-50 rounded-xl border border-red-200 text-xs text-red-700 flex items-center gap-2">
              <span>🛑</span>
              <span>This order has been cancelled and stock inventory restored.</span>
            </div>
          `}

          <!-- Order Items List -->
          <div class="divide-y divide-slate-100 bg-slate-50/50 rounded-xl p-4 border border-slate-100">
            ${(order.items || []).map(item => {
              const safeItemName = UIModule.escapeHtml(item.name || 'Product');
              const safeImg = UIModule.escapeHtml(item.image || 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80');
              const itemTotal = Math.round(item.price * item.quantity * 100) / 100;
              return `
              <div class="flex items-center justify-between py-2.5 first:pt-0 last:pb-0">
                <div class="flex items-center gap-3">
                  <img src="${safeImg}" alt="${safeItemName}" class="w-12 h-12 object-contain bg-white rounded-lg p-1 border border-slate-200 shrink-0" />
                  <div>
                    <h5 class="text-xs font-bold text-slate-900">${safeItemName}</h5>
                    <span class="text-[11px] text-slate-500">Qty: ${item.quantity} × ${UIModule.formatCurrency(item.price)}</span>
                  </div>
                </div>
                <strong class="text-xs font-extrabold text-slate-900">${UIModule.formatCurrency(itemTotal)}</strong>
              </div>
            `;
            }).join('')}
          </div>

          <!-- Order Footer Details & Actions -->
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs pt-2">
            <div class="text-slate-500">
              <span>📍 Delivery Destination: </span>
              <strong class="text-slate-800">${safeAddress}</strong>
            </div>

            <div class="flex items-center gap-2 shrink-0">
              ${(!isCancelled && !isDelivered) ? `
                <button
                  onclick="OrdersModule.cancelOrder(${order.id})"
                  class="btn-secondary text-xs py-1.5 px-3 text-red-600 hover:bg-red-50 hover:border-red-200"
                >
                  Cancel Order
                </button>
              ` : ''}
"              <button\n                onclick=\"OrdersModule.downloadInvoice(${order.id})\"\n                class=\"btn-secondary text-xs py-1.5 px-3 flex items-center gap-1.5 hover:bg-slate-100\"\n              >\n                <span>📄</span>\n                <span>Download Invoice (PDF)</span>\n              </button>\n            </div>\n          </div>\n\n        </div>\n      `;\n    }).join('');\n  },\n\n  numberToWordsINR(amount) {\n    const units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];\n    const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];\n    function convertLessThanOneThousand(n) {\n      if (n === 0) return '';\n      let s = '';\n      if (n >= 100) {\n        s += units[Math.floor(n / 100)] + ' Hundred ';\n        n %= 100;\n      }\n      if (n >= 20) {\n        s += tens[Math.floor(n / 10)] + ' ';\n        n %= 10;\n      }\n      if (n > 0) {\n        s += units[n] + ' ';\n      }\n      return s;\n    }\n    const num = Math.floor(amount);\n    if (num === 0) return 'Rupees Zero Only';\n    let res = '';\n    const crore = Math.floor(num / 10000000);\n    const lakh = Math.floor((num % 10000000) / 100000);\n    const thousand = Math.floor((num % 100000) / 1000);\n    const remainder = num % 1000;\n    if (crore > 0) res += convertLessThanOneThousand(crore) + 'Crore ';\n    if (lakh > 0) res += convertLessThanOneThousand(lakh) + 'Lakh ';\n    if (thousand > 0) res += convertLessThanOneThousand(thousand) + 'Thousand ';\n    if (remainder > 0) res += convertLessThanOneThousand(remainder);\n    return 'Rupees ' + res.trim() + ' Only';\n  },\n\n  async downloadInvoice(orderId) {\n    let order = (DataStore.orders || []).find(o => Number(o.id) === Number(orderId));\n    if (!order) {\n      try {\n        const res = await DataStore.apiRequest(`/orders/${orderId}`);\n        if (res && res.succ
<truncated 14131 bytes>
    if (!confirm('Are you sure you want to cancel this order? Stock will be immediately restored.')) {
      return;
    }

    try {
      await DataStore.cancelOrder(orderId);
      UIModule.showToast('Order cancelled successfully and stock restored', 'info');
      this.renderOrdersList();
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to cancel order.', 'error');
    }
  }
};

window.OrdersModule = OrdersModule;
