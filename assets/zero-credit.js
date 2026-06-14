document.documentElement.classList.add('js');

const menuButton = document.querySelector('[data-menu-toggle]');
const mobileMenu = document.querySelector('[data-mobile-menu]');
const cartDrawer = document.querySelector('[data-cart-drawer]');
const cartBackdrop = document.querySelector('[data-cart-backdrop]');
const cartOpenButtons = document.querySelectorAll('[data-cart-open]');
const cartCloseButton = document.querySelector('[data-cart-close]');

function setMenu(open) {
  if (!menuButton || !mobileMenu) return;
  menuButton.setAttribute('aria-expanded', String(open));
  mobileMenu.hidden = !open;
}

function setCart(open) {
  if (!cartDrawer || !cartBackdrop) return;
  cartDrawer.setAttribute('aria-hidden', String(!open));
  cartBackdrop.hidden = !open;
  document.body.classList.toggle('drawer-open', open);
  if (open) cartDrawer.focus();
}

menuButton?.addEventListener('click', () => {
  setMenu(menuButton.getAttribute('aria-expanded') !== 'true');
});

cartOpenButtons.forEach((button) => {
  button.addEventListener('click', (event) => {
    event.preventDefault();
    setCart(true);
  });
});

cartCloseButton?.addEventListener('click', () => setCart(false));
cartBackdrop?.addEventListener('click', () => setCart(false));

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    setMenu(false);
    setCart(false);
  }
});

document.querySelectorAll('[data-sort-select]').forEach((select) => {
  select.addEventListener('change', () => select.form?.submit());
});
