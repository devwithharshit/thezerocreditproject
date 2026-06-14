#!/usr/bin/env zsh
set -euo pipefail

echo "Creating The Zero Credit Project Shopify theme..."

mkdir -p layout sections snippets assets templates config locales

# ============================================================
# LAYOUT
# ============================================================
cat > layout/theme.liquid <<'EOF'
<!doctype html>
<html lang="{{ request.locale.iso_code }}" class="no-js">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="theme-color" content="{{ settings.color_background | default: '#FAFAFA' }}">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="preload" as="style" 
href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Syne:wght@500;600;700;800&display=swap">
    <link rel="stylesheet" 
href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Syne:wght@500;600;700;800&display=swap" media="print" 
onload="this.media='all'">

    {{ content_for_header }}
    {{ 'zero-credit.css' | asset_url | stylesheet_tag }}
    <script src="{{ 'zero-credit.js' | asset_url }}" defer></script>

    <title>{{ page_title }}{% if page_title != shop.name %} — {{ shop.name }}{% endif %}</title>
    <meta name="description" content="{{ page_description | escape }}">
  </head>

  <body class="gradient-bg" data-route="{{ request.page_type }}" data-template="{{ template.name }}" data-currency="{{ cart.currency.iso_code 
}}">
    <a href="#main-content" class="skip-link">Skip to main content</a>

    {% section 'announcement-bar' %}

    <header class="site-header" id="site-header" role="banner">
      {% section 'header' %}
    </header>

    {% section 'search-overlay' %}
    {% section 'cart-drawer' %}
    {% section 'mobile-menu' %}

    <main id="main-content" role="main" class="main-content">
      {{ content_for_layout }}
    </main>

    <footer class="site-footer" role="contentinfo">
      {% section 'footer' %}
    </footer>

    <script>
      window.ZCP = window.ZCP || {};
      window.ZCP.routes = {
        cart_add: '{{ routes.cart_add_url }}',
        cart_change: '{{ routes.cart_change_url }}',
        cart_get: '{{ routes.cart_url }}.js',
        search: '{{ routes.search_url }}',
        search_predictive: '{{ routes.search_predictive_url }}'
      };
      window.ZCP.currency = {
        iso_code: '{{ cart.currency.iso_code }}',
        format: '{{ shop.money_format | replace: '{{amount}}', '' | replace: '"', '' | strip }}'
      };
      window.ZCP.cartCount = {{ cart.item_count | default: 0 }};
      window.ZCP.settings = {
        enableAnimations: {{ settings.enable_animations | default: true | json }}
      };
    </script>
  </body>
</html>
EOF

# ============================================================
# SECTIONS
# ============================================================

cat > sections/announcement-bar.liquid <<'EOF'
{% comment %}
Announcement Bar — slim top bar with marquee rotation.
Settings: messages (text list), rotation speed, text color, bg color, show close.
{% endcomment %}
{% if section.settings.messages.size > 0 or section.blocks.size > 0 %}
  <div class="announcement-bar" role="region" aria-label="Announcements" data-announcement-bar style="--announcement-bg: {{ 
section.settings.bg_color }}; --announcement-text: {{ section.settings.text_color }}; --announcement-speed: {{ section.settings.rotation_speed 
}}ms;">
    <div class="announcement-bar__track" aria-live="polite" aria-atomic="true">
      {% liquid
        assign all_messages = ''
        for block in section.blocks
          assign all_messages = all_messages | append: block.settings.text | append: ' • '
        endfor
        for msg in section.settings.messages
          assign all_messages = all_messages | append: msg | append: ' • '
        endfor
      %}
      <div class="announcement-bar__content">{{ all_messages }}</div>
      <div class="announcement-bar__content" aria-hidden="true">{{ all_messages }}</div>
    </div>
    {% if section.settings.show_close %}
      <button class="announcement-bar__close" aria-label="Dismiss announcement" data-announcement-close>
        {% render 'icon-close' %}
      </button>
    {% endif %}
  </div>
{% endif %}

{% schema %}
{
  "name": "Announcement Bar",
  "tag": "",
  "class": "announcement-bar-section",
  "settings": [
    {
      "type": "textarea",
      "id": "messages",
      "label": "Messages (one per line)",
      "default": "Made to order. Built from zero.\nNew drops coming soon.\nFollow the project. Own the process.\nLimited pieces. No 
shortcuts.\nBuilt for people starting from zero."
    },
    {
      "type": "range",
      "id": "rotation_speed",
      "label": "Rotation speed (ms)",
      "min": 2000,
      "max": 15000,
      "step": 500,
      "default": 6000
    },
    {
      "type": "color",
      "id": "bg_color",
      "label": "Background color",
      "default": "#111111"
    },
    {
      "type": "color",
      "id": "text_color",
      "label": "Text color",
      "default": "#FFFFFF"
    },
    {
      "type": "checkbox",
      "id": "show_close",
      "label": "Show dismiss button",
      "default": true
    }
  ],
  "blocks": [
    {
      "type": "message",
      "name": "Custom Message",
      "settings": [
        {
          "type": "text",
          "id": "text",
          "label": "Message text",
          "default": "Custom announcement"
        }
      ]
    }
  ],
  "presets": [
    { "name": "Announcement Bar" }
  ]
}
{% endschema %}
EOF

cat > sections/header.liquid <<'EOF'
{% comment %}
Sticky Header — centered logo, left nav, right icons (search, account, cart).
Settings: logo, menu, transparent on home, compact on scroll.
{% endcomment %}
<header class="header header--{{ section.settings.logo_position }}" data-header data-sticky>
  <div class="header__container container">
    {% comment %} Left: Navigation {% endcomment %}
    <nav class="header__nav header__nav--left" aria-label="Main navigation" role="navigation">
      {% if section.settings.menu != blank %}
        <ul class="header__menu list-unstyled flex gap-8" role="menubar">
          {% for link in section.settings.menu.links %}
            <li role="none">
              <a href="{{ link.url }}" class="header__menu-link {% if link.active %}header__menu-link--active{% endif %}" role="menuitem" {% 
if link.links.size > 0 %}aria-haspopup="true" aria-expanded="false"{% endif %}>
                {{ link.title }}
                {% if link.links.size > 0 %}{% render 'icon-chevron-down', class: 'header__menu-icon' %}{% endif %}
              </a>
              {% if link.links.size > 0 %}
                <ul class="header__submenu list-unstyled" role="menu">
                  {% for sublink in link.links %}
                    <li role="none"><a href="{{ sublink.url }}" class="header__submenu-link" role="menuitem">{{ sublink.title }}</a></li>
                  {% endfor %}
                </ul>
              {% endif %}
            </li>
          {% endfor %}
        </ul>
      {% endif %}
    </nav>

    {% comment %} Center: Logo {% endcomment %}
    <div class="header__logo-wrapper" aria-label="Home">
      <a href="{{ routes.root_url }}" class="header__logo-link" aria-label="{{ shop.name }} — Home">
        {% if section.settings.logo_image != blank %}
          {{ section.settings.logo_image | image_tag: width: section.settings.logo_width, height: section.settings.logo_height, class: 
'header__logo-image', loading: 'eager', fetchpriority: 'high', alt: shop.name }}
        {% else %}
          <span class="header__logo-text">{{ shop.name }}</span>
        {% endif %}
      </a>
    </div>

    {% comment %} Right: Icons {% endcomment %}
    <div class="header__actions flex items-center gap-6" role="navigation" aria-label="User actions">
      <button class="header__icon-btn" aria-label="Search" data-search-open>
        {% render 'icon-search' %}
      </button>

      {% if customer_accounts_enabled %}
        <a href="{{ routes.account_url }}" class="header__icon-btn" aria-label="Account">
          {% render 'icon-account' %}
        </a>
      {% endif %}

      <button class="header__icon-btn header__icon-btn--cart" aria-label="Cart ({{ cart.item_count }} items)" data-cart-open>
        {% render 'icon-cart' %}
        {% if cart.item_count > 0 %}
          <span class="header__cart-count" aria-live="polite" aria-atomic="true">{{ cart.item_count }}</span>
        {% endif %}
      </button>

      <button class="header__mobile-menu-btn" aria-label="Menu" aria-expanded="false" aria-controls="mobile-menu" data-mobile-menu-open>
        {% render 'icon-menu' %}
      </button>
    </div>
  </div>
</header>

{% schema %}
{
  "name": "Header",
  "tag": "header",
  "class": "header-section",
  "settings": [
    {
      "type": "image_picker",
      "id": "logo_image",
      "label": "Logo image"
    },
    {
      "type": "range",
      "id": "logo_width",
      "label": "Logo width (px)",
      "min": 80,
      "max": 300,
      "step": 10,
      "default": 140
    },
    {
      "type": "range",
      "id": "logo_height",
      "label": "Logo height (px)",
      "min": 30,
      "max": 150,
      "step": 5,
      "default": 40
    },
    {
      "type": "select",
      "id": "logo_position",
      "label": "Logo position",
      "options": [
        { "value": "center", "label": "Centered" },
        { "value": "left", "label": "Left" }
      ],
      "default": "center"
    },
    {
      "type": "link_list",
      "id": "menu",
      "label": "Main menu",
      "default": "main-menu"
    },
    {
      "type": "checkbox",
      "id": "transparent_home",
      "label": "Transparent on homepage",
      "default": true
    },
    {
      "type": "checkbox",
      "id": "compact_scroll",
      "label": "Compact on scroll",
      "default": true
    }
  ],
  "presets": [{ "name": "Header" }]
}
{% endschema %}
EOF

cat > sections/hero-zero-credit.liquid <<'EOF'
{% comment %}
Hero Section — full-screen brand statement with CTA buttons.
Settings: heading, subheading, background image/video, CTA text/links, alignment.
{% endcomment %}
<section class="hero hero--{{ section.settings.alignment }}" data-hero aria-labelledby="hero-heading">
  {% if section.settings.background_image != blank %}
    <div class="hero__media" aria-hidden="true">
      {{ section.settings.background_image | image_tag: width: 1920, height: 1080, class: 'hero__image', loading: 'eager', fetchpriority: 
'high', sizes: '100vw', alt: '' }}
    </div>
  {% else %}
    <div class="hero__placeholder" aria-hidden="true"></div>
  {% endif %}

  <div class="hero__overlay"></div>

  <div class="hero__content container reveal">
    <h1 id="hero-heading" class="hero__title">{{ section.settings.heading | escape }}</h1>
    {% if section.settings.subheading != blank %}
      <p class="hero__subtitle">{{ section.settings.subheading | escape }}</p>
    {% endif %}

    <div class="hero__actions flex flex-wrap gap-4 mt-8">
      {% if section.settings.cta_primary_text != blank and section.settings.cta_primary_link != blank %}
        <a href="{{ section.settings.cta_primary_link }}" class="btn btn--primary">{{ section.settings.cta_primary_text | escape }}</a>
      {% endif %}
      {% if section.settings.cta_secondary_text != blank and section.settings.cta_secondary_link != blank %}
        <a href="{{ section.settings.cta_secondary_link }}" class="btn btn--outline">{{ section.settings.cta_secondary_text | escape }}</a>
      {% endif %}
    </div>

    {% if section.settings.show_scroll_hint %}
      <div class="hero__scroll-hint reveal" style="transition-delay: 400ms">
        {% render 'icon-chevron-down', class: 'hero__scroll-icon' %}
        <span>Scroll</span>
      </div>
    {% endif %}
  </div>
</section>

{% schema %}
{
  "name": "Hero - Zero Credit",
  "tag": "section",
  "class": "hero-section",
  "settings": [
    {
      "type": "text",
      "id": "heading",
      "label": "Heading",
      "default": "The Zero Credit Project"
    },
    {
      "type": "textarea",
      "id": "subheading",
      "label": "Subheading",
      "default": "No credit. No shortcuts. Just the project."
    },
    {
      "type": "image_picker",
      "id": "background_image",
      "label": "Background image (optional)"
    },
    {
      "type": "select",
      "id": "alignment",
      "label": "Content alignment",
      "options": [
        { "value": "center", "label": "Center" },
        { "value": "left", "label": "Left" },
        { "value": "right", "label": "Right" }
      ],
      "default": "center"
    },
    {
      "type": "text",
      "id": "cta_primary_text",
      "label": "Primary CTA text",
      "default": "Shop the Drop"
    },
    {
      "type": "url",
      "id": "cta_primary_link",
      "label": "Primary CTA link",
      "default": "/collections/all"
    },
    {
      "type": "text",
      "id": "cta_secondary_text",
      "label": "Secondary CTA text",
      "default": "Explore the Project"
    },
    {
      "type": "url",
      "id": "cta_secondary_link",
      "label": "Secondary CTA link",
      "default": "/collections"
    },
    {
      "type": "checkbox",
      "id": "show_scroll_hint",
      "label": "Show scroll indicator",
      "default": true
    }
  ],
  "presets": [{ "name": "Hero - Zero Credit" }]
}
{% endschema %}
EOF

cat > sections/featured-products.liquid <<'EOF'
{% comment %}
Featured Products Grid — pulls from a collection, renders product-card snippet.
Settings: collection, title, subtitle, products per row, show view all.
{% endcomment %}
{% assign collection = collections[section.settings.collection] %}
{% if collection == blank %}{% return %}{% endif %}

<section class="featured-products" data-featured-products aria-labelledby="featured-heading">
  <div class="container">
    <header class="section-header reveal">
      <h2 id="featured-heading" class="section-header__title">{{ section.settings.title | escape }}</h2>
      {% if section.settings.subtitle != blank %}
        <p class="section-header__subtitle">{{ section.settings.subtitle | escape }}</p>
      {% endif %}
      {% if section.settings.show_view_all and collection.url != blank %}
        <a href="{{ collection.url }}" class="section-header__view-all" aria-label="View all {{ collection.title }}">{{ 
'sections.featured_products.view_all' | t }} →</a>
      {% endif %}
    </header>

    <div class="product-grid product-grid--{{ section.settings.products_per_row }}cols" role="list">
      {% for product in collection.products limit: section.settings.limit %}
        {% render 'product-card', product: product, show_vendor: false, show_badges: section.settings.show_badges, quick_add: 
section.settings.enable_quick_add %}
      {% else %}
        <p class="product-grid__empty">{{ 'sections.featured_products.no_products' | t }}</p>
      {% endfor %}
    </div>
  </div>
</section>

{% schema %}
{
  "name": "Featured Products",
  "tag": "section",
  "class": "featured-products-section",
  "settings": [
    {
      "type": "collection",
      "id": "collection",
      "label": "Collection"
    },
    {
      "type": "text",
      "id": "title",
      "label": "Section title",
      "default": "Current Drop"
    },
    {
      "type": "textarea",
      "id": "subtitle",
      "label": "Subtitle",
      "default": "Essentials for the self-made."
    },
    {
      "type": "range",
      "id": "limit",
      "label": "Products to show",
      "min": 1,
      "max": 20,
      "step": 1,
      "default": 8
    },
    {
      "type": "select",
      "id": "products_per_row",
      "label": "Products per row (desktop)",
      "options": [
        { "value": "2", "label": "2" },
        { "value": "3", "label": "3" },
        { "value": "4", "label": "4" },
        { "value": "5", "label": "5" }
      ],
      "default": "4"
    },
    {
      "type": "checkbox",
      "id": "show_badges",
      "label": "Show 'Made to order' / 'New' badges",
      "default": true
    },
    {
      "type": "checkbox",
      "id": "enable_quick_add",
      "label": "Enable Quick Add to cart",
      "default": true
    },
    {
      "type": "checkbox",
      "id": "show_view_all",
      "label": "Show 'View all' link",
      "default": true
    }
  ],
  "presets": [{ "name": "Featured Products" }]
}
{% endschema %}
EOF

cat > sections/editorial-story.liquid <<'EOF'
{% comment %}
Editorial Story — large image + text block for brand storytelling.
Settings: image, heading, body (richtext), alignment, button.
{% endcomment %}
<section class="editorial" data-editorial>
  <div class="editorial__grid container">
    <div class="editorial__media reveal">
      {% if section.settings.image != blank %}
        {{ section.settings.image | image_tag: width: 1200, height: 1600, class: 'editorial__image', loading: 'lazy', alt: 
section.settings.image.alt | default: section.settings.heading | escape }}
      {% else %}
        <div class="editorial__placeholder" aria-hidden="true"></div>
      {% endif %}
    </div>

    <div class="editorial__content reveal">
      {% if section.settings.eyebrow != blank %}
        <p class="editorial__eyebrow">{{ section.settings.eyebrow | escape }}</p>
      {% endif %}
      <h2 class="editorial__heading">{{ section.settings.heading | escape }}</h2>
      {% if section.settings.body != blank %}
        <div class="editorial__body rte">{{ section.settings.body }}</div>
      {% endif %}
      {% if section.settings.button_text != blank and section.settings.button_link != blank %}
        <a href="{{ section.settings.button_link }}" class="btn btn--primary mt-6">{{ section.settings.button_text | escape }}</a>
      {% endif %}
    </div>
  </div>
</section>

{% schema %}
{
  "name": "Editorial Story",
  "tag": "section",
  "class": "editorial-section",
  "settings": [
    {
      "type": "image_picker",
      "id": "image",
      "label": "Image"
    },
    {
      "type": "text",
      "id": "eyebrow",
      "label": "Eyebrow text",
      "default": "Philosophy"
    },
    {
      "type": "text",
      "id": "heading",
      "label": "Heading",
      "default": "Built from zero, not from privilege."
    },
    {
      "type": "richtext",
      "id": "body",
      "label": "Body text",
      "default": "<p>We don't believe in shortcuts. Every piece is made to order — cut, sewn, and finished with intent. No mass production. No 
fake scarcity. Just product built for the long haul.</p>"
    },
    {
      "type": "select",
      "id": "alignment",
      "label": "Layout",
      "options": [
        { "value": "image-left", "label": "Image left, text right" },
        { "value": "image-right", "label": "Image right, text left" }
      ],
      "default": "image-left"
    },
    {
      "type": "text",
      "id": "button_text",
      "label": "Button text",
      "default": "Read the manifesto"
    },
    {
      "type": "url",
      "id": "button_link",
      "label": "Button link",
      "default": "/pages/about"
    }
  ],
  "presets": [{ "name": "Editorial Story" }]
}
{% endschema %}
EOF

cat > sections/brand-marquee.liquid <<'EOF'
{% comment %}
Brand Marquee — infinite scrolling brand line (e.g., "NO CREDIT • NO SHORTCUTS • JUST THE PROJECT").
Settings: text, speed, direction, gap, font size.
{% endcomment %}
{% if section.settings.text != blank %}
  <div class="marquee" data-marquee role="region" aria-label="Brand marquee" style="--marquee-speed: {{ section.settings.speed }}s; 
--marquee-direction: {{ section.settings.direction }}; --marquee-color: {{ section.settings.color }}; --marquee-font-size: {{ 
section.settings.font_size }}rem;">
    <div class="marquee__track">
      {% liquid
        assign repeat_count = 12
        assign full_text = ''
        for i in (1..repeat_count)
          assign full_text = full_text | append: section.settings.text | append: '  '
        endfor
      %}
      <span class="marquee__content" aria-hidden="true">{{ full_text }}</span>
      <span class="marquee__content" aria-hidden="true">{{ full_text }}</span>
    </div>
  </div>
{% endif %}

{% schema %}
{
  "name": "Brand Marquee",
  "tag": "section",
  "class": "marquee-section",
  "settings": [
    {
      "type": "text",
      "id": "text",
      "label": "Marquee text",
      "default": "NO CREDIT  •  NO SHORTCUTS  •  JUST THE PROJECT  •  FROM ZERO  •  NOT PRIVILEGE"
    },
    {
      "type": "range",
      "id": "speed",
      "label": "Animation duration (seconds)",
      "min": 10,
      "max": 60,
      "step": 5,
      "default": 30
    },
    {
      "type": "select",
      "id": "direction",
      "label": "Direction",
      "options": [
        { "value": "left", "label": "Left" },
        { "value": "right", "label": "Right" }
      ],
      "default": "left"
    },
    {
      "type": "color",
      "id": "color",
      "label": "Text color",
      "default": "#111111"
    },
    {
      "type": "range",
      "id": "font_size",
      "label": "Font size (rem)",
      "min": 1.5,
      "max": 5,
      "step": 0.25,
      "default": 2.5
    }
  ],
  "presets": [{ "name": "Brand Marquee" }]
}
{% endschema %}
EOF

cat > sections/newsletter-zero-credit.liquid <<'EOF'
{% comment %}
Newsletter Section — email capture with brand voice.
Settings: heading, subheading, placeholder, button text, background.
{% endcomment %}
<section class="newsletter newsletter--{{ section.settings.style }}" data-newsletter aria-labelledby="newsletter-heading">
  <div class="container">
    <div class="newsletter__inner reveal">
      <div class="newsletter__content">
        <h2 id="newsletter-heading" class="newsletter__title">{{ section.settings.heading | escape }}</h2>
        {% if section.settings.subheading != blank %}
          <p class="newsletter__subtitle">{{ section.settings.subheading | escape }}</p>
        {% endif %}
      </div>

      <form action="{{ routes.contact_post_url }}" method="post" class="newsletter__form" novalidate>
        <input type="hidden" name="form_type" value="customer">
        <input type="hidden" name="utf8" value="✓">
        <input type="hidden" name="contact[tags]" value="newsletter">

        <div class="newsletter__input-wrapper">
          <label for="newsletter-email" class="visually-hidden">{{ section.settings.placeholder | escape }}</label>
          <input type="email" id="newsletter-email" name="contact[email]" placeholder="{{ section.settings.placeholder | escape }}" 
class="newsletter__input" required autocomplete="email" aria-describedby="newsletter-status">
          <button type="submit" class="btn btn--primary newsletter__submit" aria-label="Subscribe">
            {{ section.settings.button_text | escape }}
          </button>
        </div>

        <p id="newsletter-status" class="newsletter__status visually-hidden" aria-live="polite"></p>
      </form>
    </div>
  </div>
</section>

{% schema %}
{
  "name": "Newsletter - Zero Credit",
  "tag": "section",
  "class": "newsletter-section",
  "settings": [
    {
      "type": "select",
      "id": "style",
      "label": "Style",
      "options": [
        { "value": "minimal", "label": "Minimal (white bg)" },
        { "value": "dark", "label": "Dark (black bg)" },
        { "value": "bordered", "label": "Bordered" }
      ],
      "default": "dark"
    },
    {
      "type": "text",
      "id": "heading",
      "label": "Heading",
      "default": "Join The Zero Credit Project"
    },
    {
      "type": "textarea",
      "id": "subheading",
      "label": "Subheading",
      "default": "Be the first to know about new collections and special offers."
    },
    {
      "type": "text",
      "id": "placeholder",
      "label": "Email placeholder",
      "default": "Email address"
    },
    {
      "type": "text",
      "id": "button_text",
      "label": "Button text",
      "default": "Subscribe"
    }
  ],
  "presets": [{ "name": "Newsletter - Zero Credit" }]
}
{% endschema %}
EOF

cat > sections/footer.liquid <<'EOF'
{% comment %}
Footer — brand line, navigation columns, newsletter, policies, contact, copyright.
Settings: menus, social links, contact info, show newsletter.
{% endcomment %}
<footer class="footer" role="contentinfo">
  <div class="container">
    <div class="footer__grid">
      {% comment %} Brand Column {% endcomment %}
      <div class="footer__brand">
        {% if section.settings.logo != blank %}
          <a href="{{ routes.root_url }}" class="footer__logo" aria-label="{{ shop.name }} — Home">
            {{ section.settings.logo | image_tag: width: 140, height: 40, alt: shop.name }}
          </a>
        {% else %}
          <a href="{{ routes.root_url }}" class="footer__logo-text">{{ shop.name }}</a>
        {% endif %}
        {% if section.settings.brand_line != blank %}
          <p class="footer__brand-line">{{ section.settings.brand_line | escape }}</p>
        {% endif %}

        {% if section.settings.show_social %}
          <div class="footer__social flex gap-4" role="list" aria-label="Social links">
            {% for block in section.blocks %}
              {% if block.type == 'social' and block.settings.url != blank %}
                <a href="{{ block.settings.url }}" class="footer__social-link" role="listitem" aria-label="{{ block.settings.platform }}" 
target="_blank" rel="noopener">
                  {% render block.settings.icon %}
                </a>
              {% endif %}
            {% endfor %}
          </div>
        {% endif %}
      </div>

      {% comment %} Navigation Columns {% endcomment %}
      <div class="footer__nav-cols flex flex-wrap gap-12">
        {% for block in section.blocks %}
          {% if block.type == 'menu' and block.settings.menu != blank %}
            <nav class="footer__nav-col" aria-labelledby="footer-nav-{{ forloop.index }}">
              <h3 id="footer-nav-{{ forloop.index }}" class="footer__nav-title">{{ block.settings.menu.title }}</h3>
              <ul class="list-unstyled">
                {% for link in block.settings.menu.links %}
                  <li><a href="{{ link.url }}" class="footer__nav-link">{{ link.title }}</a></li>
                {% endfor %}
              </ul>
            </nav>
          {% endif %}
        {% endfor %}
      </div>

      {% comment %} Contact / Newsletter Column {% endcomment %}
      <div class="footer__contact">
        {% if section.settings.show_newsletter %}
          <h3 class="footer__contact-title">Stay in the loop</h3>
          <form action="{{ routes.contact_post_url }}" method="post" class="footer__newsletter-form" novalidate>
            <input type="hidden" name="form_type" value="customer">
            <input type="hidden" name="utf8" value="✓">
            <input type="hidden" name="contact[tags]" value="newsletter,footer">
            <div class="footer__input-wrapper">
              <label for="footer-email" class="visually-hidden">Email address</label>
              <input type="email" id="footer-email" name="contact[email]" placeholder="Email address" class="footer__input" required 
autocomplete="email">
              <button type="submit" class="btn btn--text" aria-label="Subscribe">{% render 'icon-chevron-right' %}</button>
            </div>
          </form>
        {% endif %}

        {% if section.settings.show_contact %}
          <address class="footer__address" style="margin-top: var(--space-8);">
            <p class="footer__address-line"><strong>{{ shop.name }}</strong></p>
            <p class="footer__address-line">India</p>
            <p class="footer__address-line"><a href="mailto:{{ section.settings.email | default: 'thezerocreditproject@gmail.com' }}" 
class="footer__address-link">{{ section.settings.email | default: 'thezerocreditproject@gmail.com' }}</a></p>
            <p class="footer__address-line"><a href="tel:{{ section.settings.phone | default: '+91 9411323055' }}" 
class="footer__address-link">{{ section.settings.phone | default: '+91 9411323055' }}</a></p>
            <p class="footer__address-line">Thursday – Sunday, 10:00 AM – 6:00 PM IST</p>
          </address>
        {% endif %}
      </div>
    </div>

    <div class="footer__bottom">
      <p class="footer__copyright">© {{ 'now' | date: '%Y' }} {{ shop.name }}. All rights reserved.</p>
      <nav class="footer__policies" aria-label="Legal policies">
        <ul class="list-unstyled flex flex-wrap gap-6">
          {% if policies.privacy_policy %}<li><a href="{{ policies.privacy_policy.url }}" class="footer__policy-link">Privacy 
Policy</a></li>{% endif %}
          {% if policies.refund_policy %}<li><a href="{{ policies.refund_policy.url }}" class="footer__policy-link">Refund Policy</a></li>{% 
endif %}
          {% if policies.shipping_policy %}<li><a href="{{ policies.shipping_policy.url }}" class="footer__policy-link">Shipping 
Policy</a></li>{% endif %}
          {% if policies.terms_of_service %}<li><a href="{{ policies.terms_of_service.url }}" class="footer__policy-link">Terms of 
Service</a></li>{% endif %}
          <li><a href="{{ routes.contact_url }}" class="footer__policy-link">Contact</a></li>
        </ul>
      </nav>
    </div>
  </div>
</footer>

{% schema %}
{
  "name": "Footer",
  "tag": "footer",
  "class": "footer-section",
  "settings": [
    {
      "type": "image_picker",
      "id": "logo",
      "label": "Logo image"
    },
    {
      "type": "textarea",
      "id": "brand_line",
      "label": "Brand line",
      "default": "Essentials for the self-made."
    },
    {
      "type": "checkbox",
      "id": "show_social",
      "label": "Show social links",
      "default": true
    },
    {
      "type": "checkbox",
      "id": "show_newsletter",
      "label": "Show newsletter in footer",
      "default": true
    },
    {
      "type": "checkbox",
      "id": "show_contact",
      "label": "Show contact info",
      "default": true
    },
    {
      "type": "email",
      "id": "email",
      "label": "Contact email",
      "default": "thezerocreditproject@gmail.com"
    },
    {
      "type": "text",
      "id": "phone",
      "label": "Contact phone",
      "default": "+91 9411323055"
    }
  ],
  "blocks": [
    {
      "type": "menu",
      "name": "Navigation Menu",
      "settings": [
        { "type": "link_list", "id": "menu", "label": "Menu", "default": "footer-menu" }
      ]
    },
    {
      "type": "social",
      "name": "Social Link",
      "settings": [
        { "type": "select", "id": "platform", "label": "Platform", "options": 
[{"value":"instagram","label":"Instagram"},{"value":"twitter","label":"X 
(Twitter)"},{"value":"youtube","label":"YouTube"},{"value":"tiktok","label":"TikTok"}] },
        { "type": "url", "id": "url", "label": "Profile URL" },
        { "type": "select", "id": "icon", "label": "Icon snippet", "options": 
[{"value":"icon-instagram","label":"Instagram"},{"value":"icon-twitter","label":"X"},{"value":"icon-youtube","label":"YouTube"},{"value":"icon-[{"value":"icon-instagram","label":"Instagram"},{"value":"icon-twtter","label":"X"},{"value":"icon-youtube","label":"YouTube"},{"value":"icon-tiktok","label":"TikTok"}] }
      ]
    }
  ],
  "presets": [{ "name": "Footer", "blocks": [{ "type": "menu" }, { "type": "menu" }] }]
}
{% endschema %}
EOF

cat > sections/main-product.liquid <<'EOF'
{% comment %}
Product Page — gallery, form, accordions, sticky ATB on mobile.
Settings: gallery layout, enable sticky ATB, show dynamic checkout.
{% endcomment %}
{% assign product = section.product %}
{% assign current_variant = product.selected_or_first_available_variant %}

<section class="product-page" data-product-page data-product-id="{{ product.id }}" itemscope itemtype="https://schema.org/Product">
  <div class="container">
    <div class="product-page__grid">
      {% comment %} Gallery {% endcomment %}
      <div class="product-page__gallery reveal" id="product-gallery">
        <div class="product-gallery__main" role="region" aria-label="Product images">
          {% for media in product.media %}
            <div class="product-gallery__slide {% if forloop.first %}is-active{% endif %}" data-media-id="{{ media.id }}">
              {{ media | media_tag: image_size: '1024x', class: 'product-gallery__image', loading: forloop.first ? 'eager' : 'lazy', alt: 
media.alt | default: product.title | escape }}
            </div>
          {% endfor %}
        </div>
        {% if product.media.size > 1 %}
          <div class="product-gallery__thumbs flex gap-3 mt-4" role="tablist" aria-label="Product thumbnails">
            {% for media in product.media %}
              <button class="product-gallery__thumb {% if forloop.first %}is-active{% endif %}" role="tab" aria-selected="{{ forloop.first }}" 
aria-controls="panel-{{ media.id }}" data-thumb-target="{{ media.id }}">
                {{ media | media_tag: image_size: '150x', class: 'product-gallery__thumb-image', alt: '' }}
              </button>
            {% endfor %}
          </div>
        {% endif %}
      </div>

      {% comment %} Info & Form {% endcomment %}
      <div class="product-page__info reveal">
        <p class="product-page__category">{{ product.type | escape }}</p>
        <h1 class="product-page__title" itemprop="name">{{ product.title | escape }}</h1>

        <div class="product-page__price" itemprop="offers" itemscope itemtype="https://schema.org/Offer">
          <span class="price price--regular" id="price-{{ product.id }}">
            <span class="visually-hidden">{{ 'products.product.regular_price' | t }}</span>
            {{ current_variant.price | money }}
          </span>
          {% if current_variant.compare_at_price > current_variant.price %}
            <span class="price price--compare" aria-hidden="true">{{ current_variant.compare_at_price | money }}</span>
          {% endif %}
          <meta itemprop="price" content="{{ current_variant.price | divided_by: 100.0 }}">
          <meta itemprop="priceCurrency" content="{{ cart.currency.iso_code }}">
          <link itemprop="availability" href="https://schema.org/{% if current_variant.available %}InStock{% else %}OutOfStock{% endif %}">
        </div>

        {% if section.settings.show_mto_note %}
          <p class="product-page__mto">Made to order. Ships in 1–5 business days.</p>
        {% endif %}

        {% comment %} Variant Selectors {% endcomment %}
        <form class="product-form" id="product-form-{{ product.id }}" action="{{ routes.cart_add_url }}" method="post" novalidate>
          <input type="hidden" name="id" value="{{ current_variant.id }}" data-product-form-id>
          <input type="hidden" name="quantity" value="1" data-quantity-input>

          {% for option in product.options_with_values %}
            <fieldset class="product-form__field" aria-labelledby="option-label-{{ option.name | handleize }}">
              <legend id="option-label-{{ option.name | handleize }}" class="product-form__label">{{ option.name }}</legend>
              <div class="product-form__values flex flex-wrap gap-3" role="radiogroup" aria-label="{{ option.name }}">
                {% for value in option.values %}
                  {% assign variant_for_value = product.variants | where: option.name, value | first %}
                  <input type="radio" name="{{ option.name }}" value="{{ value | escape }}" id="{{ option.name | handleize }}-{{ value | 
handleize }}" class="product-form__input visually-hidden" {% if forloop.first %}checked{% endif %} {% unless variant_for_value.available 
%}disabled{% endunless %}>
                  <label for="{{ option.name | handleize }}-{{ value | handleize }}" class="product-form__option {% unless 
variant_for_value.available %}product-form__option--disabled{% endunless %}" aria-disabled="{{ variant_for_value.available | not }}">
                    {{ value }}
                  </label>
                {% endfor %}
              </div>
            </fieldset>
          {% endfor %}

          {% comment %} Quantity {% endcomment %}
          <div class="product-form__quantity" style="max-width: 120px;">
            <label for="quantity-{{ product.id }}" class="product-form__label">Quantity</label>
            <div class="quantity-selector flex items-center border" role="group" aria-label="Quantity">
              <button type="button" class="quantity-selector__btn" data-quantity-decrement aria-label="Decrease quantity">{% render 
'icon-minus' %}</button>
              <input type="number" id="quantity-{{ product.id }}" name="quantity" value="1" min="1" max="99" class="quantity-selector__input" 
data-quantity-input aria-label="Quantity">
              <button type="button" class="quantity-selector__btn" data-quantity-increment aria-label="Increase quantity">{% render 
'icon-plus' %}</button>
            </div>
          </div>

          {% comment %} Add to Cart / Dynamic Checkout {% endcomment %}
          <div class="product-form__actions flex flex-wrap gap-3 mt-6">
            <button type="submit" name="add" class="btn btn--primary flex-1" {% unless current_variant.available %}disabled{% endunless %} 
data-add-to-cart>
              <span class="btn__text">{{ 'products.product.add_to_cart' | t }}</span>
              <span class="btn__loader visually-hidden" aria-hidden="true">{% render 'icon-spinner' %}</span>
            </button>
            {% if section.settings.show_dynamic_checkout and current_variant.available %}
              {{ form | payment_button }}
            {% endif %}
          </div>
        </form>

        {% comment %} Accordions {% endcomment %}
        <div class="product-page__accordions mt-10" data-accordions>
          {% render 'product-accordion', title: 'Product Details', content: section.settings.details_content, open: true %}
          {% render 'product-accordion', title: 'Shipping', content: section.settings.shipping_content %}
          {% render 'product-accordion', title: 'Returns & Exchanges', content: section.settings.returns_content %}
          {% render 'product-accordion', title: 'Size Guide', content: section.settings.size_guide_content %}
        </div>
      </div>
    </div>

    {% comment %} Sticky Mobile ATB {% endcomment %}
    {% if section.settings.sticky_atb_mobile %}
      <div class="product-page__sticky-atb" hidden data-sticky-atb>
        <div class="product-page__sticky-price">{{ current_variant.price | money }}</div>
        <button class="btn btn--primary w-100" data-sticky-atb-btn {% unless current_variant.available %}disabled{% endunless %}>
          {{ 'products.product.add_to_cart' | t }}
        </button>
      </div>
    {% endif %}
  </div>
</section>

{% comment %} Recommended Products (placeholder) {% endcomment %}
{% if section.settings.show_recommendations and collections[section.settings.recommendations_collection] != blank %}
  {% render 'featured-products', collection: collections[section.settings.recommendations_collection], title: 'You may also like', limit: 4 %}
{% endif %}

{% schema %}
{
  "name": "Product Page",
  "tag": "section",
  "class": "product-page-section",
  "settings": [
    {
      "type": "select",
      "id": "gallery_layout",
      "label": "Gallery layout",
      "options": [{"value":"stacked","label":"Stacked (mobile) / Thumbnails (desktop)"},{"value":"slider","label":"Slider"}],
      "default": "stacked"
    },
    {
      "type": "checkbox",
      "id": "show_mto_note",
      "label": "Show 'Made to order' note",
      "default": true
    },
    {
      "type": "checkbox",
      "id": "show_dynamic_checkout",
      "label": "Show dynamic checkout button",
      "default": true
    },
    {
      "type": "checkbox",
      "id": "sticky_atb_mobile",
      "label": "Sticky Add to Cart on mobile",
      "default": true
    },
    {
      "type": "richtext",
      "id": "details_content",
      "label": "Product Details content",
      "default": "<p>Each piece is made to order in small batches. Expect minor variations — they're not defects, they're 
character.</p><ul><li>Heavyweight 280–320 GSM cotton</li><li>Pre-shrunk, garment-dyed</li><li>Screen printed with water-based inks</li></ul>"
    },
    {
      "type": "richtext",
      "id": "shipping_content",
      "label": "Shipping content",
      "default": "<p>Processing: 1–5 business days. India delivery: 4–10 business days. Tracking sent via email.</p>"
    },
    {
      "type": "richtext",
      "id": "returns_content",
      "label": "Returns content",
      "default": "<p>Made to order — no returns for change of mind. Eligible only if damaged, defective, or wrong item delivered. Contact 
within 7 days with photos.</p>"
    },
    {
      "type": "richtext",
      "id": "size_guide_content",
      "label": "Size Guide content",
      "default": "<p>Measure a tee you love. Chest: measure under arms across fullest part. Length: from high point shoulder to 
hem.</p><table><thead><tr><th>Size</th><th>Chest (cm)</th><th>Length 
(cm)</th></tr></thead><tbody><tr><td>S</td><td>52</td><td>70</td></tr><tr><td>M</td><td>55</td><td>72</td></tr><tr><td>L</td><td>58</td><td>74<(cm)</th></tr></thead><tbody><tr><td>S</td><td>52</td><td>70</td></tr><tr>td>M</td><td>55</td><td>72</td></tr><tr><td>L</td><td>58</td><td>74</td></tr><tr><td>XL</td><td>61</td><td>76</td></tr></tbody></table>"
    },
    {
      "type": "checkbox",
      "id": "show_recommendations",
      "label": "Show recommended products",
      "default": true
    },
    {
      "type": "collection",
      "id": "recommendations_collection",
      "label": "Recommendations collection"
    }
  ],
  "presets": [{ "name": "Product Page" }]
}
{% endschema %}
EOF

cat > sections/main-collection-product-grid.liquid <<'EOF'
{% comment %}
Collection Page — product grid with sidebar filters (desktop) / drawer (mobile).
Uses product-card snippet. Handles sort, pagination/infinite scroll.
{% endcomment %}
<section class="collection-page" data-collection-page>
  <div class="container">
    <div class="collection-page__layout">
      {% comment %} Sidebar Filters {% endcomment %}
      <aside class="collection-page__sidebar" id="collection-filters" aria-label="Filters">
        <div class="filter-drawer__header flex items-center justify-between">
          <h2 class="filter-drawer__title">Filters</h2>
          <button class="filter-drawer__close btn btn--text" data-filter-drawer-close aria-label="Close filters">{% render 'icon-close' 
%}</button>
        </div>
        <form class="filter-form" id="filter-form" action="{{ collection.url }}">
          {% render 'collection-filters', collection: collection %}
          <button type="submit" class="btn btn--primary w-100 mt-6">Apply</button>
          <button type="button" class="btn btn--outline w-100 mt-3" data-filters-clear>Clear all</button>
        </form>
      </aside>

      <div class="collection-page__main">
        {% comment %} Header + Sort + Mobile Filter Trigger {% endcomment %}
        <header class="collection-page__header flex flex-wrap items-center justify-between gap-4 mb-8">
          <div>
            <h1 class="collection-page__title">{{ collection.title }}</h1>
            {% if collection.description != blank %}
              <div class="collection-page__description rte">{{ collection.description }}</div>
            {% endif %}
          </div>
          <div class="collection-page__toolbar flex items-center gap-4">
            <button class="btn btn--outline collection-page__filter-btn" data-filter-drawer-open aria-expanded="false" 
aria-controls="collection-filters">
              {% render 'icon-filter' %} Filters
            </button>
            <div class="collection-page__sort">
              <label for="sort-by" class="visually-hidden">Sort by</label>
              <select id="sort-by" class="select" name="sort_by" aria-label="Sort products">
                {% for option in collection.sort_options %}
                  <option value="{{ option.value }}" {% if option.selected %}selected{% endif %}>{{ option.name }}</option>
                {% endfor %}
              </select>
            </div>
          </div>
        </header>

        {% comment %} Product Grid {% endcomment %}
        <div class="product-grid product-grid--{{ section.settings.products_per_row }}cols" role="list" id="product-grid">
          {% for product in collection.products %}
            {% render 'product-card', product: product, show_vendor: false, show_badges: true, quick_add: section.settings.enable_quick_add %}
          {% else %}
            <p class="product-grid__empty">{{ 'collections.general.no_matches' | t }}</p>
          {% endfor %}
        </div>

        {% comment %} Pagination / Load More {% endcomment %}
        {% if paginate.pages > 1 %}
          <div class="collection-page__pagination flex justify-center gap-3 mt-10">
            {% if paginate.previous %}
              <a href="{{ paginate.previous.url }}" class="btn btn--outline" rel="prev">Previous</a>
            {% endif %}
            <span class="pagination__info self-center" aria-current="page">Page {{ paginate.current_page }} of {{ paginate.pages }}</span>
            {% if paginate.next %}
              <a href="{{ paginate.next.url }}" class="btn btn--outline" rel="next">Next</a>
            {% endif %}
          </div>
        {% endif %}
      </div>
    </div>
  </div>
</section>

{% comment %} Mobile Filter Drawer Overlay {% endcomment %}
<div class="filter-drawer-overlay" id="filter-drawer-overlay" hidden data-filter-drawer-overlay></div>

{% schema %}
{
  "name": "Collection Product Grid",
  "tag": "section",
  "class": "collection-grid-section",
  "settings": [
    {
      "type": "select",
      "id": "products_per_row",
      "label": "Products per row (desktop)",
      "options": [
        { "value": "3", "label": "3" },
        { "value": "4", "label": "4" },
        { "value": "5", "label": "5" }
      ],
      "default": "4"
    },
    {
      "type": "checkbox",
      "id": "enable_quick_add",
      "label": "Enable Quick Add",
      "default": true
    },
    {
      "type": "checkbox",
      "id": "enable_infinite_scroll",
      "label": "Enable infinite scroll (requires JS)",
      "default": false
    }
  ],
  "presets": [{ "name": "Collection Product Grid" }]
}
{% endschema %}
EOF

cat > sections/main-page.liquid <<'EOF'
{% comment %}
Generic Page Section — used for Contact, Policy pages. Renders page.content with styled typography.
{% endcomment %}
<section class="page-content" data-page-content>
  <div class="container container--narrow">
    <header class="page-content__header reveal">
      <h1 class="page-content__title">{{ page.title }}</h1>
    </header>
    <div class="page-content__body rte reveal">
      {{ page.content }}
    </div>
  </div>
</section>

{% schema %}
{
  "name": "Page Content",
  "tag": "section",
  "class": "page-section",
  "settings": [],
  "presets": [{ "name": "Page Content" }]
}
{% endschema %}
EOF

cat > sections/contact-page.liquid <<'EOF'
{% comment %}
Contact Page Section — branded contact form + info.
{% endcomment %}
<section class="page-content contact-page" data-page-content>
  <div class="container container--narrow">
    <header class="page-content__header reveal">
      <h1 class="page-content__title">{{ page.title }}</h1>
    </header>

    <div class="contact-page__grid">
      <div class="contact-page__info reveal">
        <div class="contact-page__body rte">
          {{ page.content }}
        </div>
        <address class="contact-page__address">
          <p><strong>{{ shop.name }}</strong></p>
          <p>India</p>
          <p><a href="mailto:{{ shop.email }}">{{ shop.email }}</a></p>
          <p><a href="tel:+919411323055">+91 9411323055</a></p>
          <p>Thursday – Sunday, 10:00 AM – 6:00 PM IST</p>
          <p style="margin-top: 1rem;"><strong>Customer Support:</strong> <a 
href="mailto:thezerocreditproject@gmail.com">thezerocreditproject@gmail.com</a></p>
          <p>We aim to respond to all inquiries within 24–72 business hours.</p>
        </address>
      </div>

      <div class="contact-page__form reveal">
        {% form 'contact', id: 'contact-form', class: 'contact-form' %}
          {% if form.posted_successfully? %}
            <p class="form-status form-status--success" role="status">Thanks for reaching out. We'll get back to you soon.</p>
          {% elsif form.errors %}
            <p class="form-status form-status--error" role="alert">Please fix the errors below.</p>
          {% endif %}

          <div class="form-field">
            <label for="contact-name" class="form-label">Name</label>
            <input type="text" id="contact-name" name="contact[name]" class="form-input" required autocomplete="name">
          </div>

          <div class="form-field">
            <label for="contact-email" class="form-label">Email</label>
            <input type="email" id="contact-email" name="contact[email]" class="form-input" required autocomplete="email">
          </div>

          <div class="form-field">
            <label for="contact-phone" class="form-label">Phone (optional)</label>
            <input type="tel" id="contact-phone" name="contact[phone]" class="form-input" autocomplete="tel">
          </div>

          <div class="form-field">
            <label for="contact-body" class="form-label">Message</label>
            <textarea id="contact-body" name="contact[body]" class="form-textarea" rows="5" required></textarea>
          </div>

          <button type="submit" class="btn btn--primary w-100">Send Message</button>
        {% endform %}
      </div>
    </div>
  </div>
</section>

{% schema %}
{
  "name": "Contact Page",
  "tag": "section",
  "class": "contact-page-section",
  "settings": [],
  "presets": [{ "name": "Contact Page" }]
}
{% endschema %}
EOF

cat > sections/policy-page.liquid <<'EOF'
{% comment %}
Policy Page Section — branded policy content with structured sections.
{% endcomment %}
<section class="page-content policy-page" data-page-content>
  <div class="container container--narrow">
    <header class="page-content__header reveal">
      <h1 class="page-content__title">{{ page.title }}</h1>
      <p class="policy-page__updated">Last updated: June 2026</p>
      <p class="policy-page__disclaimer"><em>This policy is a template. Please review with legal counsel before publishing.</em></p>
    </header>

    <div class="policy-page__body rte reveal">
      {{ page.content }}
    </div>

    <div class="policy-page__contact reveal">
      <h3>Contact Us</h3>
      <address>
        <p><strong>The Zero Credit Project</strong></p>
        <p>Email: <a href="mailto:thezerocreditproject@gmail.com">thezerocreditproject@gmail.com</a></p>
        <p>Phone: <a href="tel:+919411323055">+91 9411323055</a></p>
        <p>India</p>
      </address>
    </div>
  </div>
</section>

{% schema %}
{
  "name": "Policy Page",
  "tag": "section",
  "class": "policy-page-section",
  "settings": [],
  "presets": [{ "name": "Policy Page" }]
}
{% endschema %}
EOF

# ============================================================
# SNIPPETS
# ============================================================

cat > snippets/product-card.liquid <<'EOF'
{% comment %}
Product Card — used everywhere. Handles image swap, badges, quick add, price, color swatches.
Context variables: product, show_vendor, show_badges, quick_add.
{% endcomment %}
{% liquid
  assign card_product = product
  assign show_vendor = show_vendor | default: false
  assign show_badges = show_badges | default: true
  assign enable_quick_add = quick_add | default: true
  assign first_media = card_product.featured_media
  assign first_variant = card_product.selected_or_first_available_variant
%}

<article class="product-card reveal" itemscope itemtype="https://schema.org/Product" data-product-id="{{ card_product.id }}" role="listitem">
  <div class="product-card__media-wrapper">
    <a href="{{ card_product.url }}" class="product-card__link" aria-label="{{ card_product.title | escape }}">
      {% if first_media %}
        {{ first_media | media_tag: image_size: '530x', class: 'product-card__image product-card__image--primary', loading: 'lazy', alt: 
first_media.alt | default: card_product.title | escape, width: 530, height: 530 }}
      {% endif %}
      {% if card_product.media.size > 1 %}
        {% assign second_media = card_product.media[1] %}
        {{ second_media | media_tag: image_size: '530x', class: 'product-card__image product-card__image--secondary', loading: 'lazy', alt: 
second_media.alt | default: card_product.title | escape, width: 530, height: 530 }}
      {% endif %}
    </a>

    {% if show_badges %}
      <div class="product-card__badges flex flex-col gap-2">
        {% if card_product.tags contains 'made-to-order' %}
          <span class="badge badge--mto">Made to order</span>
        {% endif %}
        {% if card_product.tags contains 'new' %}
          <span class="badge badge--new">New</span>
        {% endif %}
        {% unless first_variant.available %}
          <span class="badge badge--sold">Sold out</span>
        {% endunless %}
      </div>
    {% endif %}

    {% if enable_quick_add and first_variant.available %}
      <form class="product-card__quick-add" action="{{ routes.cart_add_url }}" method="post" data-quick-add>
        <input type="hidden" name="id" value="{{ first_variant.id }}">
        <input type="hidden" name="quantity" value="1">
        <input type="hidden" name="sections" value="cart-drawer">
        <button type="submit" class="btn btn--primary btn--sm product-card__quick-add-btn" aria-label="Quick add {{ card_product.title | 
escape }} to cart">
          <span class="btn__text">Quick add</span>
          <span class="btn__loader visually-hidden" aria-hidden="true">{% render 'icon-spinner' %}</span>
        </button>
      </form>
    {% endif %}
  </div>

  <div class="product-card__info">
    {% if show_vendor and card_product.vendor != blank %}
      <p class="product-card__vendor">{{ card_product.vendor | escape }}</p>
    {% endif %}
    <h3 class="product-card__title">
      <a href="{{ card_product.url }}" itemprop="url">{{ card_product.title | escape }}</a>
    </h3>

    <div class="product-card__price" itemprop="offers" itemscope itemtype="https://schema.org/Offer">
      <span class="price price--regular" itemprop="price" content="{{ first_variant.price | divided_by: 100.0 }}">
        {{ first_variant.price | money }}
      </span>
      {% if first_variant.compare_at_price > first_variant.price %}
        <span class="price price--compare" aria-hidden="true">{{ first_variant.compare_at_price | money }}</span>
      {% endif %}
      <meta itemprop="priceCurrency" content="{{ cart.currency.iso_code }}">
      <link itemprop="availability" href="https://schema.org/{% if first_variant.available %}InStock{% else %}OutOfStock{% endif %}">
    </div>

    {% comment %} Color Swatches (first 4 option values for 'Color'/'Colour') {% endcomment %}
    {% assign color_option = card_product.options_with_values | where: 'name', 'Color' | first | default: card_product.options_with_values | 
where: 'name', 'Colour' | first %}
    {% if color_option and color_option.values.size > 1 %}
      <div class="product-card__swatches flex gap-2 mt-3" role="group" aria-label="Color options">
        {% for value in color_option.values limit: 4 %}
          {% assign swatch_handle = value | handleize %}
          <button type="button" class="product-card__swatch" aria-label="{{ value }}" style="--swatch-bg: {{ swatch_handle }};" 
data-swatch-value="{{ value | escape }}"></button>
        {% endfor %}
        {% if color_option.values.size > 4 %}
          <span class="product-card__swatch-more">+{{ color_option.values.size | minus: 4 }}</span>
        {% endif %}
      </div>
    {% endif %}
  </div>
</article>
EOF

cat > snippets/icon-search.liquid <<'EOF'
<svg class="icon icon-search" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" 
y2="16.65"></line></svg>
EOF

cat > snippets/icon-account.liquid <<'EOF'
<svg class="icon icon-account" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" 
cy="7" r="4"></circle></svg>
EOF

cat > snippets/icon-cart.liquid <<'EOF'
<svg class="icon icon-cart" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" 
r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>
EOF

cat > snippets/icon-menu.liquid <<'EOF'
<svg class="icon icon-menu" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" 
y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
EOF

cat > snippets/icon-close.liquid <<'EOF'
<svg class="icon icon-close" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" 
y2="18"></line></svg>
EOF

cat > snippets/icon-chevron-down.liquid <<'EOF'
<svg class="icon icon-chevron-down" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="6 9 12 15 18 9"></polyline></svg>
EOF

cat > snippets/icon-chevron-right.liquid <<'EOF'
<svg class="icon icon-chevron-right" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="9 18 15 12 9 6"></polyline></svg>
EOF

cat > snippets/icon-minus.liquid <<'EOF'
<svg class="icon icon-minus" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"></line></svg>
EOF

cat > snippets/icon-plus.liquid <<'EOF'
<svg class="icon icon-plus" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" 
y2="12"></line></svg>
EOF

cat > snippets/icon-spinner.liquid <<'EOF'
<svg class="icon icon-spinner animate-spin" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
EOF

cat > snippets/icon-filter.liquid <<'EOF'
<svg class="icon icon-filter" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 
3"></polygon></svg>
EOF

cat > snippets/icon-instagram.liquid <<'EOF'
<svg class="icon icon-instagram" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"></rect><path d="M16 
11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"></path><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"></line></svg>
EOF

cat > snippets/icon-twitter.liquid <<'EOF'
<svg class="icon icon-twitter" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M23 3a10.9 10.9 0 0 1-3.14 1.53 4.48 4.48 0 0 0-7.86 3v1A10.66 
10.66 0 0 1 3 4s-4 9 5 13a11.64 11.64 0 0 1-7 2c9 5 20 0 20-11.5a4.5 4.5 0 0 0-.08-.83A7.72 7.72 0 0 0 23 3z"></path></svg>
EOF

cat > snippets/icon-youtube.liquid <<'EOF'
<svg class="icon icon-youtube" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22.54 6.42a2.78 2.78 0 0 0-1.94-2C18.88 4 12 4 12 4s-6.88 
0-8.6.46a2.78 2.78 0 0 0-1.94 2A29 29 0 0 0 1 11.75a29 29 0 0 0 .46 5.33A2.78 2.78 0 0 0 3.4 19c1.72.46 8.6.46 8.6.46s6.88 0 8.6-.46a2.78 2.78 
0 0 0 1.94-2 29 29 0 0 0 .46-5.25 29 29 0 0 0-.46-5.33z"></path><polygon points="9.75 15.02 15.5 11.75 9.75 8.48 9.75 15.02"></polygon></svg>
EOF

cat > snippets/icon-tiktok.liquid <<'EOF'
<svg class="icon icon-tiktok" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 8.5c0 2.5-2 2.5-2 5s2 5 2 5M5 8.5c0 2.5 2 2.5 2 5s-2 5-2 5M19 
3h-2.5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2H19a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2z"></path></svg>
EOF

cat > snippets/cart-drawer.liquid <<'EOF'
{% comment %}
Cart Drawer — slide-out cart with items, quantity controls, checkout.
{% endcomment %}
<aside class="cart-drawer" id="cart-drawer" role="dialog" aria-label="Shopping cart" aria-hidden="true" data-cart-drawer>
  <div class="cart-drawer__overlay" data-cart-close></div>
  <div class="cart-drawer__panel">
    <header class="cart-drawer__header flex items-center justify-between">
      <h2 class="cart-drawer__title">Your Cart</h2>
      <button class="cart-drawer__close btn btn--text" aria-label="Close cart" data-cart-close>
        {% render 'icon-close' %}
      </button>
    </header>

    <div class="cart-drawer__items" id="cart-drawer-items" role="list" aria-label="Cart items">
      {% if cart.item_count == 0 %}
        <div class="cart-drawer__empty">
          <p>Your cart is empty.</p>
          <a href="{{ routes.all_products_collection_url }}" class="btn btn--outline mt-4">Continue Shopping</a>
        </div>
      {% else %}
        {% for item in cart.items %}
          <article class="cart-drawer__item flex gap-4" role="listitem" data-line-item="{{ forloop.index }}">
            <a href="{{ item.url }}" class="cart-drawer__item-image" aria-label="{{ item.title | escape }}">
              {{ item.featured_media | image_tag: width: 80, height: 80, class: 'cart-drawer__item-img', alt: item.featured_media.alt | 
default: item.title | escape }}
            </a>
            <div class="cart-drawer__item-details flex-1">
              <h3 class="cart-drawer__item-title">
                <a href="{{ item.url }}">{{ item.title | escape }}</a>
              </h3>
              {% if item.variant.title != 'Default Title' %}
                <p class="cart-drawer__item-variant">{{ item.variant.title | escape }}</p>
              {% endif %}
              <div class="cart-drawer__item-price">{{ item.final_price | money }}</div>

              <div class="cart-drawer__item-controls flex items-center gap-3 mt-3">
                <form action="{{ routes.cart_change_url }}" method="post" class="quantity-form flex items-center gap-2" data-quantity-form>
                  <input type="hidden" name="line" value="{{ forloop.index }}">
                  <button type="button" class="quantity-form__btn" data-qty-decrement aria-label="Decrease quantity">{% render 'icon-minus' 
%}</button>
                  <input type="number" name="quantity" value="{{ item.quantity }}" min="1" max="99" class="quantity-form__input" 
aria-label="Quantity" data-qty-input>
                  <button type="button" class="quantity-form__btn" data-qty-increment aria-label="Increase quantity">{% render 'icon-plus' 
%}</button>
                </form>

                <button type="button" class="cart-drawer__remove btn btn--text" data-line-remove="{{ forloop.index }}" aria-label="Remove {{ 
item.title | escape }}">
                  Remove
                </button>
              </div>
            </div>
          </article>
        {% endfor %}
      {% endif %}
    </div>

    {% if cart.item_count > 0 %}
      <div class="cart-drawer__footer">
        <p class="cart-drawer__note">Made to order — ships in 1–5 business days.</p>
        <div class="cart-drawer__subtotal flex justify-between">
          <span>Subtotal</span>
          <span class="cart-drawer__subtotal-value" id="cart-subtotal">{{ cart.total_price | money }}</span>
        </div>
        <button type="button" class="btn btn--primary w-100 cart-drawer__checkout" data-cart-checkout>
          Checkout
        </button>
        <button type="button" class="btn btn--outline w-100 mt-3" data-cart-close>
          Continue Shopping
        </button>
      </div>
    {% endif %}
  </div>
</aside>
EOF

cat > snippets/search-overlay.liquid <<'EOF'
{% comment %}
Search Overlay — full-screen search with predictive results.
{% endcomment %}
<div class="search-overlay" id="search-overlay" role="dialog" aria-label="Search" aria-hidden="true" hidden data-search-overlay>
  <div class="search-overlay__panel">
    <header class="search-overlay__header flex items-center justify-between">
      <h2 class="search-overlay__title">Search</h2>
      <button class="search-overlay__close btn btn--text" aria-label="Close search" data-search-close>
        {% render 'icon-close' %}
      </button>
    </header>

    <form action="{{ routes.search_url }}" method="get" class="search-overlay__form" role="search">
      <label for="search-input" class="visually-hidden">Search products</label>
      <div class="search-overlay__input-wrapper">
        {% render 'icon-search', class: 'search-overlay__icon' %}
        <input type="search" id="search-input" name="q" class="search-overlay__input" placeholder="Search products..." autocomplete="off" 
autocorrect="off" autocapitalize="off" spellcheck="false" aria-autocomplete="list" aria-controls="search-results">
      </div>
    </form>

    <div class="search-overlay__results" id="search-results" role="listbox" hidden></div>

    <div class="search-overlay__suggestions">
      <h3 class="search-overlay__suggestions-title">Popular searches</h3>
      <ul class="search-overlay__suggestions-list flex flex-wrap gap-2">
        {% for term in search.terms %}
          <li><a href="{{ routes.search_url }}?q={{ term | url_encode }}" class="search-overlay__suggestion">{{ term }}</a></li>
        {% endfor %}
      </ul>
    </div>
  </div>
</div>
EOF

cat > snippets/mobile-menu.liquid <<'EOF'
{% comment %}
Mobile Menu Drawer — slide-out navigation for mobile.
{% endcomment %}
<nav class="mobile-menu" id="mobile-menu" role="dialog" aria-label="Mobile menu" aria-hidden="true" hidden data-mobile-menu>
  <div class="mobile-menu__overlay" data-mobile-menu-close></div>
  <div class="mobile-menu__panel">
    <header class="mobile-menu__header flex items-center justify-between">
      <span class="mobile-menu__title">Menu</span>
      <button class="mobile-menu__close btn btn--text" aria-label="Close menu" data-mobile-menu-close>
        {% render 'icon-close' %}
      </button>
    </header>

    <ul class="mobile-menu__list list-unstyled" role="list">
      {% for link in linklists.main-menu.links %}
        <li>
          <a href="{{ link.url }}" class="mobile-menu__link {% if link.active %}mobile-menu__link--active{% endif %}">{{ link.title }}</a>
