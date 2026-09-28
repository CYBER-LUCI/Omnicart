/**
 * OmniCart AuthModule — Access Guards, Authentication Modal,
 * Role-Switching, and Session Management.
 */

const AuthModule = {
  currentModalRole: 'buyer', // 'buyer' | 'seller'
  currentModalMode: 'login', // 'login' | 'register'
  pendingRedirect: null,

  // Guard customer routes (Cart, Saved Products, Checkout, Orders, Profile)
  guardUserClick(targetUrl, event) {
    if (DataStore.currentUser && DataStore.currentUserRole === 'buyer') {
      return true; // Proceed with navigation
    }

    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    this.pendingRedirect = targetUrl;
    this.openAuthModal('buyer', 'login');
    return false;
  },

  // Guard merchant routes (Seller Dashboard)
  guardSellerClick(targetUrl, event) {
    if (DataStore.currentSeller && DataStore.currentUserRole === 'seller') {
      return true; // Proceed with navigation
    }

    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    this.pendingRedirect = targetUrl;
    this.openAuthModal('seller', 'login');
    return false;
  },

  toggleAuthDropdown() {
    const menu = document.getElementById('auth-dropdown-menu');
    if (menu) {
      menu.classList.toggle('hidden');
    }
  },

  closeAuthDropdown() {
    const menu = document.getElementById('auth-dropdown-menu');
    if (menu) {
      menu.classList.add('hidden');
    }
  },

  openAuthModal(role = 'buyer', mode = 'login') {
    this.currentModalRole = role;
    this.currentModalMode = mode;

    const modal = document.getElementById('auth-modal');
    if (!modal) {
      // If no inline modal on current page, redirect to login.html
      const redirectParam = this.pendingRedirect ? `&redirect=${encodeURIComponent(this.pendingRedirect)}` : '';
      window.location.href = `login.html?role=${role}${redirectParam}`;
      return;
    }

    this.setModalTab(role);
    modal.classList.remove('hidden');
  },

  closeAuthModal() {
    const modal = document.getElementById('auth-modal');
    if (modal) {
      modal.classList.add('hidden');
    }
  },

  setModalTab(role) {
    this.currentModalRole = role;
    const buyerTab = document.getElementById('modal-tab-buyer');
    const sellerTab = document.getElementById('modal-tab-seller');

    if (role === 'buyer') {
      if (buyerTab) buyerTab.className = 'py-2.5 rounded-lg font-semibold transition-all bg-white text-blue-700 shadow-xs border border-slate-200';
      if (sellerTab) sellerTab.className = 'py-2.5 rounded-lg font-medium transition-all text-slate-600 hover:text-slate-900';
    } else {
      if (sellerTab) sellerTab.className = 'py-2.5 rounded-lg font-semibold transition-all bg-white text-emerald-700 shadow-xs border border-slate-200';
      if (buyerTab) buyerTab.className = 'py-2.5 rounded-lg font-medium transition-all text-slate-600 hover:text-slate-900';
    }

    this.renderModalForm();
  },

  setModalMode(mode) {
    this.currentModalMode = mode;
    this.renderModalForm();
  },

  renderModalForm() {
    const container = document.getElementById('auth-modal-form-container');
    if (!container) return;

    if (this.currentModalRole === 'buyer') {
      if (this.currentModalMode === 'login') {
        container.innerHTML = `
          <div class="mb-4">
            <h3 class="text-lg font-bold text-slate-900">Customer Sign In</h3>
            <p class="text-xs text-slate-500">Enter your email or phone to continue</p>
          </div>
          <form onsubmit="AuthModule.handleCustomerLogin(event)" class="space-y-3.5 text-xs">
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Email or Mobile Number</label>
              <input type="text" id="modal-cust-id" required placeholder="name@domain.com or 9876543210" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Password</label>
              <input type="password" id="modal-cust-pw" required placeholder="••••••••" class="clean-input text-xs" />
            </div>
            <button type="submit" class="btn-primary w-full py-2.5 text-xs justify-center font-bold">
              Sign In to Account →
            </button>
          </form>
          <div class="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
            <span class="text-slate-500">Need an account?</span>
            <button type="button" onclick="AuthModule.setModalMode('register')" class="text-blue-600 font-bold hover:underline">Register Now</button>
          </div>
        `;
      } else {
        container.innerHTML = `
          <div class="mb-4">
            <h3 class="text-lg font-bold text-slate-900">Create Customer Account</h3>
            <p class="text-xs text-slate-500">Join OmniCart for fast 20-min delivery</p>
          </div>
          <form onsubmit="AuthModule.handleCustomerRegister(event)" class="space-y-3 text-xs">
            <div class="grid grid-cols-2 gap-2">
              <div>
                <label class="block font-semibold text-slate-700 mb-1">First Name</label>
                <input type="text" id="modal-reg-fname" required placeholder="First Name" class="clean-input text-xs" />
              </div>
              <div>
                <label class="block font-semibold text-slate-700 mb-1">Last Name</label>
                <input type="text" id="modal-reg-lname" required placeholder="Last Name" class="clean-input text-xs" />
              </div>
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Email</label>
              <input type="email" id="modal-reg-email" required placeholder="name@domain.com" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Phone</label>
              <input type="tel" id="modal-reg-phone" required placeholder="+91 98765 43210" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Password</label>
              <input type="password" id="modal-reg-pw" required placeholder="Set password" class="clean-input text-xs" />
            </div>
            <button type="submit" class="btn-primary w-full py-2.5 text-xs justify-center font-bold">
              Create Account →
            </button>
          </form>
          <div class="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
            <span class="text-slate-500">Already registered?</span>
            <button type="button" onclick="AuthModule.setModalMode('login')" class="text-blue-600 font-bold hover:underline">Sign In</button>
          </div>
        `;
      }
    } else {
      // Seller
      if (this.currentModalMode === 'login') {
        container.innerHTML = `
          <div class="mb-4">
            <h3 class="text-lg font-bold text-slate-900">Merchant Sign In</h3>
            <p class="text-xs text-slate-500">Manage store inventory and price ledgers</p>
          </div>
          <form onsubmit="AuthModule.handleSellerLogin(event)" class="space-y-3.5 text-xs">
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Merchant Email</label>
              <input type="text" id="modal-seller-id" required placeholder="seller@store.in" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Password</label>
              <input type="password" id="modal-seller-pw" required placeholder="••••••••" class="clean-input text-xs" />
            </div>
            <button type="submit" class="btn-primary bg-emerald-600 hover:bg-emerald-700 w-full py-2.5 text-xs justify-center font-bold">
              Access Seller Portal →
            </button>
          </form>
          <div class="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
            <span class="text-slate-500">New seller?</span>
            <button type="button" onclick="AuthModule.setModalMode('register')" class="text-emerald-700 font-bold hover:underline">Register Store</button>
          </div>
        `;
      } else {
        container.innerHTML = `
          <div class="mb-4">
            <h3 class="text-lg font-bold text-slate-900">Register Merchant Store</h3>
            <p class="text-xs text-slate-500">Sell products with GSTIN registration</p>
          </div>
          <form onsubmit="AuthModule.handleSellerRegister(event)" class="space-y-3 text-xs">
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Company / Store Name</label>
              <input type="text" id="modal-seller-name" required placeholder="e.g. Apex Hardware Pvt Ltd" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">GSTIN (15-digit)</label>
              <input type="text" id="modal-seller-gstin" required placeholder="29ABCDE1234F1Z5" class="clean-input text-xs uppercase" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Business Email</label>
              <input type="email" id="modal-seller-email" required placeholder="contact@store.in" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Password</label>
              <input type="password" id="modal-seller-pw2" required placeholder="Set password" class="clean-input text-xs" />
            </div>
            <button type="submit" class="btn-primary bg-emerald-600 hover:bg-emerald-700 w-full py-2.5 text-xs justify-center font-bold">
              Register Store →
            </button>
          </form>
          <div class="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
            <span class="text-slate-500">Already registered?</span>
            <button type="button" onclick="AuthModule.setModalMode('login')" class="text-emerald-700 font-bold hover:underline">Sign In</button>
          </div>
        `;
      }
    }
  },

  async handleCustomerLogin(e) {
    e.preventDefault();
    const id = document.getElementById('modal-cust-id').value.trim();
    const pw = document.getElementById('modal-cust-pw').value;

    try {
      const user = await DataStore.loginCustomer(id, pw);
      this.closeAuthModal();
      UIModule.showToast(`Signed in as ${user.FirstName}!`, 'success');
      UIModule.renderHeader();

      if (this.pendingRedirect) {
        window.location.href = this.pendingRedirect;
      } else {
        setTimeout(() => window.location.reload(), 300);
      }
    } catch (err) {
      UIModule.showToast(err.message || 'Invalid credentials. Please register first.', 'error');
    }
  },

  async handleCustomerRegister(e) {
    e.preventDefault();
    const fname = document.getElementById('modal-reg-fname').value.trim();
    const lname = document.getElementById('modal-reg-lname').value.trim();
    const email = document.getElementById('modal-reg-email').value.trim();
    const phone = document.getElementById('modal-reg-phone').value.trim();
    const pw = document.getElementById('modal-reg-pw').value;

    try {
      const user = await DataStore.registerCustomer({
        firstName: fname,
        lastName: lname,
        email: email,
        phone: phone,
        password: pw
      });

      this.closeAuthModal();
      UIModule.showToast(`Welcome to OmniCart, ${user.FirstName}!`, 'success');
      UIModule.renderHeader();

      if (this.pendingRedirect) {
        window.location.href = this.pendingRedirect;
      } else {
        setTimeout(() => window.location.reload(), 300);
      }
    } catch (err) {
      UIModule.showToast(err.message || 'Registration failed.', 'error');
    }
  },

  async handleSellerLogin(e) {
    e.preventDefault();
    const id = document.getElementById('modal-seller-id').value.trim();
    const pw = document.getElementById('modal-seller-pw').value;

    try {
      const seller = await DataStore.loginSeller(id, pw);
      this.closeAuthModal();
      UIModule.showToast(`Authenticated Merchant: ${seller.CompanyName}`, 'success');
      UIModule.renderHeader();

      if (this.pendingRedirect) {
        window.location.href = this.pendingRedirect;
      } else {
        window.location.href = 'seller-dashboard.html';
      }
    } catch (err) {
      UIModule.showToast(err.message || 'Invalid merchant credentials.', 'error');
    }
  },

  async handleSellerRegister(e) {
    e.preventDefault();
    const name = document.getElementById('modal-seller-name').value.trim();
    const gstin = document.getElementById('modal-seller-gstin').value.trim();
    const email = document.getElementById('modal-seller-email').value.trim();
    const pw = document.getElementById('modal-seller-pw2').value;

    try {
      const seller = await DataStore.registerSeller({
        companyName: name,
        gstin: gstin,
        email: email,
        phone: '+91 800 555 1010',
        city: 'Bengaluru, Karnataka',
        password: pw
      });

      this.closeAuthModal();
      UIModule.showToast(`Merchant Store Registered: ${seller.CompanyName}`, 'success');
      UIModule.renderHeader();

      window.location.href = 'seller-dashboard.html';
    } catch (err) {
      UIModule.showToast(err.message || 'Store registration failed.', 'error');
    }
  },

  logout() {
    DataStore.logout();
    UIModule.showToast('You have been logged out.', 'info');
    UIModule.renderHeader();
    setTimeout(() => {
      window.location.href = 'index.html';
    }, 400);
  }
};

window.AuthModule = AuthModule;
