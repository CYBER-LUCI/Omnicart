/**
 * OmniCart DataStore — Central State Management & Hybrid API Client
 * Seamlessly synchronizes with Spring Boot REST Backend (http://localhost:8080/api)
 * with graceful local fallback and persistent caching in localStorage.
 */

const DataStore = {
  API_BASE: 'http://localhost:8080/api',
  token: localStorage.getItem('omnicart_token') || null,
  currentUser: JSON.parse(localStorage.getItem('omnicart_user') || 'null'),
  currentSeller: JSON.parse(localStorage.getItem('omnicart_seller') || 'null'),
  currentUserRole: localStorage.getItem('omnicart_role') || null, // 'buyer' | 'seller' | null

  // In-memory / Cached Collections
  categories: [],
  products: [],
  cart: JSON.parse(localStorage.getItem('omnicart_cart') || '[]'),
  savedProducts: JSON.parse(localStorage.getItem('omnicart_saved') || '[]'),
  orders: JSON.parse(localStorage.getItem('omnicart_orders') || '[]'),
  addresses: JSON.parse(localStorage.getItem('omnicart_addresses') || '[]'),
  phones: JSON.parse(localStorage.getItem('omnicart_phones') || '[]'),
  emails: JSON.parse(localStorage.getItem('omnicart_emails') || '[]'),

  // Generic Fetch with Authorization Header
  async apiRequest(endpoint, options = {}) {
    const headers = {
      'Content-Type': 'application/json',
      ...(this.token ? { 'Authorization': `Bearer ${this.token}` } : {}),
      ...(options.headers || {})
    };

    if (options.body instanceof FormData) {
      delete headers['Content-Type']; // Let browser set boundary
    }

    try {
      const response = await fetch(`${this.API_BASE}${endpoint}`, {
        ...options,
        headers
      });
      const data = await response.json();
      return data;
    } catch (err) {
      console.warn(`[DataStore] Backend API call to ${endpoint} failed or is offline. Operating in local-sync mode.`, err);
      return null;
    }
  },

  // Initialize seed database & local state
  init() {
    this.seedInitialData();
    this.syncBackendCatalog();
  },

  seedInitialData() {
    // If previously seeded with dummy data, clear it out
    if (localStorage.getItem('omnicart_seeded_v1') || !localStorage.getItem('omnicart_clean_v2')) {
      localStorage.removeItem('omnicart_seeded_v1');
      localStorage.removeItem('omnicart_products');
      localStorage.removeItem('omnicart_orders');
      localStorage.removeItem('omnicart_addresses');
      localStorage.removeItem('omnicart_phones');
      localStorage.removeItem('omnicart_emails');
      localStorage.removeItem('omnicart_cart');
      localStorage.removeItem('omnicart_saved');
      localStorage.removeItem('omnicart_user');
      localStorage.removeItem('omnicart_seller');
      localStorage.removeItem('omnicart_token');
      localStorage.removeItem('omnicart_role');

      // Base category taxonomy aligned with OmniCart database
      const baseCategories = [
        { id: 1, name: 'Electronics', code: 'ELEC', description: 'Electronic devices and gadgets' },
        { id: 2, name: 'Apparel', code: 'APP', description: 'Clothing and fashion accessories' },
        { id: 3, name: 'Home & Kitchen', code: 'HOME', description: 'Household and kitchen items' },
        { id: 4, name: 'Sports', code: 'SPORT', description: 'Sports equipment and gear' },
        { id: 5, name: 'Mobile Phones', code: 'MOBI', description: 'Smartphones and accessories' },
        { id: 6, name: 'Laptops', code: 'LAPT', description: 'Laptops and notebooks' },
        { id: 7, name: 'Mens Clothing', code: 'MCLO', description: 'Apparel for men' },
        { id: 8, name: 'Womens Clothing', code: 'WCLO', description: 'Apparel for women' },
        { id: 9, name: 'Kitchen Appliances', code: 'KITC', description: 'Electrical appliances for kitchen' },
        { id: 10, name: 'Running Shoes', code: 'SHOE', description: 'Shoes for running and athletics' }
      ];

      localStorage.setItem('omnicart_categories', JSON.stringify(baseCategories));
      localStorage.setItem('omnicart_products', JSON.stringify([]));
      localStorage.setItem('omnicart_addresses', JSON.stringify([]));
      localStorage.setItem('omnicart_phones', JSON.stringify([]));
      localStorage.setItem('omnicart_emails', JSON.stringify([]));
      localStorage.setItem('omnicart_orders', JSON.stringify([]));
      localStorage.setItem('omnicart_clean_v2', 'true');
    }

    this.categories = JSON.parse(localStorage.getItem('omnicart_categories') || '[]');
    this.products = JSON.parse(localStorage.getItem('omnicart_products') || '[]');
    this.addresses = JSON.parse(localStorage.getItem('omnicart_addresses') || '[]');
    if (this.addresses.length === 0) {
      this.addresses = [
        {
          id: 1,
          type: 'Home',
          street: 'Flat 402, Cyber Residency, 100 Feet Rd, Indiranagar',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560038',
          isDefault: true
        }
      ];
      localStorage.setItem('omnicart_addresses', JSON.stringify(this.addresses));
    }
    this.phones = JSON.parse(localStorage.getItem('omnicart_phones') || '[]');
    this.emails = JSON.parse(localStorage.getItem('omnicart_emails') || '[]');
    this.orders = JSON.parse(localStorage.getItem('omnicart_orders') || '[]');
  },

  async syncBackendCatalog() {
    try {
      const catRes = await this.apiRequest('/categories');
      if (catRes && catRes.success && Array.isArray(catRes.data) && catRes.data.length > 0) {
        this.categories = catRes.data;
        localStorage.setItem('omnicart_categories', JSON.stringify(this.categories));
      }

      const prodRes = await this.apiRequest('/products?page=0&size=50');
      if (prodRes && prodRes.success && prodRes.data && Array.isArray(prodRes.data.content)) {
        if (prodRes.data.content.length === 0) {
          this.products = [];
          localStorage.setItem('omnicart_products', JSON.stringify([]));
        } else {
          // Map backend product structure to frontend schema
          const mappedProducts = prodRes.data.content.map(p => ({
            id: p.id,
            code: `PROD-00${p.id}`,
            name: p.name,
            description: p.description,
            categoryId: p.categoryId,
            categoryName: p.categoryName || 'General',
            sellerId: p.sellerId || 1,
            sellerName: p.sellerName || 'Verified Merchant',
            currentPrice: Number(p.currentPrice) || 999,
            originalPrice: Math.round((Number(p.currentPrice) || 999) * 1.5),
            stockQuantity: p.stockQuantity ?? 15,
            stockStatus: p.stockStatus || (p.stockQuantity > 10 ? 'AVAILABLE' : (p.stockQuantity > 0 ? 'LOW_STOCK' : 'OUT_OF_STOCK')),
            isDealOfTheDay: p.id === 1,
            rating: 4.8,
            reviewsCount: 50 + p.id * 12,
            fastDeliveryAvailable: true,
            images: (p.images && p.images.length > 0) ? p.images : [
              { id: 100 + p.id, url: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80', isPrimary: true }
            ]
          }));
          this.products = mappedProducts;
          localStorage.setItem('omnicart_products', JSON.stringify(this.products));
        }
      }
    } catch (e) {
      console.warn('[DataStore] Backend sync notice:', e.message);
    }
  },

  // Auth Operations
  async loginCustomer(emailOrPhone, password) {
    const email = (emailOrPhone || '').trim();
    const cleanPw = (password || '').trim();

    if (!email || !cleanPw) {
      throw new Error('Email and password are required.');
    }

    // 1. Try backend authentication
    const apiRes = await this.apiRequest('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: email, password: cleanPw })
    });

    if (apiRes) {
      if (!apiRes.success || !apiRes.data) {
        throw new Error(apiRes.message || `No account found for '${email}'. Please check your credentials or register.`);
      }

      this.token = apiRes.data.token;
      localStorage.setItem('omnicart_token', this.token);

      const customerObj = {
        id: apiRes.data.userId || 1,
        FirstName: apiRes.data.role === 'ADMIN' ? 'Admin' : (email.includes('@') ? email.split('@')[0] : 'Customer'),
        LastName: '',
        email: email,
        phone: '+91 98765 43210'
      };

      this.currentUser = customerObj;
      this.currentUserRole = 'buyer';
      this.currentSeller = null;

      localStorage.setItem('omnicart_user', JSON.stringify(customerObj));
      localStorage.setItem('omnicart_role', 'buyer');
      localStorage.removeItem('omnicart_seller');

      return customerObj;
    }

    // 2. Offline / Local fallback: check registered accounts with password verification
    const registeredUsers = JSON.parse(localStorage.getItem('omnicart_registered_users') || '[]');
    const matchedUser = registeredUsers.find(u => u.email.toLowerCase() === email.toLowerCase() || (u.phone && u.phone.includes(email)));

    if (!matchedUser) {
      throw new Error(`Account not found for '${email}'. Please create an account by clicking Register.`);
    }

    if (matchedUser.password && matchedUser.password !== cleanPw) {
      throw new Error('Incorrect password. Please enter the valid account password.');
    }

    const customerObj = {
      id: matchedUser.id,
      FirstName: matchedUser.FirstName,
      LastName: matchedUser.LastName,
      email: matchedUser.email,
      phone: matchedUser.phone
    };

    this.currentUser = customerObj;
    this.currentUserRole = 'buyer';
    this.currentSeller = null;

    localStorage.setItem('omnicart_user', JSON.stringify(customerObj));
    localStorage.setItem('omnicart_role', 'buyer');
    localStorage.removeItem('omnicart_seller');

    return customerObj;
  },

  async registerCustomer(data) {
    if (!data.email || !data.firstName || !data.password) {
      throw new Error('First name, email, and password are required.');
    }
    if (data.password.length < 6) {
      throw new Error('Password must be at least 6 characters long.');
    }

    const apiRes = await this.apiRequest('/auth/register', {
      method: 'POST',
      body: JSON.stringify({
        firstName: data.firstName.trim(),
        lastName: (data.lastName || '').trim(),
        email: data.email.trim(),
        phone: (data.phone || '').trim(),
        password: data.password,
        role: 'CUSTOMER'
      })
    });

    const customerObj = {
      id: (apiRes && apiRes.data && apiRes.data.userId) ? apiRes.data.userId : Date.now(),
      FirstName: data.firstName.trim(),
      LastName: (data.lastName || '').trim(),
      email: data.email.trim(),
      phone: (data.phone || '').trim(),
      password: data.password // Stored for offline credential verification
    };

    // Save to registered local list
    const registeredUsers = JSON.parse(localStorage.getItem('omnicart_registered_users') || '[]');
    const existingIdx = registeredUsers.findIndex(u => u.email.toLowerCase() === customerObj.email.toLowerCase());
    if (existingIdx > -1) {
      registeredUsers[existingIdx] = customerObj;
    } else {
      registeredUsers.push(customerObj);
    }
    localStorage.setItem('omnicart_registered_users', JSON.stringify(registeredUsers));

    if (data.address && data.address.street) {
      const newAddr = {
        id: Date.now(),
        customerId: customerObj.id,
        street: data.address.street.trim(),
        city: data.address.city ? data.address.city.trim() : 'Bengaluru',
        state: data.address.state ? data.address.state.trim() : 'Karnataka',
        pincode: data.address.pincode ? data.address.pincode.trim() : '560001',
        type: 'Home',
        isDefault: true
      };
      this.addresses.push(newAddr);
      localStorage.setItem('omnicart_addresses', JSON.stringify(this.addresses));
    }

    if (apiRes && apiRes.data && apiRes.data.token) {
      this.token = apiRes.data.token;
      localStorage.setItem('omnicart_token', this.token);
    }

    const sessionObj = {
      id: customerObj.id,
      FirstName: customerObj.FirstName,
      LastName: customerObj.LastName,
      email: customerObj.email,
      phone: customerObj.phone
    };

    this.currentUser = sessionObj;
    this.currentUserRole = 'buyer';
    this.currentSeller = null;

    localStorage.setItem('omnicart_user', JSON.stringify(sessionObj));
    localStorage.setItem('omnicart_role', 'buyer');
    localStorage.removeItem('omnicart_seller');

    return sessionObj;
  },

  async loginSeller(emailOrId, password) {
    const email = (emailOrId || '').trim();
    const cleanPw = (password || '').trim();

    if (!email || !cleanPw) {
      throw new Error('Merchant email and password are required.');
    }

    // 1. Try backend authentication
    const apiRes = await this.apiRequest('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: email, password: cleanPw })
    });

    if (apiRes) {
      if (!apiRes.success || !apiRes.data) {
        throw new Error(apiRes.message || `No registered merchant found for '${email}'. Please register your store.`);
      }

      this.token = apiRes.data.token;
      localStorage.setItem('omnicart_token', this.token);

      const sellerObj = {
        id: apiRes.data.userId || 1,
        CompanyName: email.includes('@') ? (email.split('@')[0].toUpperCase() + ' Retail') : 'Merchant Store',
        gstin: '29ABCDE1234F1Z5',
        email: email,
        phone: '+91 800 555 1010',
        city: 'Bengaluru, Karnataka'
      };

      this.currentSeller = sellerObj;
      this.currentUserRole = 'seller';
      this.currentUser = null;

      localStorage.setItem('omnicart_seller', JSON.stringify(sellerObj));
      localStorage.setItem('omnicart_role', 'seller');
      localStorage.removeItem('omnicart_user');

      return sellerObj;
    }

    // 2. Offline / Local fallback: check registered sellers with password verification
    const registeredSellers = JSON.parse(localStorage.getItem('omnicart_registered_sellers') || '[]');
    const matchedSeller = registeredSellers.find(s => s.email.toLowerCase() === email.toLowerCase());

    if (!matchedSeller) {
      throw new Error(`Merchant account '${email}' not found. Please register your store first.`);
    }

    if (matchedSeller.password && matchedSeller.password !== cleanPw) {
      throw new Error('Incorrect merchant password. Please verify your credentials.');
    }

    const sellerObj = {
      id: matchedSeller.id,
      CompanyName: matchedSeller.CompanyName,
      gstin: matchedSeller.gstin,
      email: matchedSeller.email,
      phone: matchedSeller.phone,
      city: matchedSeller.city
    };

    this.currentSeller = sellerObj;
    this.currentUserRole = 'seller';
    this.currentUser = null;

    localStorage.setItem('omnicart_seller', JSON.stringify(sellerObj));
    localStorage.setItem('omnicart_role', 'seller');
    localStorage.removeItem('omnicart_user');

    return sellerObj;
  },

  async registerSeller(data) {
    if (!data.companyName || !data.email || !data.gstin || !data.password) {
      throw new Error('Company name, GSTIN, business email, and password are required.');
    }
    const cleanGstin = data.gstin.trim().toUpperCase();
    const gstinRegex = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/;
    if (!gstinRegex.test(cleanGstin)) {
      throw new Error('Invalid GSTIN format. Expected 15-character standard format (e.g. 29ABCDE1234F1Z5).');
    }
    if (data.password.length < 6) {
      throw new Error('Password must be at least 6 characters long.');
    }

    const apiRes = await this.apiRequest('/sellers', {
      method: 'POST',
      body: JSON.stringify({
        companyName: data.companyName.trim(),
        gstin: data.gstin.trim(),
        contactEmail: (data.email || data.contactEmail).trim(),
        contactPhone: (data.phone || data.contactPhone || '+91 800 555 1010').trim(),
        city: (data.city || 'Bengaluru, Karnataka').trim()
      })
    });

    const sellerObj = {
      id: (apiRes && apiRes.data && apiRes.data.id) ? apiRes.data.id : Date.now(),
      CompanyName: data.companyName.trim(),
      gstin: data.gstin.trim().toUpperCase(),
      email: data.email.trim(),
      phone: (data.phone || '+91 800 555 1010').trim(),
      city: (data.city || 'Bengaluru, Karnataka').trim(),
      password: data.password // Stored for offline credential verification
    };

    const registeredSellers = JSON.parse(localStorage.getItem('omnicart_registered_sellers') || '[]');
    const existingIdx = registeredSellers.findIndex(s => s.email.toLowerCase() === sellerObj.email.toLowerCase());
    if (existingIdx > -1) {
      registeredSellers[existingIdx] = sellerObj;
    } else {
      registeredSellers.push(sellerObj);
    }
    localStorage.setItem('omnicart_registered_sellers', JSON.stringify(registeredSellers));

    const sessionObj = {
      id: sellerObj.id,
      CompanyName: sellerObj.CompanyName,
      gstin: sellerObj.gstin,
      email: sellerObj.email,
      phone: sellerObj.phone,
      city: sellerObj.city
    };

    this.currentSeller = sessionObj;
    this.currentUserRole = 'seller';
    this.currentUser = null;

    localStorage.setItem('omnicart_seller', JSON.stringify(sessionObj));
    localStorage.setItem('omnicart_role', 'seller');
    localStorage.removeItem('omnicart_user');

    return sessionObj;
  },

  logout() {
    this.token = null;
    this.currentUser = null;
    this.currentSeller = null;
    this.currentUserRole = null;

    localStorage.removeItem('omnicart_token');
    localStorage.removeItem('omnicart_user');
    localStorage.removeItem('omnicart_seller');
    localStorage.removeItem('omnicart_role');
  },

  // Cart Operations
  getCart() {
    return this.cart;
  },

  getCartCount() {
    return this.cart.reduce((total, item) => total + (item.quantity || 1), 0);
  },

  getCartSubtotal() {
    const raw = this.cart.reduce((total, item) => total + (Number(item.price) * Number(item.quantity)), 0);
    return Math.round(raw * 100) / 100;
  },

  addToCart(product, quantity = 1) {
    if (!product || !product.id) {
      throw new Error('Invalid product.');
    }

    // STRICT CUSTOMER AUTHENTICATION GATE
    // Add to cart should work ONLY when customer is logged in
    if (!this.currentUser || this.currentUserRole !== 'buyer') {
      const currentFile = window.location.pathname.split('/').pop() || 'index.html';
      const redirectUrl = encodeURIComponent(currentFile + window.location.search);
      if (window.UIModule && typeof window.UIModule.showToast === 'function') {
        window.UIModule.showToast('Please sign in to add items to your cart. Redirecting...', 'warning', 3000);
      }
      setTimeout(() => {
        window.location.href = `login.html?role=buyer&redirect=${redirectUrl}&auth_required=true&reason=cart`;
      }, 400);
      throw new Error('Please sign in to your buyer account to add items to your cart.');
    }

    const prodId = Number(product.id);
    const qtyToAdd = Math.max(1, Math.floor(Number(quantity) || 1));

    // Find live product in catalog to verify real stock
    const catalogProd = this.products.find(p => Number(p.id) === prodId) || product;
    const availableStock = typeof catalogProd.stockQuantity === 'number' ? catalogProd.stockQuantity : 10;

    if (availableStock <= 0) {
      throw new Error(`"${catalogProd.name}" is currently out of stock.`);
    }

    const existingIndex = this.cart.findIndex(item => Number(item.id) === prodId);
    const price = Number(catalogProd.currentPrice || product.currentPrice || product.price || 0);
    const primaryImg = (catalogProd.images && catalogProd.images.length > 0)
      ? (catalogProd.images.find(img => img.isPrimary) || catalogProd.images[0]).url
      : (product.image || 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80');

    if (existingIndex > -1) {
      const targetQty = this.cart[existingIndex].quantity + qtyToAdd;
      if (targetQty > availableStock) {
        this.cart[existingIndex].quantity = availableStock;
        this.saveCart();
        throw new Error(`Only ${availableStock} units available in warehouse. Cart quantity adjusted to maximum available stock.`);
      }
      this.cart[existingIndex].quantity = targetQty;
    } else {
      const finalQty = Math.min(qtyToAdd, availableStock);
      this.cart.push({
        id: prodId,
        name: catalogProd.name,
        code: catalogProd.code || `PROD-${prodId}`,
        price: price,
        originalPrice: catalogProd.originalPrice || Math.round(price * 1.5),
        image: primaryImg,
        categoryName: catalogProd.categoryName || 'Product',
        quantity: finalQty
      });
    }

    this.saveCart();
    return this.cart;
  },

  updateCartQty(productId, quantity) {
    const prodId = Number(productId);
    const index = this.cart.findIndex(item => Number(item.id) === prodId);

    if (index > -1) {
      const requestedQty = Math.floor(Number(quantity));
      if (requestedQty <= 0) {
        this.cart.splice(index, 1);
      } else {
        const catalogProd = this.products.find(p => Number(p.id) === prodId);
        const maxStock = catalogProd ? (catalogProd.stockQuantity ?? 50) : 50;
        this.cart[index].quantity = Math.min(requestedQty, maxStock);
      }
      this.saveCart();
    }
    return this.cart;
  },

  removeFromCart(productId) {
    const prodId = Number(productId);
    this.cart = this.cart.filter(item => Number(item.id) !== prodId);
    this.saveCart();
    return this.cart;
  },

  clearCart() {
    this.cart = [];
    this.saveCart();
  },

  saveCart() {
    localStorage.setItem('omnicart_cart', JSON.stringify(this.cart));
    if (window.UIModule) {
      window.UIModule.renderHeader();
    }
  },

  // Saved Products / Wishlist
  getSavedProducts() {
    return this.savedProducts;
  },

  isSaved(productId) {
    const prodId = Number(productId);
    return this.savedProducts.some(id => Number(id) === prodId);
  },

  toggleSavedProduct(productId) {
    const prodId = Number(productId);
    const index = this.savedProducts.findIndex(id => Number(id) === prodId);
    let added = false;

    if (index > -1) {
      this.savedProducts.splice(index, 1);
      added = false;
    } else {
      this.savedProducts.push(prodId);
      added = true;
    }

    localStorage.setItem('omnicart_saved', JSON.stringify(this.savedProducts));
    if (window.UIModule) {
      window.UIModule.renderHeader();
    }
    return added;
  },

  // Orders Management
  async placeOrder({ customerId, paymentMethod, paymentMethodId = 3, address, isExpress = true, discount = 0 }) {
    if (!this.cart || this.cart.length === 0) {
      throw new Error('Your shopping cart is empty.');
    }

    if (!this.currentUser || this.currentUserRole !== 'buyer') {
      throw new Error('Please sign in to your customer account to place an order.');
    }

    // Pre-flight stock verification to ensure data integrity
    for (const item of this.cart) {
      const prod = this.products.find(p => Number(p.id) === Number(item.id));
      if (prod && typeof prod.stockQuantity === 'number') {
        if (prod.stockQuantity < item.quantity) {
          throw new Error(`Insufficient stock for "${item.name}". Only ${prod.stockQuantity} available.`);
        }
      }
    }

    const subtotal = this.getCartSubtotal();
    const finalTotal = Math.max(0, Math.round((subtotal - discount) * 100) / 100);

    const buyerId = this.currentUser.id;

    const orderPayload = {
      customerId: buyerId,
      paymentMethodId: paymentMethodId,
      items: this.cart.map(item => ({
        productId: item.id,
        quantity: item.quantity
      }))
    };

    // Try backend ACID checkout
    const apiRes = await this.apiRequest('/orders', {
      method: 'POST',
      body: JSON.stringify(orderPayload)
    });

    const newOrder = {
      id: (apiRes && apiRes.data && apiRes.data.id) ? apiRes.data.id : (1000 + this.orders.length + 1),
      orderNumber: `ORD-2026-${Math.floor(1000 + Math.random() * 9000)}`,
      customerId: buyerId,
      customerName: `${this.currentUser.FirstName} ${this.currentUser.LastName || ''}`.trim(),
      orderDate: new Date().toISOString().replace('T', ' ').substring(0, 19),
      shippingStatus: 'ORDER_PLACED',
      paymentMethod: paymentMethod || 'UPI Instant Transfer',
      paymentStatus: 'PAID',
      deliveryAddress: address || (this.addresses[0] ? `${this.addresses[0].street}, ${this.addresses[0].city} ${this.addresses[0].pincode}` : 'Bengaluru, Karnataka'),
      isExpress20Min: isExpress,
      items: [...this.cart],
      subtotal: subtotal,
      discount: discount,
      deliveryFee: 0,
      totalAmount: finalTotal
    };

    this.orders.unshift(newOrder);
    localStorage.setItem('omnicart_orders', JSON.stringify(this.orders));

    // Deduct local stock
    this.cart.forEach(item => {
      const prod = this.products.find(p => Number(p.id) === Number(item.id));
      if (prod && typeof prod.stockQuantity === 'number') {
        prod.stockQuantity = Math.max(0, prod.stockQuantity - item.quantity);
        if (prod.stockQuantity === 0) prod.stockStatus = 'OUT_OF_STOCK';
        else if (prod.stockQuantity <= 10) prod.stockStatus = 'LOW_STOCK';
      }
    });
    localStorage.setItem('omnicart_products', JSON.stringify(this.products));

    this.clearCart();
    return newOrder;
  },

  async cancelOrder(orderId) {
    const id = Number(orderId);
    await this.apiRequest(`/orders/${id}/cancel`, { method: 'POST' });

    const order = this.orders.find(o => Number(o.id) === id);
    if (order) {
      order.shippingStatus = 'CANCELLED';
      localStorage.setItem('omnicart_orders', JSON.stringify(this.orders));

      // DATA INTEGRITY RESTORATION: Restore stock inventory for all cancelled items
      if (order.items && Array.isArray(order.items)) {
        order.items.forEach(item => {
          const prod = this.products.find(p => Number(p.id) === Number(item.id));
          if (prod && typeof prod.stockQuantity === 'number') {
            prod.stockQuantity += Number(item.quantity) || 1;
            prod.stockStatus = prod.stockQuantity > 10 ? 'AVAILABLE' : (prod.stockQuantity > 0 ? 'LOW_STOCK' : 'OUT_OF_STOCK');
          }
        });
        localStorage.setItem('omnicart_products', JSON.stringify(this.products));
      }
    }
    return order;
  },

  updateOrderStatus(orderId, newStatus) {
    const id = Number(orderId);
    const order = this.orders.find(o => Number(o.id) === id);
    if (order) {
      order.shippingStatus = newStatus;
      localStorage.setItem('omnicart_orders', JSON.stringify(this.orders));
    }
    return order;
  },

  // Inventory & Price Ledger Management
  async updateStock(productId, newQuantity) {
    const id = Number(productId);
    const qty = parseInt(newQuantity, 10);

    if (isNaN(qty) || qty < 0) {
      throw new Error('Stock quantity must be a non-negative integer.');
    }

    await this.apiRequest(`/products/${id}/stock`, {
      method: 'PUT',
      body: JSON.stringify({ quantity: qty })
    });

    const prod = this.products.find(p => Number(p.id) === id);
    if (prod) {
      prod.stockQuantity = qty;
      prod.stockStatus = qty > 10 ? 'AVAILABLE' : (qty > 0 ? 'LOW_STOCK' : 'OUT_OF_STOCK');
      localStorage.setItem('omnicart_products', JSON.stringify(this.products));
    }
    return prod;
  },

  async updatePrice(productId, newPrice, reason = 'Price adjustment') {
    const id = Number(productId);
    const price = Math.round(parseFloat(newPrice) * 100) / 100;

    if (isNaN(price) || price <= 0) {
      throw new Error('Price must be greater than zero.');
    }

    const cleanReason = (reason || 'Price adjustment').trim();

    await this.apiRequest(`/products/${id}/prices`, {
      method: 'POST',
      body: JSON.stringify({ price: price, changeReason: cleanReason })
    });

    const prod = this.products.find(p => Number(p.id) === id);
    if (prod) {
      prod.originalPrice = prod.currentPrice;
      prod.currentPrice = price;
      if (!prod.priceLedger) prod.priceLedger = [];
      prod.priceLedger.unshift({
        id: Date.now(),
        price: price,
        changedAt: new Date().toISOString().replace('T', ' ').substring(0, 19),
        changeReason: cleanReason
      });
      localStorage.setItem('omnicart_products', JSON.stringify(this.products));
    }
    return prod;
  },

  async addProduct(productData) {
    if (!this.currentSeller || this.currentUserRole !== 'seller') {
      throw new Error('Unauthorized: You must be signed in as a merchant to publish products.');
    }

    const name = (productData.name || '').trim();
    if (!name) {
      throw new Error('Product name is required.');
    }

    const initialPrice = Math.round(parseFloat(productData.initialPrice || productData.currentPrice || 0) * 100) / 100;
    if (isNaN(initialPrice) || initialPrice <= 0) {
      throw new Error('Product price must be greater than zero.');
    }

    const stockQuantity = parseInt(productData.stockQuantity, 10);
    if (isNaN(stockQuantity) || stockQuantity < 0) {
      throw new Error('Stock quantity must be a non-negative integer.');
    }

    const sellerId = Number(this.currentSeller.id);
    const categoryId = Number(productData.categoryId) || 1;

    const apiRes = await this.apiRequest('/products', {
      method: 'POST',
      body: JSON.stringify({
        name: productData.name,
        description: productData.description || 'Verified product',
        stockQuantity: stockQuantity,
        sellerId: sellerId,
        categoryId: categoryId,
        initialPrice: initialPrice
      })
    });

    const prodId = (apiRes && apiRes.data && apiRes.data.id) ? apiRes.data.id : (this.products.length + 1);

    // Persist image if provided
    if (productData.imageUrl && apiRes && apiRes.data) {
      try {
        await this.apiRequest(`/products/${prodId}/images`, {
          method: 'POST',
          body: JSON.stringify({
            imageUrl: productData.imageUrl,
            displayOrder: 1,
            isPrimary: true
          })
        });
      } catch (err) {
        console.warn('[DataStore] Image save notice:', err.message);
      }
    }

    // Automatically index newly published product into Visual Search AI engine (port 5000)
    if (productData.imageUrl) {
      try {
        await fetch('http://127.0.0.1:5000/api/embeddings/index', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            product_id: String(prodId),
            name: productData.name,
            category: productData.categoryName || 'General',
            price: initialPrice,
            image: productData.imageUrl,
            desc: productData.description || ''
          })
        }).catch(err => console.warn('[DataStore] Visual Search auto-index notice:', err));
      } catch (_) {}
    }

    const newProd = {
      id: prodId,
      code: `PROD-00${prodId}`,
      name: productData.name,
      description: productData.description || 'Verified authentic product',
      categoryId: categoryId,
      categoryName: productData.categoryName || 'General',
      sellerId: sellerId,
      sellerName: this.currentSeller ? this.currentSeller.CompanyName : 'Verified Merchant',
      currentPrice: initialPrice,
      originalPrice: Math.round(initialPrice * 1.4),
      stockQuantity: stockQuantity,
      stockStatus: stockQuantity > 10 ? 'AVAILABLE' : (stockQuantity > 0 ? 'LOW_STOCK' : 'OUT_OF_STOCK'),
      isDealOfTheDay: false,
      rating: 5.0,
      reviewsCount: 0,
      fastDeliveryAvailable: true,
      images: [
        { id: Date.now(), url: productData.imageUrl || 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80', isPrimary: true }
      ],
      priceLedger: [
        {
          id: Date.now(),
          price: initialPrice,
          changedAt: new Date().toISOString().replace('T', ' ').substring(0, 19),
          changeReason: 'Initial Catalog Listing'
        }
      ],
      embedding: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    };

    this.products.unshift(newProd);
    localStorage.setItem('omnicart_products', JSON.stringify(this.products));
    return newProd;
  },

  // Address & Contacts Management
  addCustomerAddress(addressData) {
    if (!this.currentUser || this.currentUserRole !== 'buyer') {
      throw new Error('Please sign in as a customer to manage addresses.');
    }
    const street = (addressData.street || '').trim();
    const city = (addressData.city || '').trim();
    const pincode = (addressData.pincode || '').trim();

    if (!street || !city || !pincode) {
      throw new Error('Street, city, and pincode are required.');
    }

    if (!/^\d{6}$/.test(pincode)) {
      throw new Error('PIN code must be a valid 6-digit postal code.');
    }

    const newAddr = {
      id: Date.now(),
      customerId: this.currentUser.id,
      street: street,
      city: city,
      state: (addressData.state || 'Karnataka').trim(),
      pincode: pincode,
      type: (addressData.type || 'Home').trim(),
      isDefault: this.addresses.length === 0
    };
    this.addresses.push(newAddr);
    localStorage.setItem('omnicart_addresses', JSON.stringify(this.addresses));
    return newAddr;
  },

  deleteCustomerAddress(addressId) {
    const id = Number(addressId);
    this.addresses = this.addresses.filter(a => Number(a.id) !== id);
    localStorage.setItem('omnicart_addresses', JSON.stringify(this.addresses));
    return this.addresses;
  },

  addCustomerPhone(phone, type = 'Mobile') {
    if (!this.currentUser || this.currentUserRole !== 'buyer') {
      throw new Error('Please sign in as a customer to manage phone numbers.');
    }
    const cleanPhone = (phone || '').trim();
    if (!cleanPhone || cleanPhone.length < 10) {
      throw new Error('A valid mobile number with at least 10 digits is required.');
    }

    const newPhone = {
      id: Date.now(),
      customerId: this.currentUser.id,
      phone: cleanPhone,
      type: (type || 'Mobile').trim()
    };
    this.phones.push(newPhone);
    localStorage.setItem('omnicart_phones', JSON.stringify(this.phones));
    return newPhone;
  },

  deleteCustomerPhone(phoneId) {
    const id = Number(phoneId);
    this.phones = this.phones.filter(p => Number(p.id) !== id);
    localStorage.setItem('omnicart_phones', JSON.stringify(this.phones));
    return this.phones;
  },

  addCustomerEmail(email, type = 'Personal') {
    if (!this.currentUser || this.currentUserRole !== 'buyer') {
      throw new Error('Please sign in as a customer to manage email addresses.');
    }
    const cleanEmail = (email || '').trim();
    if (!cleanEmail || !cleanEmail.includes('@') || !cleanEmail.includes('.')) {
      throw new Error('A valid email address (e.g. user@domain.com) is required.');
    }

    const newEmail = {
      id: Date.now(),
      customerId: this.currentUser.id,
      email: cleanEmail,
      type: (type || 'Personal').trim()
    };
    this.emails.push(newEmail);
    localStorage.setItem('omnicart_emails', JSON.stringify(this.emails));
    return newEmail;
  },

  deleteCustomerEmail(emailId) {
    const id = Number(emailId);
    this.emails = this.emails.filter(e => Number(e.id) !== id);
    localStorage.setItem('omnicart_emails', JSON.stringify(this.emails));
    return this.emails;
  }
};

// Auto initialize on load
DataStore.init();
