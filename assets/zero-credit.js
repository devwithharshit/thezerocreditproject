document.documentElement.classList.add('js');

if (window.location.search.includes('customer_posted=true') && window.location.hash === '#contact_form') {
  window.history.replaceState(null, '', `${window.location.pathname}${window.location.search}`);
  window.requestAnimationFrame(() => {
    window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
  });
}

const menuButton = document.querySelector('[data-menu-toggle]');
const mobileMenu = document.querySelector('[data-mobile-menu]');
const menuBackdrop = document.querySelector('[data-menu-backdrop]');
const menuCloseButton = document.querySelector('[data-menu-close]');
let lastFocusedElement = null;
let activeProductZoomClose = null;

function setElementInert(element, inert) {
  if (!element) return;
  element.inert = inert;
  element.toggleAttribute('inert', inert);
}

setElementInert(mobileMenu, true);
setElementInert(document.querySelector('[data-cart-drawer]'), true);

function updatePageLock() {
  const menuOpen = mobileMenu?.getAttribute('aria-hidden') === 'false';
  const cartOpen = document.querySelector('[data-cart-drawer]')?.getAttribute('aria-hidden') === 'false';
  const productZoomOpen =
    document.querySelector('[data-product-zoom-dialog]')?.getAttribute('aria-hidden') === 'false';
  document.body.classList.toggle('drawer-open', menuOpen || cartOpen || productZoomOpen);
}

function setMenu(open, restoreFocus = true) {
  if (!menuButton || !mobileMenu) return;
  const wasOpen = mobileMenu.getAttribute('aria-hidden') === 'false';
  if (open) {
    setCart(false, false);
    lastFocusedElement = document.activeElement;
  }
  menuButton.setAttribute('aria-expanded', String(open));
  mobileMenu.setAttribute('aria-hidden', String(!open));
  setElementInert(mobileMenu, !open);
  menuBackdrop?.classList.toggle('is-visible', open);
  menuBackdrop?.setAttribute('aria-hidden', String(!open));
  updatePageLock();
  if (open) menuCloseButton?.focus();
  if (!open && wasOpen && restoreFocus && lastFocusedElement instanceof HTMLElement) lastFocusedElement.focus();
}

function setCart(open, restoreFocus = true) {
  const cartDrawer = document.querySelector('[data-cart-drawer]');
  const cartBackdrop = document.querySelector('[data-cart-backdrop]');
  if (!cartDrawer || !cartBackdrop) return;
  const wasOpen = cartDrawer.getAttribute('aria-hidden') === 'false';
  if (open) {
    setMenu(false, false);
    lastFocusedElement = document.activeElement;
  }
  cartDrawer.setAttribute('aria-hidden', String(!open));
  setElementInert(cartDrawer, !open);
  cartBackdrop.classList.toggle('is-visible', open);
  cartBackdrop.setAttribute('aria-hidden', String(!open));
  document.querySelectorAll('[data-cart-open]').forEach((button) => {
    button.setAttribute('aria-expanded', String(open));
  });
  updatePageLock();
  if (open) cartDrawer.focus();
  if (!open && wasOpen && restoreFocus && lastFocusedElement instanceof HTMLElement) lastFocusedElement.focus();
}

menuButton?.addEventListener('click', () => {
  setMenu(menuButton.getAttribute('aria-expanded') !== 'true');
});

menuCloseButton?.addEventListener('click', () => setMenu(false));
menuBackdrop?.addEventListener('click', () => setMenu(false));
mobileMenu?.querySelectorAll('a').forEach((link) => {
  link.addEventListener('click', () => setMenu(false));
});

document.addEventListener('click', (event) => {
  const cartOpenButton = event.target.closest('[data-cart-open]');
  if (cartOpenButton) {
    event.preventDefault();
    setCart(true);
    return;
  }

  if (event.target.closest('[data-cart-close]') || event.target.closest('[data-cart-backdrop]')) {
    setCart(false);
  }
});

window.addEventListener('resize', () => {
  if (window.innerWidth > 1180) setMenu(false);
});

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    activeProductZoomClose?.();
    setMenu(false);
    setCart(false);
    return;
  }

  if (event.key !== 'Tab') return;

  const openOverlay =
    document.querySelector('[data-product-zoom-dialog][aria-hidden="false"]') ||
    document.querySelector('[data-cart-drawer][aria-hidden="false"]') ||
    document.querySelector('[data-mobile-menu][aria-hidden="false"]');

  if (!openOverlay) return;

  const focusableElements = [
    ...openOverlay.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )
  ].filter((element) => element.getClientRects().length > 0);

  if (!focusableElements.length) {
    event.preventDefault();
    openOverlay.focus();
    return;
  }

  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];

  if (event.shiftKey && (document.activeElement === firstElement || document.activeElement === openOverlay)) {
    event.preventDefault();
    lastElement.focus();
  } else if (!event.shiftKey && document.activeElement === lastElement) {
    event.preventDefault();
    firstElement.focus();
  }
});

document.querySelectorAll('[data-sort-select]').forEach((select) => {
  select.addEventListener('change', () => select.form?.submit());
});

function updateCartCount(count) {
  document.querySelectorAll('.cart-count').forEach((element) => {
    element.textContent = count;
  });
}

function replaceCartDrawer(html) {
  if (!html) return false;

  const parsedDocument = new DOMParser().parseFromString(html, 'text/html');
  const updatedSection = parsedDocument.querySelector('#shopify-section-cart-drawer');
  const currentSection = document.querySelector('#shopify-section-cart-drawer');

  if (!updatedSection || !currentSection) return false;
  const updatedNodes = [...updatedSection.childNodes].map((node) => document.importNode(node, true));
  currentSection.replaceChildren(...updatedNodes);
  return true;
}

async function fetchCartDrawer(rootRoute) {
  const response = await fetch(`${rootRoute}?sections=cart-drawer`, {
    headers: { Accept: 'application/json' }
  });
  if (!response.ok) throw new Error('Unable to refresh cart');
  const sections = await response.json();
  return sections['cart-drawer'];
}

document.addEventListener('submit', async (event) => {
  const form = event.target.closest('[data-ajax-cart-form]');
  if (!form) return;

  event.preventDefault();

  const submitButton = event.submitter || form.querySelector('[type="submit"]');
  const buttonLabel = submitButton?.querySelector('[data-cart-button-label]');
  const originalLabel = buttonLabel?.textContent || submitButton?.textContent || '';
  const rootRoute = window.Shopify?.routes?.root || '/';
  const formData = new FormData(form);

  formData.set('sections', 'cart-drawer');
  formData.set('sections_url', window.location.pathname);

  if (submitButton) {
    submitButton.disabled = true;
    submitButton.setAttribute('aria-busy', 'true');
  }
  if (buttonLabel) buttonLabel.textContent = 'Adding...';

  try {
    const addResponse = await fetch(`${rootRoute}cart/add.js`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: formData
    });
    const addResult = await addResponse.json();

    if (!addResponse.ok) {
      throw new Error(addResult.description || 'Unable to add this item');
    }

    const cartResponse = await fetch(`${rootRoute}cart.js`, {
      headers: { Accept: 'application/json' }
    });
    if (!cartResponse.ok) throw new Error('Unable to load cart');
    const cart = await cartResponse.json();

    let drawerHtml = addResult.sections?.['cart-drawer'];
    if (!drawerHtml) drawerHtml = await fetchCartDrawer(rootRoute);

    replaceCartDrawer(drawerHtml);
    updateCartCount(cart.item_count);
    setCart(true);
  } catch (error) {
    if (buttonLabel) {
      buttonLabel.textContent = error.message || 'Try again';
      window.setTimeout(() => {
        buttonLabel.textContent = originalLabel;
      }, 2200);
    }
  } finally {
    if (submitButton) {
      submitButton.disabled = false;
      submitButton.removeAttribute('aria-busy');
    }
    if (buttonLabel && buttonLabel.textContent === 'Adding...') {
      buttonLabel.textContent = originalLabel;
    }
  }
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
    let variants;

    try {
      variants = JSON.parse(variantsData.textContent);
    } catch (error) {
      console.error('Unable to read product variants', error);
      return;
    }

    const optionGroups = [...productRoot.querySelectorAll('[data-product-option]')];

    function setAddButtonLabel(text) {
      const addButtonLabel = addButton?.querySelector('[data-cart-button-label]');
      if (addButtonLabel) addButtonLabel.textContent = text;
    }

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
          setAddButtonLabel('Unavailable');
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
        setAddButtonLabel(variant.available ? 'Add to cart' : 'Sold out');
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
  const zoomDialog = productRoot.querySelector('[data-product-zoom-dialog]');
  const zoomImage = productRoot.querySelector('[data-product-zoom-image]');
  const zoomStage = productRoot.querySelector('[data-product-zoom-stage]');
  const zoomLevel = productRoot.querySelector('[data-product-zoom-level]');

  if (zoomDialog && zoomImage && zoomStage) {
    const zoomTriggers = [...productRoot.querySelectorAll('[data-product-zoom]')];
    let zoomTrigger = null;
    let zoomScale = 1;
    let zoomPanX = 0;
    let zoomPanY = 0;
    let dragStartX = 0;
    let dragStartY = 0;
    let dragOriginX = 0;
    let dragOriginY = 0;

    setElementInert(zoomDialog, true);

    function clampZoomPan() {
      if (zoomScale <= 1) {
        zoomPanX = 0;
        zoomPanY = 0;
        return;
      }

      const maxX = (zoomStage.clientWidth * (zoomScale - 1)) / 2;
      const maxY = (zoomStage.clientHeight * (zoomScale - 1)) / 2;
      zoomPanX = Math.max(-maxX, Math.min(maxX, zoomPanX));
      zoomPanY = Math.max(-maxY, Math.min(maxY, zoomPanY));
    }

    function renderProductZoom() {
      clampZoomPan();
      zoomImage.style.transform = `translate3d(${zoomPanX}px, ${zoomPanY}px, 0) scale(${zoomScale})`;
      if (zoomLevel) zoomLevel.textContent = `${Math.round(zoomScale * 100)}%`;
      zoomStage.classList.toggle('is-zoomed', zoomScale > 1);
    }

    function setProductZoomScale(nextScale) {
      zoomScale = Math.max(1, Math.min(4, nextScale));
      renderProductZoom();
    }

    function resetProductZoom() {
      zoomScale = 1;
      zoomPanX = 0;
      zoomPanY = 0;
      renderProductZoom();
    }

    function closeProductZoom() {
      if (zoomDialog.getAttribute('aria-hidden') !== 'false') return;
      zoomDialog.setAttribute('aria-hidden', 'true');
      setElementInert(zoomDialog, true);
      resetProductZoom();
      updatePageLock();
      activeProductZoomClose = null;
      if (zoomTrigger instanceof HTMLElement) zoomTrigger.focus();
    }

    function openProductZoom(trigger) {
      const source = trigger.dataset.zoomSrc;
      if (!source) return;

      setMenu(false, false);
      setCart(false, false);
      zoomTrigger = trigger;
      zoomImage.src = source;
      zoomImage.alt = trigger.dataset.zoomAlt || '';
      resetProductZoom();
      zoomDialog.setAttribute('aria-hidden', 'false');
      setElementInert(zoomDialog, false);
      updatePageLock();
      activeProductZoomClose = closeProductZoom;
      window.requestAnimationFrame(() => zoomDialog.querySelector('[data-product-zoom-close]')?.focus());
    }

    zoomTriggers.forEach((trigger) => {
      trigger.addEventListener('click', () => openProductZoom(trigger));
    });

    zoomDialog.querySelector('[data-product-zoom-close]')?.addEventListener('click', closeProductZoom);
    zoomDialog.querySelector('[data-product-zoom-in]')?.addEventListener('click', () => {
      setProductZoomScale(zoomScale + 0.5);
    });
    zoomDialog.querySelector('[data-product-zoom-out]')?.addEventListener('click', () => {
      setProductZoomScale(zoomScale - 0.5);
    });
    zoomDialog.querySelector('[data-product-zoom-reset]')?.addEventListener('click', resetProductZoom);

    zoomStage.addEventListener('dblclick', () => {
      setProductZoomScale(zoomScale > 1 ? 1 : 2.5);
    });

    zoomStage.addEventListener(
      'wheel',
      (event) => {
        event.preventDefault();
        setProductZoomScale(zoomScale + (event.deltaY < 0 ? 0.25 : -0.25));
      },
      { passive: false }
    );

    zoomStage.addEventListener('pointerdown', (event) => {
      if (zoomScale <= 1) return;
      dragStartX = event.clientX;
      dragStartY = event.clientY;
      dragOriginX = zoomPanX;
      dragOriginY = zoomPanY;
      zoomStage.classList.add('is-dragging');
      zoomStage.setPointerCapture(event.pointerId);
    });

    zoomStage.addEventListener('pointermove', (event) => {
      if (!zoomStage.hasPointerCapture(event.pointerId)) return;
      zoomPanX = dragOriginX + event.clientX - dragStartX;
      zoomPanY = dragOriginY + event.clientY - dragStartY;
      renderProductZoom();
    });

    function stopProductZoomDrag(event) {
      if (zoomStage.hasPointerCapture(event.pointerId)) {
        zoomStage.releasePointerCapture(event.pointerId);
      }
      zoomStage.classList.remove('is-dragging');
    }

    zoomStage.addEventListener('pointerup', stopProductZoomDrag);
    zoomStage.addEventListener('pointercancel', stopProductZoomDrag);
    window.addEventListener('resize', renderProductZoom);
  }

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
const comingSoonAtmosphere = document.querySelector('[data-coming-soon-atmosphere]');

if (comingSoonAtmosphere && !reduceMotion) {
  let spotlightFrame = null;
  let spotlightEvent = null;

  comingSoonAtmosphere.addEventListener(
    'pointermove',
    (event) => {
      spotlightEvent = event;
      if (spotlightFrame) return;

      spotlightFrame = window.requestAnimationFrame(() => {
        const rect = comingSoonAtmosphere.getBoundingClientRect();
        const x = ((spotlightEvent.clientX - rect.left) / Math.max(rect.width, 1)) * 100;
        const y = ((spotlightEvent.clientY - rect.top) / Math.max(rect.height, 1)) * 100;
        comingSoonAtmosphere.style.setProperty('--spotlight-x', `${Math.min(100, Math.max(0, x))}%`);
        comingSoonAtmosphere.style.setProperty('--spotlight-y', `${Math.min(100, Math.max(0, y))}%`);
        spotlightFrame = null;
      });
    },
    { passive: true }
  );
}

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
