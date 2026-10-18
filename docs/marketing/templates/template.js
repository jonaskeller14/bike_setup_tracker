// Shared by the marketing templates in this folder, the App Store creative templates
// (docs/store/app-store/creative/) and the Play feature graphic. Load it at the end of <body>.
//
// URL parameters it handles:
//   size=1080x1080    page size for templates with several formats (CSS keys on body[data-size]);
//                     default: the body's data-size. Headless Chrome's viewport is shorter than its
//                     window, so templates never read innerWidth/innerHeight.
//   <name>=…          fills every [data-param="<name>"]; *words* become the teal key phrase, {9} a
//                     changed value, a line break a <br>. A missing parameter falls back to the
//                     element's data-default; an element left empty is hidden.
//   kind=…            removes every [data-kind] element that doesn't list this kind (default: the
//                     body's data-kind); a [data-param] may carry data-default-<kind>
//   lang=de           <html lang>, and [data-i18n] from the page's STRINGS[lang] (default en)
//   device=android    Android frame and Play raws instead of the iPhone (default: the body's
//                     data-device, else iphone)
//   shots=04,03       raws for the .phone[data-shot="N"] elements; an entry with a "/" is a repo path
//   bg=<repo path>    background image slot behind everything
//   dark              the .dark variant (thumbnails only)
//   zoom=x,y,w,h      still callouts on the .phone[data-callout] (else the first phone), in raw
//   lift=x,y,w,h      screen pixels; brand.md, Callouts
//   safe=x,y,w,h      draws the safe area; avoid=…;… (areas a platform covers) and guides=…;…
//                     (reference boxes) as well. With check, text outside safe or inside avoid
//                     is reported
//   check             writes problems to <body data-problems> (render_images.py reads it)
//   video             hides the .phone[data-video] and writes its position to <body data-layout>
//                     for tool/marketing/render_video.py
// [data-fit="<min px>"] shrinks an element's font size until its text fits its box.
// [data-decor] marks text that may sit outside the safe area (a brand row a platform may cover).
// When everything is laid out, <body data-ready> is set.
const LIFT_SCALE = 1.6;

(async () => {
  const params = new URLSearchParams(location.search);
  const root = new URL('../../../', document.currentScript.src);
  const repo = (path) => new URL(path, root).href;
  const escape = (text) => text.replace(/[&<>"]/g, (c) => `&#${c.charCodeAt(0)};`);
  const markup = (text) => escape(text)
    .replace(/\*([^*]+)\*/g, '<em>$1</em>')
    .replace(/\{([^}]+)\}/g, '<span class="new">$1</span>')
    .replace(/\n/g, '<br>');
  const rect = (value) => value.split(',').map(Number);
  const problems = [];

  const size = params.get('size') || document.body.dataset.size;
  const [width, height] = size ? size.split('x').map(Number) : [0, 0];
  if (width) {
    document.body.dataset.size = `${width}x${height}`;
    for (const el of [document.documentElement, document.body]) {
      Object.assign(el.style, { width: `${width}px`, height: `${height}px` });
    }
  }

  const lang = params.get('lang') === 'de' ? 'de' : 'en';
  document.documentElement.lang = lang;
  if (typeof STRINGS !== 'undefined') {
    document.querySelectorAll('[data-i18n]').forEach((el) => {
      el.innerHTML = STRINGS[lang][el.dataset.i18n];
    });
  }
  const kind = params.get('kind') || document.body.dataset.kind;
  if (kind) {
    document.body.dataset.kind = kind;
    document.querySelectorAll('[data-kind]:not(body)').forEach((el) => {
      if (!el.dataset.kind.split(' ').includes(kind)) el.remove();
    });
  }
  const kindDefault = kind && `default${kind[0].toUpperCase()}${kind.slice(1)}`;
  document.querySelectorAll('[data-param]').forEach((el) => {
    const value = params.get(el.dataset.param) ?? el.dataset[kindDefault] ?? el.dataset.default;
    if (value) el.innerHTML = markup(value);
    else el.hidden = true;
  });
  // [data-if="a b"]: hidden unless one of the parameters a, b is set.
  document.querySelectorAll('[data-if]').forEach((el) => {
    if (!el.dataset.if.split(' ').some((name) => params.get(name))) el.hidden = true;
  });
  if (params.has('dark')) document.body.classList.add('dark');
  if (params.has('video')) document.body.classList.add('mode-video');
  if (params.get('bg')) {
    const bg = document.createElement('img');
    bg.className = 'bg';
    bg.src = repo(params.get('bg'));
    document.body.prepend(bg);
  }

  const device = (params.get('device') || document.body.dataset.device) === 'android' ? 'android' : 'iphone';
  document.body.dataset.device = device;
  const { shotDir, frame } = {
    iphone: { shotDir: 'docs/store/app-store/iPhone-17-Pro-Max/', frame: 'docs/store/app-store/iPhone-17-Pro-Max/frame.png' },
    android: { shotDir: 'docs/store/play-store/phone/', frame: 'tool/marketing/assets/frames/android.png' },
  }[device];
  const shots = (params.get('shots') || '').split(',').filter(Boolean);
  document.querySelectorAll('.phone').forEach((phone) => {
    const shot = shots[Number(phone.dataset.shot || 0)] || shots[0] || phone.dataset.default || '04';
    const src = shot.includes('/') ? repo(shot) : repo(`${shotDir}${shot}_raw.png`);
    phone.innerHTML = `<div class="screen"><img src="${src}" alt=""></div><img class="frame" src="${repo(frame)}" alt="">`;
  });

  await new Promise((resolve) => (document.readyState === 'complete' ? resolve() : addEventListener('load', resolve)));
  await document.fonts.ready;

  document.querySelectorAll('[data-fit]').forEach((el) => {
    const min = Number(el.dataset.fit);
    let size = parseFloat(getComputedStyle(el).fontSize);
    const overflows = () => el.scrollHeight > el.clientHeight + 1 || el.scrollWidth > el.clientWidth + 1;
    while (overflows() && size > min) {
      size = Math.max(min, size * .96);
      el.style.fontSize = `${size}px`;
    }
    if (overflows() && !el.hidden) problems.push(`"${el.textContent.trim().slice(0, 40)}" doesn't fit at ${min} px`);
  });

  const target = document.querySelector('.phone[data-callout]') || document.querySelector('.phone');
  if (target && (params.get('zoom') || params.get('lift'))) {
    const screen = target.querySelector('.screen');
    const img = screen.querySelector('img');
    const [sw, sh] = [screen.offsetWidth, screen.offsetHeight];
    if (params.get('zoom')) {
      const [x, y, w, h] = rect(params.get('zoom'));
      const z = Math.max(1, .9 * Math.min(sw / w, sh / h));
      const clamp = (v, low) => Math.min(0, Math.max(low, v));
      const tx = clamp(sw / 2 - (x + w / 2) * z, sw - sw * z);
      const ty = clamp(sh / 2 - (y + h / 2) * z, sh - sh * z);
      img.style.transform = `translate(${tx}px, ${ty}px) scale(${z})`;
    }
    if (params.get('lift')) {
      const [x, y, w, h] = rect(params.get('lift'));
      const box = screen.getBoundingClientRect();
      // Centered on the element, kept inside the safe area (or a 24 px margin); a wide element
      // grows less, so it still fits.
      const [ax, ay, aw, ah] = params.get('safe')
        ? rect(params.get('safe').split(';')[0]) : [24, 24, document.body.offsetWidth - 48, document.body.offsetHeight - 48];
      const k = box.width / sw * Math.min(LIFT_SCALE, aw / (w * box.width / sw), ah / (h * box.width / sw));
      const lift = document.createElement('div');
      lift.className = 'lift';
      lift.innerHTML = `<img src="${img.src}" alt="">`;
      Object.assign(lift.style, { width: `${w * k}px`, height: `${h * k}px` });
      Object.assign(lift.firstChild.style, {
        width: `${sw}px`, height: `${sh}px`, transform: `translate(${-x * k}px, ${-y * k}px) scale(${k})`,
      });
      const cx = box.left + (x + w / 2) * box.width / sw;
      const cy = box.top + (y + h / 2) * box.height / sh;
      const fit = (c, size, start, length) => Math.min(Math.max(c - size / 2, start), start + length - size);
      lift.style.left = `${fit(cx, w * k, ax, aw)}px`;
      lift.style.top = `${fit(cy, h * k, ay, ah)}px`;
      document.body.append(lift);
    }
  }

  if (params.get('safe')) {
    const list = (name) => (params.get(name) || '').split(';').filter(Boolean).map(rect);
    const [safe] = list('safe');
    const avoid = list('avoid');
    for (const [kind, areas] of [['safe', [safe]], ['avoid', avoid], ['guide', list('guides')]]) {
      for (const [x, y, w, h] of areas) {
        const box = document.createElement('div');
        box.className = `safe-overlay ${kind}`;
        Object.assign(box.style, { left: `${x}px`, top: `${y}px`, width: `${w}px`, height: `${h}px` });
        document.body.append(box);
      }
    }
    if (params.has('check')) {
      const [x, y, w, h] = safe;
      const overlaps = (r, [ax, ay, aw, ah]) => r.left < ax + aw && r.right > ax && r.top < ay + ah && r.bottom > ay;
      const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
      for (let node = walker.nextNode(); node; node = walker.nextNode()) {
        const el = node.parentElement;
        if (!node.textContent.trim() || el.closest('[data-decor], script, style') || !el.checkVisibility({ visibilityProperty: true })) continue;
        const range = document.createRange();
        range.selectNodeContents(node);
        // Glyph boxes include side bearings, so heavy type set flush by eye pokes out a little.
        const t = Math.max(1, parseFloat(getComputedStyle(el).fontSize) * .03);
        // One rect per line, so a ragged line doesn't count as the whole block's box.
        for (const r of range.getClientRects()) {
          if (r.left < x - t || r.top < y - t || r.right > x + w + t || r.bottom > y + h + t || avoid.some((a) => overlaps(r, a))) {
            problems.push(`"${node.textContent.trim().slice(0, 40)}" outside the safe area (${[r.left, r.top, r.right, r.bottom].map(Math.round)})`);
            break;
          }
        }
      }
    }
  }
  if (params.has('check')) document.body.dataset.problems = JSON.stringify(problems);

  if (params.has('video')) {
    const phone = document.querySelector('.phone[data-video]');
    const screen = phone.querySelector('.screen');
    // Scale and rotation of every transform from the phone up to <body>.
    let matrix = new DOMMatrix();
    for (let el = phone; el; el = el.parentElement) {
      const transform = getComputedStyle(el).transform;
      if (transform !== 'none') matrix = new DOMMatrix(transform).multiply(matrix);
    }
    // A rotated box's bounding rectangle has the same center as the box.
    const box = phone.getBoundingClientRect();
    document.body.dataset.layout = JSON.stringify({
      center: [box.left + box.width / 2, box.top + box.height / 2],
      scale: Math.hypot(matrix.a, matrix.b),
      angle: Math.atan2(matrix.b, matrix.a) * 180 / Math.PI,
      size: [phone.offsetWidth, phone.offsetHeight],
      screen: [screen.offsetLeft, screen.offsetTop, screen.offsetWidth, screen.offsetHeight],
      radius: parseFloat(getComputedStyle(screen).borderTopLeftRadius) || 0,
      frame: phone.querySelector('.frame').src,
    });
    phone.style.visibility = 'hidden';
  }
  document.body.dataset.ready = '';
})();
