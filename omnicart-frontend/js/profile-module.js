/**
 * OmniCart ProfileModule — Customer Profile & Multi-Value Contacts Controller (customer-profile.html)
 * Manages CustomerPhone, CustomerEmail, and Address records with database alignment.
 */

const ProfileModule = {
  authMode: 'login', // 'login' | 'register'

  init() {
    this.render();
  },

  setAuthMode(mode) {
    this.authMode = mode;
    this.renderAuthForm();
  },

  async render() {
    const authContainer = document.getElementById('customer-auth-container');
    const profileContainer = document.getElementById('customer-profile-container');

    if (!DataStore.currentUser || DataStore.currentUserRole !== 'buyer') {
      if (authContainer) authContainer.classList.remove('hidden');
      if (profileContainer) profileContainer.classList.add('hidden');
      this.renderAuthForm();
      return;
    }

    if (authContainer) authContainer.classList.add('hidden');
    if (profileContainer) profileContainer.classList.remove('hidden');

    const user = DataStore.currentUser;

    // Header values
    const nameElem = document.getElementById('profile-full-name');
    const idElem = document.getElementById('profile-customer-id');

    if (nameElem) nameElem.innerText = `${user.FirstName || ''} ${user.LastName || ''}`.trim() || user.email || 'Customer';
    if (idElem) idElem.innerText = `CUST-00${user.id || '101'}`;

    // Load initial cached values immediately for fast UI paint
    this.renderPhones();
    this.renderEmails();
    this.renderAddresses();

    // Fetch fresh live values directly from OmniCart MySQL database
    try {
      await Promise.all([
        DataStore.fetchCustomerPhones(),
        DataStore.fetchCustomerEmails(),
        DataStore.fetchCustomerAddresses()
      ]);
      this.renderPhones();
      this.renderEmails();
      this.renderAddresses();
    } catch (_) {}
  },

  renderAuthForm() {
    const box = document.getElementById('customer-auth-form-box');
    const loginTab = document.getElementById('cust-tab-login');
    const regTab = document.getElementById('cust-tab-register');

    if (this.authMode === 'login') {
      if (loginTab) loginTab.className = 'py-2 rounded-lg font-semibold transition-all bg-white text-blue-700 shadow-xs border border-slate-200';
      if (regTab) regTab.className = 'py-2 rounded-lg font-medium transition-all text-slate-500 hover:text-slate-800';

      if (box) {
        box.innerHTML = `
          <form onsubmit="ProfileModule.handleLogin(event)" class="space-y-4 text-xs">
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Email or Mobile Phone</label>
              <input type="text" id="prof-login-id" required placeholder="name@domain.com or 9876543210" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Password</label>
              <input type="password" id="prof-login-pw" required placeholder="••••••••" class="clean-input text-xs" />
            </div>
            <button type="submit" class="btn-primary w-full py-2.5 text-xs justify-center font-bold">
              Sign In to Account →
            </button>
          </form>
        `;
      }
    } else {
      if (regTab) regTab.className = 'py-2 rounded-lg font-semibold transition-all bg-white text-blue-700 shadow-xs border border-slate-200';
      if (loginTab) loginTab.className = 'py-2 rounded-lg font-medium transition-all text-slate-500 hover:text-slate-800';

      if (box) {
        box.innerHTML = `
          <form onsubmit="ProfileModule.handleRegister(event)" class="space-y-3 text-xs">
            <div class="grid grid-cols-2 gap-2">
              <div>
                <label class="block font-semibold text-slate-700 mb-1">First Name</label>
                <input type="text" id="prof-reg-fname" required placeholder="First Name" class="clean-input text-xs" />
              </div>
              <div>
                <label class="block font-semibold text-slate-700 mb-1">Last Name</label>
                <input type="text" id="prof-reg-lname" required placeholder="Last Name" class="clean-input text-xs" />
              </div>
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Email</label>
              <input type="email" id="prof-reg-email" required placeholder="name@domain.com" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Phone</label>
              <input type="tel" id="prof-reg-phone" required placeholder="+91 98765 43210" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Delivery Street Address</label>
              <input type="text" id="prof-reg-street" required placeholder="Street address" class="clean-input text-xs" />
            </div>
            <div>
              <label class="block font-semibold text-slate-700 mb-1">Password</label>
              <input type="password" id="prof-reg-pw" required placeholder="Set password" class="clean-input text-xs" />
            </div>
            <button type="submit" class="btn-primary w-full py-2.5 text-xs justify-center font-bold">
              Create Customer Account →
            </button>
          </form>
        `;
      }
    }
  },

  async handleLogin(e) {
    e.preventDefault();
    const id = document.getElementById('prof-login-id').value.trim();
    const pw = document.getElementById('prof-login-pw').value;

    try {
      const user = await DataStore.loginCustomer(id, pw);
      UIModule.showToast(`Welcome back, ${user.FirstName}!`, 'success');
      UIModule.renderHeader();
      this.render();
    } catch (err) {
      UIModule.showToast(err.message || 'Invalid credentials. Please register first.', 'error');
    }
  },

  async handleRegister(e) {
    e.preventDefault();
    const fname = document.getElementById('prof-reg-fname').value.trim();
    const lname = document.getElementById('prof-reg-lname').value.trim();
    const email = document.getElementById('prof-reg-email').value.trim();
    const phone = document.getElementById('prof-reg-phone').value.trim();
    const street = document.getElementById('prof-reg-street').value.trim();
    const pw = document.getElementById('prof-reg-pw').value;

    try {
      const user = await DataStore.registerCustomer({
        firstName: fname,
        lastName: lname,
        email: email,
        phone: phone,
        address: { street: street },
        password: pw
      });

      UIModule.showToast(`Account created! Welcome, ${user.FirstName}`, 'success');
      UIModule.renderHeader();
      this.render();
    } catch (err) {
      UIModule.showToast(err.message || 'Account registration failed.', 'error');
    }
  },

  renderPhones() {
    const container = document.getElementById('profile-phones-container');
    if (!container) return;

    const phones = DataStore.phones;

    if (phones.length === 0) {
      container.innerHTML = '<p class="text-xs text-slate-400">No registered phone numbers.</p>';
      return;
    }

    container.innerHTML = phones.map(p => {
      const safePhone = UIModule.escapeHtml(p.phone || '');
      const safeType = UIModule.escapeHtml(p.type || 'Mobile');
      return `
      <div class="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-100 text-xs">
        <div>
          <span class="font-bold text-slate-800">${safePhone}</span>
          <span class="text-[10px] text-slate-400 block">${safeType}</span>
        </div>
        <button
          onclick="ProfileModule.deletePhone(${p.id})"
          class="text-red-500 hover:text-red-700 text-xs px-2 py-1 rounded hover:bg-red-50"
        >
          Remove
        </button>
      </div>
    `;
    }).join('');
  },

  addPhone(e) {
    e.preventDefault();
    const phoneInput = document.getElementById('new-phone-input');
    const typeInput = document.getElementById('new-phone-type');

    if (!phoneInput || !phoneInput.value.trim()) return;
    const phoneVal = phoneInput.value.trim();

    if (phoneVal.length < 10) {
      UIModule.showToast('Please enter a valid 10-digit mobile number.', 'error');
      return;
    }

    try {
      DataStore.addCustomerPhone(phoneVal, typeInput ? typeInput.value.trim() || 'Mobile' : 'Mobile');
      phoneInput.value = '';
      this.renderPhones();
      UIModule.showToast('Phone number added successfully', 'success');
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to add phone number.', 'error');
    }
  },

  deletePhone(id) {
    try {
      DataStore.deleteCustomerPhone(id);
      this.renderPhones();
      UIModule.showToast('Phone number removed', 'info');
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to remove phone number.', 'error');
    }
  },

  renderEmails() {
    const container = document.getElementById('profile-emails-container');
    if (!container) return;

    const emails = DataStore.emails;

    if (emails.length === 0) {
      container.innerHTML = '<p class="text-xs text-slate-400">No secondary email addresses.</p>';
      return;
    }

    container.innerHTML = emails.map(e => {
      const safeEmail = UIModule.escapeHtml(e.email || '');
      const safeType = UIModule.escapeHtml(e.type || 'Personal');
      return `
      <div class="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-100 text-xs">
        <div>
          <span class="font-bold text-slate-800">${safeEmail}</span>
          <span class="text-[10px] text-slate-400 block">${safeType}</span>
        </div>
        <button
          onclick="ProfileModule.deleteEmail(${e.id})"
          class="text-red-500 hover:text-red-700 text-xs px-2 py-1 rounded hover:bg-red-50"
        >
          Remove
        </button>
      </div>
    `;
    }).join('');
  },

  addEmail(e) {
    e.preventDefault();
    const emailInput = document.getElementById('new-email-input');
    const typeInput = document.getElementById('new-email-type');

    if (!emailInput || !emailInput.value.trim()) return;
    const emailVal = emailInput.value.trim();

    if (!emailVal.includes('@') || !emailVal.includes('.')) {
      UIModule.showToast('Please enter a valid email address.', 'error');
      return;
    }

    try {
      DataStore.addCustomerEmail(emailVal, typeInput ? typeInput.value.trim() || 'Personal' : 'Personal');
      emailInput.value = '';
      this.renderEmails();
      UIModule.showToast('Email address added successfully', 'success');
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to add email address.', 'error');
    }
  },

  deleteEmail(id) {
    try {
      DataStore.deleteCustomerEmail(id);
      this.renderEmails();
      UIModule.showToast('Email address removed', 'info');
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to remove email.', 'error');
    }
  },

  renderAddresses() {
    const container = document.getElementById('profile-addresses-container');
    if (!container) return;

    const addresses = DataStore.addresses;

    if (addresses.length === 0) {
      container.innerHTML = '<p class="text-xs text-slate-400">No delivery addresses saved yet.</p>';
      return;
    }

    container.innerHTML = addresses.map(addr => {
      const safeType = UIModule.escapeHtml(addr.type || 'Home');
      const safeStreet = UIModule.escapeHtml(addr.street || '');
      const safeCity = UIModule.escapeHtml(addr.city || 'Bengaluru');
      const safeState = UIModule.escapeHtml(addr.state || 'Karnataka');
      const safePin = UIModule.escapeHtml(addr.pincode || '560001');

      return `
      <div class="p-4 rounded-xl border border-slate-200 bg-white space-y-2 text-xs">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <span class="badge badge-slate font-bold text-[10px]">${safeType}</span>
            ${addr.isDefault ? '<span class="badge badge-blue text-[10px]">Default</span>' : ''}
          </div>
          <button
            onclick="ProfileModule.deleteAddress(${addr.id})"
            class="text-red-500 hover:text-red-700 font-semibold"
          >
            Delete
          </button>
        </div>
        <p class="font-bold text-slate-800 text-sm">${safeStreet}</p>
        <p class="text-slate-500">${safeCity}, ${safeState} - ${safePin}</p>
      </div>
    `;
    }).join('');
  },

  addAddress(e) {
    e.preventDefault();
    const street = document.getElementById('addr-street').value.trim();
    const city = document.getElementById('addr-city').value.trim();
    const state = document.getElementById('addr-state').value.trim();
    const pincode = document.getElementById('addr-pincode').value.trim();
    const type = document.getElementById('addr-type').value.trim();

    if (!street || !city) {
      UIModule.showToast('Please fill in street and city.', 'error');
      return;
    }

    // Enforce 6-digit Indian PIN code matching database constraint chk_pincode CHECK (PINCode REGEXP '^[0-9]{6}$')
    if (!/^\d{6}$/.test(pincode)) {
      UIModule.showToast('Invalid PIN code. Must be exactly 6 digits.', 'error');
      return;
    }

    try {
      DataStore.addCustomerAddress({
        street: street,
        city: city,
        state: state || 'Karnataka',
        pincode: pincode,
        type: type || 'Home'
      });

      e.target.reset();
      this.renderAddresses();
      UIModule.showToast('Delivery address saved successfully', 'success');
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to save address.', 'error');
    }
  },

  deleteAddress(id) {
    try {
      DataStore.deleteCustomerAddress(id);
      this.renderAddresses();
      UIModule.showToast('Delivery address deleted', 'info');
    } catch (err) {
      UIModule.showToast(err.message || 'Failed to delete address.', 'error');
    }
  }
};

window.ProfileModule = ProfileModule;
