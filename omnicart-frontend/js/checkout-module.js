/**
 * OmniCart CheckoutModule — Cart Management & ACID Checkout Controller
 * Powers both cart.html and checkout.html with real-time tax/discount computation,
 * address selection, payment method selection, and transactional order placement.
 */

const CheckoutModule = {
  appliedVoucher: localStorage.getItem('omnicart_voucher') || null,
  voucherDiscount: Number(localStorage.getItem('omnicart_discount') || 0),
  selectedAddressId: null,
  selectedPaymentMethod: 'UPI Instant Transfer (Google Pay / PhonePe / Paytm)',
  selectedPaymentMethodId: 3,

  async init() {
    const isCartPage = window.location.pathname.includes('cart.html');
    const isCheckoutPage = window.location.pathname.includes('checkout.html');

    if (isCartPage) {
      this.renderCartPage();
    } else if (isCheckoutPage) {
      if (DataStore.currentUser && DataStore.currentUserRole === 'buyer') {
        try {
          await DataStore.fetchCustomerAddresses();
        } catch (_) {}
      }
      this.renderCheckoutPage();
    }
  },

  // -------------------------------------------------------------
  // CART.HTML METHODS
  // -------------------------------------------------------------
  renderCartPage() {
    const emptyMsg = document.getElementById('cart-empty-message');
    const tableWrapper = document.getElementById('cart-table-wrapper');
    const tbody = document.getElementById('cart-page-tbody');
    const subtotalElem = document.getElementById('summary-subtotal');
    const discountElem = document.getElementById('summary-discount');
    const finalTotalElem = document.getElementById('summary-final-total') || document.getElementById('summary-total');
    const checkoutBtn = document.getElementById('checkout-action-btn');

    const cart = DataStore.getCart();

    if (cart.length === 0) {
      if (emptyMsg) emptyMsg.classList.remove('hidden');
      if (tableWrapper) tableWrapper.classList.add('hidden');
      if (subtotalElem) subtotalElem.innerText = '₹0';
      if (finalTotalElem) finalTotalElem.innerText = '₹0';
      if (checkoutBtn) {
        checkoutBtn.classList.add('opacity-50', 'pointer-events-none');
      }
      return;
    }

    if (emptyMsg) emptyMsg.classList.add('hidden');
    if (tableWrapper) tableWrapper.classList.remove('hidden');
    if (checkoutBtn) {
      checkoutBtn.classList.remove('opacity-50', 'pointer-events-none');
    }

    if (tbody) {
      tbody.innerHTML = cart.map(item => {
        const liveProd = (DataStore.products || []).find(p => p.id === item.id);
        const availableStock = liveProd ? liveProd.stockQuantity : 99;
        const isExceedingStock = item.quantity > availableStock;
        const safeName = UIModule.escapeHtml(item.name || 'Product');
        const safeCat = UIModule.escapeHtml(item.categoryName || 'General');
        const safeCode = UIModule.escapeHtml(item.code || `PROD-${item.id}`);
        const safeImg = UIModule.escapeHtml(item.image || 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80');

        return `
        <tr class="hover:bg-slate-50 transition-colors">
          <!-- Product Name & Image -->
          <td class="py-4 px-2">
            <div class="flex items-center gap-3">
              <img src="${safeImg}" alt="${safeName}" class="w-14 h-14 object-contain rounded-lg bg-slate-50 p-1 border border-slate-100 shrink-0" />
              <div>
                <span class="text-[11px] text-blue-600 font-semibold block">${safeCat}</span>
                <a href="product-detail.html?id=${encodeURIComponent(item.code || item.id)}" class="font-bold text-slate-900 text-xs sm:text-sm hover:text-blue-600 block line-clamp-1">
                  ${safeName}
                </a>
                <span class="text-[11px] text-slate-400 font-mono">${safeCode}</span>
                ${isExceedingStock ? `<span class="text-[10px] text-red-600 font-semibold block mt-0.5">⚠️ Only ${availableStock} in stock</span>` : ''}
              </div>
            </div>
          </td>

          <!-- Unit Price -->
          <td class="py-4 px-2 font-semibold text-slate-800 text-xs sm:text-sm">
            ${UIModule.formatCurrency(item.price)}
          </td>

          <!-- Quantity Stepper -->
          <td class="py-4 px-2">
            <div class="flex items-center border border-slate-200 rounded-lg overflow-hidden w-24 bg-white">
              <button
                onclick="CheckoutModule.updateCartItemQty(${item.id}, ${item.quantity - 1})"
                class="w-7 h-7 flex items-center justify-center hover:bg-slate-100 text-slate-600 font-bold"
              >
                -
              </button>
              <span class="flex-1 text-center font-bold text-xs">${item.quantity}</span>
              <button
                onclick="CheckoutModule.updateCartItemQty(${item.id}, ${item.quantity + 1})"
                class="w-7 h-7 flex items-center justify-center hover:bg-slate-100 text-slate-600 font-bold"
              >
                +
              </button>
            </div>
          </td>

          <!-- Line Subtotal -->
          <td class="py-4 px-2 font-extrabold text-slate-900 text-xs sm:text-sm">
            ${UIModule.formatCurrency(Math.round(item.price * item.quantity * 100) / 100)}
          </td>

          <!-- Remove Action -->
          <td class="py-4 px-2 text-right">
            <button
              onclick="CheckoutModule.removeCartItem(${item.id})"
              class="w-7 h-7 rounded-lg hover:bg-red-50 text-red-500 hover:text-red-700 text-xs inline-flex items-center justify-center transition-colors"
              title="Remove item"
            >
              ✕
            </button>
          </td>
        </tr>
      `;
      }).join('');
    }

    const subtotal = DataStore.getCartSubtotal();
    const discount = Math.min(this.voucherDiscount, subtotal);
    const finalTotal = Math.max(0, Math.round((subtotal - discount) * 100) / 100);

    if (subtotalElem) subtotalElem.innerText = UIModule.formatCurrency(subtotal);
    if (discountElem) discountElem.innerText = discount > 0 ? `-${UIModule.formatCurrency(discount)}` : '₹0';
    if (finalTotalElem) finalTotalElem.innerText = UIModule.formatCurrency(finalTotal);
  },

  updateCartItemQty(productId, newQty) {
    DataStore.updateCartQty(productId, newQty);
    this.renderCartPage();
    UIModule.renderHeader();
  },

  removeCartItem(productId) {
    DataStore.removeFromCart(productId);
    this.renderCartPage();
    UIModule.renderHeader();
    UIModule.showToast('Item removed from cart', 'info');
  },

  applyPromoCode() {
    const input = document.getElementById('cart-promo-input');
    if (!input) return;

    const code = input.value.trim().toUpperCase();
    if (code === 'FESTIVE-LIGHT') {
      this.appliedVoucher = 'FESTIVE-LIGHT';
      this.voucherDiscount = 250;
      localStorage.setItem('omnicart_voucher', 'FESTIVE-LIGHT');
      localStorage.setItem('omnicart_discount', '250');
      UIModule.showToast('Voucher applied: ₹250 discount deducted!', 'success');
      this.renderCartPage();
    } else if (code === 'FIRST50') {
      this.appliedVoucher = 'FIRST50';
      this.voucherDiscount = 50;
      localStorage.setItem('omnicart_voucher', 'FIRST50');
      localStorage.setItem('omnicart_discount', '50');
      UIModule.showToast('Voucher applied: ₹50 discount deducted!', 'success');
      this.renderCartPage();
    } else {
      UIModule.showToast('Invalid promo code. Try "FESTIVE-LIGHT"', 'error');
    }
  },

  // -------------------------------------------------------------
  // CHECKOUT.HTML METHODS
  // -------------------------------------------------------------
  renderCheckoutPage() {
    const customerBox = document.getElementById('checkout-customer-box');
    const addressesList = document.getElementById('checkout-addresses-list');
    const miniItemsContainer = document.getElementById('checkout-mini-items');
    const subtotalElem = document.getElementById('summary-subtotal');
    const discountElem = document.getElementById('summary-discount');
    const totalElem = document.getElementById('summary-total');

    if (!DataStore.currentUser || DataStore.currentUserRole !== 'buyer') {
      window.location.href = 'login.html?redirect=checkout.html';
      return;
    }

    const user = DataStore.currentUser;

    // Step 1: Customer Contact
    if (customerBox) {
      const safeName = UIModule.escapeHtml(`${user.FirstName || 'Customer'} ${user.LastName || ''}`.trim());
      const safeEmail = UIModule.escapeHtml(user.email || '');
      const safePhone = UIModule.escapeHtml(user.phone || '+91 98765 00000');

      customerBox.innerHTML = `
        <div class="p-3 bg-slate-50 rounded-xl border border-slate-100">
          <span class="text-[11px] text-slate-400 font-semibold block">Full Name</span>
          <strong class="text-slate-800 text-xs">${safeName}</strong>
        </div>
        <div class="p-3 bg-slate-50 rounded-xl border border-slate-100">
          <span class="text-[11px] text-slate-400 font-semibold block">Email Address</span>
          <strong class="text-slate-800 text-xs truncate block">${safeEmail}</strong>
        </div>
        <div class="p-3 bg-slate-50 rounded-xl border border-slate-100">
          <span class="text-[11px] text-slate-400 font-semibold block">Mobile Contact</span>
          <strong class="text-slate-800 text-xs">${safePhone}</strong>
        </div>
      `;
    }

    // Step 2: Addresses
    const addresses = DataStore.addresses;

    if (!this.selectedAddressId && addresses.length > 0) {
      this.selectedAddressId = addresses[0].id;
    }

    if (addresses.length === 0 && addressesList) {
      addressesList.innerHTML = `
        <div class="col-span-full p-6 text-center text-slate-400 bg-white rounded-xl border border-dashed border-slate-200">
          <p class="text-xs">No delivery address found in your account.</p>
          <a href="customer-profile.html" class="inline-block mt-2 text-xs text-blue-600 hover:underline font-semibold">+ Add Delivery Address in Profile</a>
        </div>
      `;
    }

    if (addressesList) {
      addressesList.innerHTML = addresses.map(addr => {
        const isSelected = this.selectedAddressId === addr.id;
        const activeClass = isSelected ? 'border-blue-600 bg-blue-50/40 ring-2 ring-blue-500/20' : 'border-slate-200 bg-white hover:border-slate-300';
        const safeType = UIModule.escapeHtml(addr.type || 'Home');
        const safeStreet = UIModule.escapeHtml(addr.street || '');
        const safeCity = UIModule.escapeHtml(addr.city || 'Bengaluru');
        const safeState = UIModule.escapeHtml(addr.state || 'Karnataka');
        const safePin = UIModule.escapeHtml(addr.pincode || '560001');

        return `
          <label class="p-4 rounded-xl border ${activeClass} flex items-start gap-3 cursor-pointer transition-all">
            <input
              type="radio"
              name="shipping-address"
              ${isSelected ? 'checked' : ''}
              onchange="CheckoutModule.selectAddress(${addr.id})"
              class="mt-1 text-blue-600 w-4 h-4"
            />
            <div class="text-xs space-y-1">
              <div class="flex items-center gap-2">
                <span class="badge badge-slate font-bold text-[10px]">${safeType}</span>
                ${addr.isDefault ? '<span class="badge badge-blue text-[10px]">Default</span>' : ''}
              </div>
              <p class="font-bold text-slate-800 leading-snug">${safeStreet}</p>
              <p class="text-slate-500">${safeCity}, ${safeState} - ${safePin}</p>
            </div>
          </label>
        `;
      }).join('');
    }

    // Step 3: Mini Cart Items
    const cart = DataStore.getCart();
    if (miniItemsContainer) {
      if (cart.length === 0) {
        miniItemsContainer.innerHTML = '<p class="text-xs text-slate-400 py-3 text-center">Your cart is empty.</p>';
      } else {
        miniItemsContainer.innerHTML = cart.map(item => {
          const safeItemName = UIModule.escapeHtml(item.name || 'Product');
          const lineTotal = Math.round(item.price * item.quantity * 100) / 100;
          return `
          <div class="flex items-center justify-between gap-3 text-xs py-1.5">
            <div class="flex items-center gap-2 min-w-0 flex-1">
              <span class="text-slate-400 font-bold font-mono text-[11px]">${item.quantity}×</span>
              <span class="text-slate-800 font-medium truncate">${safeItemName}</span>
            </div>
            <strong class="text-slate-900 shrink-0">${UIModule.formatCurrency(lineTotal)}</strong>
          </div>
        `;
        }).join('');
      }
    }

    const subtotal = DataStore.getCartSubtotal();
    const discount = Math.min(this.voucherDiscount, subtotal);
    const finalTotal = Math.max(0, Math.round((subtotal - discount) * 100) / 100);

    if (subtotalElem) subtotalElem.innerText = UIModule.formatCurrency(subtotal);
    if (discountElem) discountElem.innerText = discount > 0 ? `-${UIModule.formatCurrency(discount)}` : '-₹0';
    if (totalElem) totalElem.innerText = UIModule.formatCurrency(finalTotal);
  },

  selectAddress(addressId) {
    this.selectedAddressId = Number(addressId);
    this.renderCheckoutPage();
  },

  selectPaymentMethod(methodName) {
    this.selectedPaymentMethod = methodName;
    if (methodName.includes('UPI')) this.selectedPaymentMethodId = 3;
    else if (methodName.includes('Card')) this.selectedPaymentMethodId = 1;
    else this.selectedPaymentMethodId = 5; // COD
  },

  async placeOrder(e) {
    if (e) e.preventDefault();

    const cart = DataStore.getCart();
    if (cart.length === 0) {
      UIModule.showToast('Your cart is empty!', 'error');
      return;
    }

    // Pre-order stock validation: verify every item has sufficient inventory
    for (const item of cart) {
      const liveProd = (DataStore.products || []).find(p => p.id === item.id);
      if (liveProd && liveProd.stockQuantity < item.quantity) {
        UIModule.showToast(`Insufficient stock for "${liveProd.name}". Available units: ${liveProd.stockQuantity}`, 'error');
        return;
      }
    }

    const btn = document.getElementById('checkout-action-btn');
    if (btn) {
      btn.innerText = 'Processing Order...';
      btn.disabled = true;
    }

    const selectedAddr = (DataStore.addresses && DataStore.addresses.find(a => a.id === this.selectedAddressId))
      || (DataStore.addresses && DataStore.addresses[0])
      || { street: 'Flat 402, Cyber Residency, 100 Feet Rd, Indiranagar', city: 'Bengaluru', pincode: '560038' };

    const addressStr = `${selectedAddr.street || 'Bengaluru'}, ${selectedAddr.city || 'Karnataka'} ${selectedAddr.pincode || '560038'}`;
    const subtotal = DataStore.getCartSubtotal();
    const effectiveDiscount = Math.min(this.voucherDiscount, subtotal);

    try {
      const order = await DataStore.placeOrder({
        customerId: DataStore.currentUser ? DataStore.currentUser.id : 1,
        paymentMethod: this.selectedPaymentMethod,
        paymentMethodId: this.selectedPaymentMethodId,
        address: addressStr,
        isExpress: true,
        discount: effectiveDiscount
      });

      // Clear applied voucher
      localStorage.removeItem('omnicart_voucher');
      localStorage.removeItem('omnicart_discount');
      this.voucherDiscount = 0;

      UIModule.showToast(`Order #${order.orderNumber} placed successfully!`, 'success', 4000);

      setTimeout(() => {
        window.location.href = 'orders.html';
      }, 700);
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to place order. Please try again.', 'error');
      if (btn) {
        btn.innerText = 'Confirm & Place Order (₹) →';
        btn.disabled = false;
      }
    }
  }
};

window.CheckoutModule = CheckoutModule;
