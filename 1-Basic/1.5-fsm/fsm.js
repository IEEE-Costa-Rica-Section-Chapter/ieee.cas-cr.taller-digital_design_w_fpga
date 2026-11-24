/* Module 1.5 widget: FSM stepper for the 1011 detector (Moore) */
'use strict';

(function () {
  var NS = 'http://www.w3.org/2000/svg';
  var STATES = [
    { id: 'S_IDLE', x: 60 }, { id: 'S_1', x: 190 }, { id: 'S_10', x: 320 }, { id: 'S_101', x: 450 }, { id: 'S_1011', x: 580 }
  ];
  var Y = 120, R = 30;
  // next[state][input]
  var NEXT = {
    S_IDLE: ['S_IDLE', 'S_1'], S_1: ['S_10', 'S_1'], S_10: ['S_IDLE', 'S_101'],
    S_101: ['S_10', 'S_1011'], S_1011: ['S_10', 'S_1']
  };
  var XS = {}; STATES.forEach(function (s) { XS[s.id] = s.x; });

  function edgePath(from, to) {
    var x1 = XS[from], x2 = XS[to];
    if (from === to) return { d: 'M' + (x1 - 14) + ' ' + (Y - R + 2) + ' C' + (x1 - 40) + ' ' + (Y - 85) + ' ' + (x1 + 40) + ' ' + (Y - 85) + ' ' + (x1 + 14) + ' ' + (Y - R + 2), lx: x1, ly: Y - 72 };
    if (x2 > x1) return { d: 'M' + (x1 + R) + ' ' + Y + ' L' + (x2 - R) + ' ' + Y, lx: (x1 + x2) / 2, ly: Y - 8 };
    var dy = Math.min(140, 40 + (x1 - x2) * 0.35);
    var up = (to === 'S_1' || (from === 'S_1011' && to === 'S_10'));
    var sy = up ? -1 : 1;
    return { d: 'M' + (x1 - 8) + ' ' + (Y + sy * R) + ' Q' + ((x1 + x2) / 2) + ' ' + (Y + sy * (R + dy)) + ' ' + (x2 + 8) + ' ' + (Y + sy * R),
             lx: (x1 + x2) / 2, ly: Y + sy * (R + dy / 2 + 6) };
  }

  function mk(tag, attrs, text) {
    var e = document.createElementNS(NS, tag);
    Object.keys(attrs || {}).forEach(function (k) { e.setAttribute(k, attrs[k]); });
    if (text) e.textContent = text;
    return e;
  }

  document.addEventListener('DOMContentLoaded', function () {
    var root = document.getElementById('fsm-widget');
    if (!root) return;
    var svg = root.querySelector('#fsm-svg');
    var hist = root.querySelector('#fsm-hist');
    var out = root.querySelector('#fsm-out');
    var state = 'S_IDLE', last = null, bits = '';

    var edgeEls = {};
    var defs = mk('defs');
    var marker = mk('marker', { id: 'fsm-arrow', viewBox: '0 0 10 10', refX: '9', refY: '5', markerWidth: '7', markerHeight: '7', orient: 'auto-start-reverse' });
    marker.appendChild(mk('path', { d: 'M0 0 L10 5 L0 10 z', class: 'fsm-arrowhead' }));
    defs.appendChild(marker); svg.appendChild(defs);

    Object.keys(NEXT).forEach(function (from) {
      [0, 1].forEach(function (inp) {
        var to = NEXT[from][inp], ep = edgePath(from, to);
        var p = mk('path', { d: ep.d, class: 'fsm-edge', fill: 'none', 'marker-end': 'url(#fsm-arrow)' });
        var t = mk('text', { x: ep.lx, y: ep.ly, class: 'gt-name fsm-elabel', 'text-anchor': 'middle' }, String(inp));
        svg.appendChild(p); svg.appendChild(t);
        edgeEls[from + inp] = { p: p, t: t };
      });
    });
    var circles = {};
    STATES.forEach(function (s) {
      var g = mk('g');
      var c = mk('circle', { cx: s.x, cy: Y, r: R, class: 'fsm-state' + (s.id === 'S_1011' ? ' fsm-final' : '') });
      g.appendChild(c);
      g.appendChild(mk('text', { x: s.x, y: Y + 4, 'text-anchor': 'middle', class: 'gt-name fsm-sname' }, s.id));
      svg.appendChild(g); circles[s.id] = c;
    });

    function render() {
      STATES.forEach(function (s) { circles[s.id].classList.toggle('current', s.id === state); });
      Object.keys(edgeEls).forEach(function (k) {
        var on = last === k;
        edgeEls[k].p.classList.toggle('taken', on);
        edgeEls[k].t.classList.toggle('taken', on);
      });
      hist.textContent = bits ? bits.split('').join(' ') : '(none yet)';
      var d = state === 'S_1011';
      out.textContent = 'detect = ' + (d ? 1 : 0);
      out.classList.toggle('on', d);
    }
    function feed(b) {
      last = state + b;
      state = NEXT[state][b];
      bits = (bits + b).slice(-16);
      render();
    }
    root.querySelector('#fsm-0').addEventListener('click', function () { feed(0); });
    root.querySelector('#fsm-1').addEventListener('click', function () { feed(1); });
    root.querySelector('#fsm-reset').addEventListener('click', function () { state = 'S_IDLE'; last = null; bits = ''; render(); });
    render();
  });
})();
