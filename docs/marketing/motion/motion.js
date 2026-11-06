// Shared by the compositions in this folder (README.md). Load after gsap, before the composition's
// own script. Motion.create() splits [data-words] into words and hides .caption until its time;
// finish() registers the timeline.
//
// With ?check&safe=x,y,w,h&avoid=x,y,w,h;… the page seeks through the whole timeline and writes the
// text that leaves the safe area or enters an avoided one to <body data-problems>, for build_kit.py.
// [data-decor] marks text that may sit outside it (the brand row).
window.__timelines = window.__timelines || {};

const Motion = (() => {
  const WORD_GAP = .13;

  const splitWords = (node) => {
    for (const child of [...node.childNodes]) {
      if (child.nodeType !== Node.TEXT_NODE) {
        splitWords(child);
        continue;
      }
      child.replaceWith(...child.textContent.split(/(\s+)/).filter(Boolean).map((part) => {
        if (!part.trim()) return document.createTextNode(' ');
        const span = document.createElement('span');
        span.className = 'w';
        span.textContent = part;
        return span;
      }));
    }
  };
  const element = (target) => (typeof target === 'string' ? document.querySelector(target) : target);
  const spokenKey = (word) => word.toLowerCase().replace(/[^\p{L}\p{N}]/gu, '');

  // When each shown word is said: the next spoken word that matches, in order. A word the voice doesn't
  // say follows the word before it, so a caption that isn't word for word still reads in one go.
  const spokenTimes = (words, line, start) => {
    const said = (window.VOICE && window.VOICE[line] && window.VOICE[line].words) || null;
    if (!said) return null;
    let next = 0;
    let previous = start - WORD_GAP;
    return words.map((w, i) => {
      const key = spokenKey(w.textContent);
      const found = said.findIndex((entry, j) => j >= next && spokenKey(entry[0]) === key);
      if (found >= 0) next = found + 1;
      const time = i === 0 && found < 0 ? start : Math.max(found >= 0 ? said[found][1] : previous + WORD_GAP, previous);
      previous = time;
      return time;
    });
  };

  const create = () => {
    document.querySelectorAll('[data-words]').forEach(splitWords);
    gsap.set('.caption', { autoAlpha: 0 });
    const tl = gsap.timeline({ paused: true });
    const word = (target, t) => tl.fromTo(target, { opacity: 0, y: 26 }, { opacity: 1, y: 0, duration: .14, ease: 'power3.out' }, t);
    const caption = (el, start, end) => {
      const all = [...el.querySelectorAll('.w')];
      const times = (el.dataset.line !== undefined && spokenTimes(all, Number(el.dataset.line), start))
        || all.map((_, i) => start + i * WORD_GAP);
      if (start < .01) {
        gsap.set(el, { autoAlpha: 1 });
        all.slice(1).forEach((w, i) => word(w, times[i + 1]));
      } else {
        tl.set(el, { autoAlpha: 1 }, start);
        all.forEach((w, i) => word(w, times[i]));
      }
      if (end !== undefined) tl.set(el, { autoAlpha: 0 }, end);
    };
    return {
      tl,
      word,
      // One start time per word of target, in order.
      words: (target, times) => element(target).querySelectorAll('.w').forEach((w, i) => word(w, times[i])),
      // Words follow the voice line in data-line, else each other WORD_GAP apart. A caption at 0 s has its
      // first word on frame 0, which is what a feed shows before the Short plays.
      caption: (target, start, end) => caption(element(target), start, end),
      // A caption of voice line `line`, its words as they are said. start: 0 for a hook.
      say: (target, line, end, start) => {
        const el = element(target);
        el.dataset.line = line;
        caption(el, start === undefined ? window.VOICE[line].at : start, end);
      },
      // The second a voice line says a word (its nth time), to time a drawing to it.
      when: (line, spoken, nth = 1) => window.VOICE[line].words.filter((entry) => spokenKey(entry[0]) === spokenKey(spoken))[nth - 1][1],
      leave: (target, t) => {
        tl.to(target, { y: -90, opacity: 0, duration: .16, ease: 'power2.in' }, t);
        tl.set(target, { autoAlpha: 0 }, t + .16);
      },
      finish: () => {
        window.__timelines.main = tl;
        tl.seek(0);
      },
    };
  };

  return { create };
})();

addEventListener('load', async () => {
  const params = new URLSearchParams(location.search);
  if (!params.has('check')) return;
  await document.fonts.ready;
  const rects = (name) => (params.get(name) || '').split(';').filter(Boolean).map((r) => r.split(',').map(Number));
  const [[x, y, w, h]] = rects('safe');
  const avoid = rects('avoid');
  const overlaps = (r, [ax, ay, aw, ah]) => r.left < ax + aw && r.right > ax && r.top < ay + ah && r.bottom > ay;
  const visible = (el) => {
    let opacity = 1;
    for (let node = el; node && node !== document.documentElement; node = node.parentElement) {
      const style = getComputedStyle(node);
      if (style.visibility === 'hidden' || style.display === 'none') return false;
      opacity *= Number(style.opacity);
    }
    return opacity > .05;
  };
  const problems = new Set();
  if (![...document.fonts].some((face) => face.family.replace(/["']/g, '') === 'Archivo' && face.status === 'loaded')) {
    problems.add('the Archivo font did not load');
  }
  const tl = window.__timelines.main;
  const length = Number(document.querySelector('[data-composition-id]').dataset.duration);
  for (let t = 0; t <= length; t += .25) {
    tl.seek(t, false);
    const walker = document.createTreeWalker(document.getElementById('root'), NodeFilter.SHOW_TEXT);
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
      const el = node.parentElement;
      if (!node.textContent.trim() || el.closest('[data-decor]') || !visible(el)) continue;
      const range = document.createRange();
      range.selectNodeContents(node);
      // Glyph boxes include side bearings, so heavy type set flush by eye pokes out a little.
      const m = Math.max(1, parseFloat(getComputedStyle(el).fontSize) * .03);
      for (const r of range.getClientRects()) {
        if (r.left < x - m || r.top < y - m || r.right > x + w + m || r.bottom > y + h + m || avoid.some((a) => overlaps(r, a))) {
          problems.add(`"${node.textContent.trim().slice(0, 40)}" outside the safe area at ${t.toFixed(2)} s`);
          break;
        }
      }
    }
  }
  document.body.dataset.problems = JSON.stringify([...problems]);
  document.body.dataset.warnings = '[]';
});
