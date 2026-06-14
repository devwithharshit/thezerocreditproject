document.documentElement.classList.add('js');

const menuButton = document.querySelector('[data-menu-toggle]');
const mobileMenu = document.querySelector('[data-mobile-menu]');
const menuBackdrop = document.querySelector('[data-menu-backdrop]');
const menuCloseButton = document.querySelector('[data-menu-close]');
const cartDrawer = document.querySelector('[data-cart-drawer]');
const cartBackdrop = document.querySelector('[data-cart-backdrop]');
const cartOpenButtons = document.querySelectorAll('[data-cart-open]');
const cartCloseButton = document.querySelector('[data-cart-close]');
let lastFocusedElement = null;

function updatePageLock() {
  const menuOpen = mobileMenu?.getAttribute('aria-hidden') === 'false';
  const cartOpen = cartDrawer?.getAttribute('aria-hidden') === 'false';
  document.body.classList.toggle('drawer-open', menuOpen || cartOpen);
}

function setMenu(open) {
  if (!menuButton || !mobileMenu) return;
  const wasOpen = mobileMenu.getAttribute('aria-hidden') === 'false';
  if (open) lastFocusedElement = document.activeElement;
  menuButton.setAttribute('aria-expanded', String(open));
  mobileMenu.setAttribute('aria-hidden', String(!open));
  menuBackdrop?.classList.toggle('is-visible', open);
  menuBackdrop?.setAttribute('aria-hidden', String(!open));
  updatePageLock();
  if (open) menuCloseButton?.focus();
  if (!open && wasOpen && lastFocusedElement instanceof HTMLElement) lastFocusedElement.focus();
}

function setCart(open) {
  if (!cartDrawer || !cartBackdrop) return;
  const wasOpen = cartDrawer.getAttribute('aria-hidden') === 'false';
  if (open) lastFocusedElement = document.activeElement;
  cartDrawer.setAttribute('aria-hidden', String(!open));
  cartBackdrop.classList.toggle('is-visible', open);
  cartBackdrop.setAttribute('aria-hidden', String(!open));
  updatePageLock();
  if (open) cartDrawer.focus();
  if (!open && wasOpen && lastFocusedElement instanceof HTMLElement) lastFocusedElement.focus();
}

menuButton?.addEventListener('click', () => {
  setMenu(menuButton.getAttribute('aria-expanded') !== 'true');
});

menuCloseButton?.addEventListener('click', () => setMenu(false));
menuBackdrop?.addEventListener('click', () => setMenu(false));
mobileMenu?.querySelectorAll('a').forEach((link) => {
  link.addEventListener('click', () => setMenu(false));
});

cartOpenButtons.forEach((button) => {
  button.addEventListener('click', (event) => {
    event.preventDefault();
    setCart(true);
  });
});

cartCloseButton?.addEventListener('click', () => setCart(false));
cartBackdrop?.addEventListener('click', () => setCart(false));

window.addEventListener('resize', () => {
  if (window.innerWidth > 1180) setMenu(false);
});

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    setMenu(false);
    setCart(false);
  }
});

document.querySelectorAll('[data-sort-select]').forEach((select) => {
  select.addEventListener('change', () => select.form?.submit());
});

const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const revealItems = document.querySelectorAll('[data-reveal]');
const parallaxItems = document.querySelectorAll('[data-parallax]');
const siteHeader = document.querySelector('.site-header');

revealItems.forEach((item) => {
  const delay = Number(item.dataset.delay || 0);
  item.style.setProperty('--reveal-delay', `${delay}ms`);
});

if (!reduceMotion && 'IntersectionObserver' in window) {
  const revealObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      });
    },
    { rootMargin: '0px 0px -10% 0px', threshold: 0.08 }
  );

  revealItems.forEach((item) => revealObserver.observe(item));
} else {
  revealItems.forEach((item) => item.classList.add('is-visible'));
}

let ticking = false;

function updateScrollEffects() {
  const scrollY = window.scrollY;
  siteHeader?.classList.toggle('is-scrolled', scrollY > 20);

  if (!reduceMotion) {
    parallaxItems.forEach((item) => {
      const speed = Number(item.dataset.speed || 0);
      item.style.transform = `translate3d(0, ${scrollY * speed}px, 0)`;
    });
  }

  ticking = false;
}

window.addEventListener(
  'scroll',
  () => {
    if (ticking) return;
    ticking = true;
    window.requestAnimationFrame(updateScrollEffects);
  },
  { passive: true }
);

updateScrollEffects();
window.requestAnimationFrame(() => document.documentElement.classList.add('is-ready'));
