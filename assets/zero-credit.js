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

document.querySelectorAll('[data-product-root]').forEach((productRoot) => {
  const form = productRoot.querySelector('[data-product-form]');
  const variantsData = productRoot.querySelector('[data-product-variants]');
  const variantInput = productRoot.querySelector('[data-variant-id]');
  const addButton = productRoot.querySelector('[data-add-to-cart]');
  const buyNowButton = productRoot.querySelector('[data-buy-now]');
  const price = productRoot.querySelector('[data-product-price] span');
  const comparePrice = productRoot.querySelector('[data-product-price] s');

  if (form && variantsData && variantInput) {
    const variants = JSON.parse(variantsData.textContent);
    const optionGroups = [...productRoot.querySelectorAll('[data-product-option]')];

    function updateVariant() {
      const selectedOptions = optionGroups.map((group) => {
        const checked = group.querySelector('input:checked');
        const optionIndex = group.dataset.productOption;
        const optionLabel = productRoot.querySelector(`[data-option-label="${optionIndex}"]`);
        if (optionLabel && checked) optionLabel.textContent = checked.value;
        return checked?.value;
      });

      const variant = variants.find(
        (candidate) =>
          candidate.options.length === selectedOptions.length &&
          candidate.options.every((option, index) => option === selectedOptions[index])
      );

      if (!variant) {
        if (addButton) {
          addButton.disabled = true;
          addButton.textContent = 'Unavailable';
        }
        if (buyNowButton) buyNowButton.disabled = true;
        return;
      }

      variantInput.value = variant.id;
      if (price) price.textContent = variant.price;
      if (comparePrice) {
        comparePrice.hidden = !variant.compare_at_price;
        comparePrice.textContent = variant.compare_at_price || '';
      }
      if (addButton) {
        addButton.disabled = !variant.available;
        addButton.textContent = variant.available ? 'Add to cart' : 'Sold out';
      }
      if (buyNowButton) buyNowButton.disabled = !variant.available;

      const url = new URL(window.location.href);
      url.searchParams.set('variant', variant.id);
      window.history.replaceState({}, '', url);
    }

    optionGroups.forEach((group) => {
      group.addEventListener('change', updateVariant);
    });

    buyNowButton?.addEventListener('click', async (event) => {
      event.preventDefault();
      if (buyNowButton.disabled) return;

      const originalText = buyNowButton.textContent;
      buyNowButton.disabled = true;
      buyNowButton.textContent = 'Opening checkout...';

      try {
        const rootRoute = window.Shopify?.routes?.root || '/';
        const response = await fetch(`${rootRoute}cart/add.js`, {
          method: 'POST',
          headers: { Accept: 'application/json' },
          body: new FormData(form)
        });
        if (!response.ok) throw new Error('Unable to add product');
        window.location.assign(`${rootRoute}checkout`);
      } catch (error) {
        buyNowButton.disabled = false;
        buyNowButton.textContent = originalText;
      }
    });
  }

  const gallery = productRoot.querySelector('[data-product-gallery]');
  const slides = [...productRoot.querySelectorAll('[data-gallery-slide]')];
  const dots = [...productRoot.querySelectorAll('[data-gallery-dot]')];

  if (gallery && slides.length > 1) {
    let galleryTicking = false;

    function setActiveSlide(index) {
      dots.forEach((dot, dotIndex) => {
        dot.setAttribute('aria-current', String(dotIndex === index));
      });
    }

    function scrollToSlide(index) {
      slides[Math.max(0, Math.min(index, slides.length - 1))]?.scrollIntoView({
        behavior: reduceMotion ? 'auto' : 'smooth',
        block: 'nearest',
        inline: 'start'
      });
    }

    gallery.addEventListener(
      'scroll',
      () => {
        if (galleryTicking) return;
        galleryTicking = true;
        window.requestAnimationFrame(() => {
          const index = Math.round(gallery.scrollLeft / Math.max(gallery.clientWidth, 1));
          setActiveSlide(index);
          galleryTicking = false;
        });
      },
      { passive: true }
    );

    dots.forEach((dot, index) => dot.addEventListener('click', () => scrollToSlide(index)));
    productRoot.querySelector('[data-gallery-prev]')?.addEventListener('click', () => {
      const index = Math.round(gallery.scrollLeft / Math.max(gallery.clientWidth, 1));
      scrollToSlide(index - 1);
    });
    productRoot.querySelector('[data-gallery-next]')?.addEventListener('click', () => {
      const index = Math.round(gallery.scrollLeft / Math.max(gallery.clientWidth, 1));
      scrollToSlide(index + 1);
    });
  }
});

const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const revealItems = document.querySelectorAll('[data-reveal]');
const siteHeader = document.querySelector('.site-header');
const tickerTracks = document.querySelectorAll('[data-ticker-track]');
const tickerPixelsPerSecond = 50;

function syncTickerSpeeds() {
  if (reduceMotion) return;

  tickerTracks.forEach((track) => {
    if (!track.classList.contains('is-animated')) return;

    const cycleLength = Math.max(1, Number(track.dataset.tickerCycle || 1));
    const cycleItems = [...track.children].slice(0, cycleLength);
    const distance = cycleItems.reduce((total, item) => total + item.getBoundingClientRect().width, 0);

    if (!distance) return;

    track.style.setProperty('--ticker-translate', `${-distance}px`);
    track.style.setProperty('--ticker-duration', `${distance / tickerPixelsPerSecond}s`);
  });
}

syncTickerSpeeds();
document.fonts?.ready.then(syncTickerSpeeds);
document.addEventListener('shopify:section:load', syncTickerSpeeds);

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
  siteHeader?.classList.toggle('is-scrolled', window.scrollY > 20);
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

let tickerResizeFrame = null;
window.addEventListener(
  'resize',
  () => {
    if (tickerResizeFrame) window.cancelAnimationFrame(tickerResizeFrame);
    tickerResizeFrame = window.requestAnimationFrame(() => {
      syncTickerSpeeds();
      tickerResizeFrame = null;
    });
  },
  { passive: true }
);

updateScrollEffects();
window.requestAnimationFrame(() => document.documentElement.classList.add('is-ready'));
