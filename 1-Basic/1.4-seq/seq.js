/* Module 1.4 widgets: blocking/non-blocking explainer is static; this file has the debounce visualizer */
'use strict';

(function () {
  var NS = 'http://www.w3.org/2000/svg';
  var DT = 0.05;            // ms per sample
  var SPAN = 40;            // ms shown
  var N = Math.round(SPAN / DT);

  function rng(seed) {      // small deterministic generator, so "same press" is repeatable
    var s = seed >>> 0;
    return function () { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; };
  }

  // raw button: press at tP, release at tR; each edge is followed by `bounce` ms of random toggling
  function makeRaw(seed, bounce) {
    var r = rng(seed), raw = new Array(N), tP = 5, tR = 24, level;
    function edgeAt(t0, to) {
      // returns function(t) -> level for t >= t0
      var changes = [], t = t0, v = 1 - to;
      while (t < t0 + bounce) {
        v ^= 1; changes.push([t, v]);
        t += 0.05 + r() * 1.7;
      }
      changes.push([Math.max(t, t0 + bounce), to]);
      return changes;
    }
    var press = edgeAt(tP, 1), rel = edgeAt(tR, 0);
    for (var i = 0; i < N; i++) {
      var t = i * DT; level = 0;
      press.forEach(function (c) { if (t >= c[0]) level = c[1]; });
      if (t >= tR) rel.forEach(function (c) { if (t >= c[0]) level = c[1]; });
      raw[i] = level;
    }
    return raw;
  }

  function debounce(raw, ms) {
    var limit = Math.max(1, Math.round(ms / DT)), cnt = 0, clean = 0, out = new Array(N);
    for (var i = 0; i < N; i++) {
      if (raw[i] === clean) cnt = 0;
      else if (cnt === limit - 1) { clean = raw[i]; cnt = 0; }
      else cnt++;
      out[i] = clean;
    }
    return out;
  }

  function edges(sig) {
    var n = 0;
    for (var i = 1; i < sig.length; i++) if (sig[i] !== sig[i - 1]) n++;
    return n;
  }

  function path(sig, y0, h) {
    var d = '', x;
    for (var i = 0; i < sig.length; i++) {
      x = 40 + (i / (sig.length - 1)) * 520;
      var y = sig[i] ? y0 : y0 + h;
      d += (i === 0 ? 'M' : 'L') + x.toFixed(1) + ' ' + y;
      if (i < sig.length - 1 && sig[i + 1] !== sig[i]) d += 'L' + x.toFixed(1) + ' ' + (sig[i + 1] ? y0 : y0 + h);
    }
    return d;
  }

  document.addEventListener('DOMContentLoaded', function () {
    var root = document.getElementById('debounce-widget');
    if (!root) return;
    var sB = root.querySelector('#deb-bounce'), sD = root.querySelector('#deb-time');
    var oB = root.querySelector('#deb-bounce-v'), oD = root.querySelector('#deb-time-v');
    var svg = root.querySelector('#deb-svg'), msg = root.querySelector('#deb-msg');
    var again = root.querySelector('#deb-again');
    var seed = 7;

    function render() {
      var bounce = Number(sB.value), ms = Number(sD.value);
      oB.textContent = bounce.toFixed(1) + ' ms'; oD.textContent = ms.toFixed(1) + ' ms';
      var raw = makeRaw(seed, bounce), clean = debounce(raw, ms);
      var eR = edges(raw), eC = edges(clean);
      svg.innerHTML = '';
      function add(tag, attrs, text) {
        var e = document.createElementNS(NS, tag);
        Object.keys(attrs).forEach(function (k) { e.setAttribute(k, attrs[k]); });
        if (text) e.textContent = text;
        svg.appendChild(e); return e;
      }
      add('text', { x: 4, y: 30, class: 'gt-lbl' }, 'raw');
      add('text', { x: 4, y: 130, class: 'gt-lbl' }, 'clean');
      add('path', { d: path(raw, 20, 40), class: 'wire act' + ' on', fill: 'none' });
      add('path', { d: path(clean, 120, 40), class: 'wire act' + ' on', fill: 'none' });
      // time axis (every 5 ms)
      for (var t = 0; t <= SPAN; t += 5) {
        var x = 40 + (t / SPAN) * 520;
        add('line', { x1: x, x2: x, y1: 70, y2: 110, class: 'rail' });
        add('text', { x: x, y: 190, class: 'gt-name', 'text-anchor': 'middle' }, t + ' ms');
      }
      var verdict;
      if (eC === 2) verdict = 'The output has exactly 2 edges: one press, one release.';
      else if (eC < 2) verdict = 'The debounce time is so long that the press was lost.';
      else verdict = 'The output glitches: a quiet gap inside the bounce lasted longer than the debounce time (' + ms.toFixed(1) + ' ms), so the circuit took a bounce for a real change. The safe rule: wait longer than the whole bounce (' + bounce.toFixed(1) + ' ms).';
      msg.textContent = 'Raw input: ' + eR + ' edges. Debounced output: ' + eC + ' edges. ' + verdict;
    }
    sB.addEventListener('input', render);
    sD.addEventListener('input', render);
    again.addEventListener('click', function () { seed = (seed * 7 + 13) % 9973; render(); });
    render();
  });
})();
