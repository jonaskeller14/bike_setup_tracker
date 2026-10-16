// Shared by the marketing templates in this folder and the App Store creative templates
// (assets/store/app-store/creative/). Load it at the end of <body>.
//
// - Fills every [data-param] element from the URL parameter of that name. *Words* in stars
//   become <em>; an element whose parameter is missing or empty is hidden.
// - Points every img[data-shot="N"] at the N-th entry of ?shots=03,04 (iPhone store raws).
// - Adds mode-endcard / mode-video to <body> for ?endcard / ?video.
// - ?video hides the phone marked data-video and writes its position to <body data-layout>, so
//   tool/marketing/render_video.py can put a recording in its place.
(() => {
  const params = new URLSearchParams(location.search);
  const escape = (text) => text.replace(/[&<>"]/g, (c) => `&#${c.charCodeAt(0)};`);
  const markup = (text) => escape(text).replace(/\*([^*]+)\*/g, '<em>$1</em>');

  document.querySelectorAll('[data-param]').forEach((el) => {
    const value = params.get(el.dataset.param);
    if (value) el.innerHTML = markup(value);
    else el.hidden = true;
  });

  const shots = (params.get('shots') || '').split(',').filter(Boolean);
  document.querySelectorAll('img[data-shot]').forEach((img) => {
    const shot = shots[Number(img.dataset.shot)] || shots[0] || '01';
    img.src = new URL(`../../../assets/store/app-store/iPhone-17-Pro-Max/${shot}_raw.png`, document.currentScript?.src ?? location.href).href;
  });

  for (const mode of ['endcard', 'video']) {
    if (params.has(mode)) document.body.classList.add(`mode-${mode}`);
  }

  if (!params.has('video')) return;
  window.addEventListener('load', () => {
    const phone = document.querySelector('.phone[data-video]');
    const screen = phone.querySelector('.screen');
    const frame = phone.querySelector('.frame');
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
      frame: frame.src,
    });
    phone.style.visibility = 'hidden';
  });
})();
