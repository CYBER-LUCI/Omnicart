/**
 * OmniCart App — Global Application Initializer
 * Orchestrates cross-cutting concerns: header badges, global search bindings,
 * modal escape triggers, and dropdown backdrop dismissals.
 */

const App = {
  init() {
    // Initial UI Header Sync
    if (window.UIModule) {
      window.UIModule.renderHeader();
    }

    // Global Search Bar Handler (Enter key)
    const searchInputs = document.querySelectorAll('.global-search-input');
    searchInputs.forEach(input => {
      input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
          const val = input.value.trim();
          if (val) {
            window.location.href = `products.html?search=${encodeURIComponent(val)}`;
          }
        }
      });
    });

    // Close Auth Dropdown when clicking outside
    document.addEventListener('click', (e) => {
      const dropdown = document.getElementById('auth-dropdown-menu');
      const toggleBtn = e.target.closest('button[onclick*="toggleAuthDropdown"]');
      if (dropdown && !dropdown.classList.contains('hidden') && !dropdown.contains(e.target) && !toggleBtn) {
        dropdown.classList.add('hidden');
      }
    });

    // Close Modals on Escape Key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        const authModal = document.getElementById('auth-modal');
        if (authModal && !authModal.classList.contains('hidden')) {
          authModal.classList.add('hidden');
        }

        const vsModal = document.getElementById('visual-search-modal');
        if (vsModal && !vsModal.classList.contains('hidden')) {
          vsModal.classList.add('hidden');
        }

        const addProdModal = document.getElementById('add-product-modal');
        if (addProdModal && !addProdModal.classList.contains('hidden')) {
          addProdModal.classList.add('hidden');
        }
      }
    });
  }
};

window.App = App;

window.addEventListener('DOMContentLoaded', () => {
  App.init();
});
