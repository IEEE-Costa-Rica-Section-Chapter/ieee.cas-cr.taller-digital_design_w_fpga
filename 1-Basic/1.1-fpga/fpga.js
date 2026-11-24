/* Module 1.1 widgets: LUT4 internals, logic cell, gate view, predict-the-resources table */
'use strict';

(function () {
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text !== undefined) e.textContent = text;
    return e;
  }
  function bit(n, i) { return (n >> i) & 1; }

  /* ---------------------------------------------------------- LUT4 ---- */
  // addr = {d,c,b,a}: input a is address bit 0
  var PRESETS = {
    and4: { name: 'a AND b AND c AND d', f: function (a, b, c, d) { return a & b & c & d; } },
    or4:  { name: 'a OR b OR c OR d',    f: function (a, b, c, d) { return a | b | c | d; } },
    xor4: { name: 'a XOR b XOR c XOR d', f: function (a, b, c, d) { return a ^ b ^ c ^ d; } },
    maj:  { name: 'majority(a, b, c)  (d ignored)', f: function (a, b, c) { return (a & b) | (a & c) | (b & c); } },
    aoi:  { name: '(a AND b) OR (c AND d)', f: function (a, b, c, d) { return (a & b) | (c & d); } },
    mux:  { name: 'd ? c : (b ? a : 0)  (a made-up function)', f: function (a, b, c, d) { return d ? c : (b ? a : 0); } }
  };

  /* ------------------------------------------------ gate diagrams ---- */
  // [id, type, input ids...]; the last gate is the output y
  var CIRCUITS = {
    and4: [['g1', 'AND', 'a', 'b'], ['g2', 'AND', 'c', 'd'], ['y', 'AND', 'g1', 'g2']],
    or4:  [['g1', 'OR', 'a', 'b'], ['g2', 'OR', 'c', 'd'], ['y', 'OR', 'g1', 'g2']],
    xor4: [['g1', 'XOR', 'a', 'b'], ['g2', 'XOR', 'c', 'd'], ['y', 'XOR', 'g1', 'g2']],
    maj:  [['g1', 'AND', 'a', 'b'], ['g2', 'AND', 'a', 'c'], ['g3', 'AND', 'b', 'c'],
           ['g4', 'OR', 'g1', 'g2'], ['y', 'OR', 'g4', 'g3']],
    aoi:  [['g1', 'AND', 'a', 'b'], ['g2', 'AND', 'c', 'd'], ['y', 'OR', 'g1', 'g2']],
    mux:  [['g1', 'AND', 'a', 'b'], ['g2', 'NOT', 'd'], ['g3', 'AND', 'g1', 'g2'],
           ['g4', 'AND', 'c', 'd'], ['y', 'OR', 'g3', 'g4']]
  };
  var NS = 'http://www.w3.org/2000/svg';
  var SHAPES = {
    AND: 'M0 0 H18 A18 15 0 0 1 18 30 H0 Z',
    OR:  'M0 0 Q14 0 36 15 Q14 30 0 30 Q9 15 0 0 Z',
    XOR: 'M0 0 Q14 0 36 15 Q14 30 0 30 Q9 15 0 0 Z M-5 0 Q4 15 -5 30',
    NOT: 'M0 2 L26 15 L0 28 Z'
  };
  function evalGate(t, x, y) {
    return t === 'AND' ? x & y : t === 'OR' ? x | y : t === 'XOR' ? x ^ y : 1 - x;
  }

  function gateSvg(key, inp) {
    var circ = CIRCUITS[key];
    var val = { a: inp[0], b: inp[1], c: inp[2], d: inp[3] };
    var lvl = { a: 0, b: 0, c: 0, d: 0 }, cy = {}, gx = {}, gtype = {};
    var names = ['a', 'b', 'c', 'd'], maxL = 0, i;
    for (i = 0; i < 4; i++) cy[names[i]] = 28 + i * 52;
    circ.forEach(function (g) {
      var l = 0;
      g.slice(2).forEach(function (s) { l = Math.max(l, lvl[s]); });
      gtype[g[0]] = g[1];
      lvl[g[0]] = l + 1; maxL = Math.max(maxL, l + 1);
      val[g[0]] = evalGate(g[1], val[g[2]], g.length > 3 ? val[g[3]] : 0);
    });
    // vertical placement, level by level
    for (var L = 1; L <= maxL; L++) {
      var row = circ.filter(function (g) { return lvl[g[0]] === L; }).map(function (g) {
        var s = g.slice(2).map(function (id) { return cy[id]; });
        return { g: g, want: s.reduce(function (p, q) { return p + q; }, 0) / s.length };
      }).sort(function (p, q) { return p.want - q.want; });
      var last = -1e9;
      row.forEach(function (r) {
        var y = Math.max(r.want, last + 46);
        cy[r.g[0]] = y; last = y; gx[r.g[0]] = 90 + (L - 1) * 120;
      });
    }
    var W = 90 + maxL * 120 + 150, H = 28 + 3 * 52 + 36;
    var out = '<svg class="gates-svg" viewBox="0 0 ' + W + ' ' + H + '" role="img" aria-label="Gate-level circuit with live values">';
    var wires = '', shapes = '';
    function wire(x1, y1, x2, y2, v, k) {
      var xm = x1 + 18 + (k % 3) * 7;
      wires += '<path class="wire' + (v ? ' on' : '') + '" d="M' + x1 + ' ' + y1 + ' H' + xm + ' V' + y2 + ' H' + x2 + '"/>';
    }
    // inputs
    names.forEach(function (n, qi) {
      shapes += '<text class="gt-lbl" x="6" y="' + (cy[n] + 5) + '">' + n + '</text>' +
        '<g class="clickable" data-in="' + qi + '"><circle class="knob' + (val[n] ? ' on' : '') + '" cx="40" cy="' + cy[n] + '" r="10"/>' +
        '<text class="knob-val' + (val[n] ? ' on' : '') + '" x="40" y="' + (cy[n] + 4) + '" text-anchor="middle">' + val[n] + '</text></g>';
    });
    var k = 0;
    circ.forEach(function (g) {
      var id = g[0], type = g[1], x = gx[id], y = cy[id] - 15;
      var srcs = g.slice(2).sort(function (p, q) { return cy[p] - cy[q]; });
      var pins = srcs.length === 1 ? [15] : [8, 22];
      var xin = type === 'XOR' ? x - 5 : x;
      srcs.forEach(function (s, j) {
        var sx = lvl[s] === 0 ? 50 : gx[s] + (gtype[s] === 'NOT' ? 34 : 36);
        wire(sx, cy[s], xin, y + pins[j], val[s], k++);
      });
      var xo = x + (type === 'NOT' ? 34 : 36);
      shapes += '<g transform="translate(' + x + ' ' + y + ')"><path class="gate" d="' + SHAPES[type] + '"/>' +
        (type === 'NOT' ? '<circle class="gate" cx="30" cy="15" r="4"/>' : '') +
        '<text class="gt-name" x="' + (type === 'NOT' ? 8 : 12) + '" y="19">' + (type === 'NOT' ? '' : type === 'XOR' ? '=1' : type === 'AND' ? '&amp;' : '&ge;1') + '</text></g>' +
        '<text class="gt-val' + (val[id] ? ' on' : '') + '" x="' + (xo + 4) + '" y="' + (cy[id] - 6) + '">' + val[id] + '</text>';
    });
    // output wire
    var yx = gx.y + 36;
    wires += '<path class="wire' + (val.y ? ' on' : '') + '" d="M' + yx + ' ' + cy.y + ' H' + (W - 40) + '"/>';
    shapes += '<circle class="pin' + (val.y ? ' on' : '') + '" cx="' + (W - 40) + '" cy="' + cy.y + '" r="4"/>' +
      '<text class="gt-lbl" x="' + (W - 30) + '" y="' + (cy.y + 4) + '">y = ' + val.y + '</text>';
    return out + wires + shapes + '</svg>';
  }

  /* ----------------------------------------- shared SVG helpers ---- */
  function hline(x1, x2, y, cls) {
    return '<path class="wire ' + cls + '" d="M' + x1 + ' ' + y + ' H' + x2 + '"/>';
  }
  function wcls(act, on) { return (act ? 'act' : 'dim') + (on ? ' on' : ''); }
  function addrOf(inp) { return inp[0] | (inp[1] << 1) | (inp[2] << 2) | (inp[3] << 3); }
  function bin4(n) { return ('0000' + n.toString(2)).slice(-4); }
  function matchPreset(mem) {
    var keys = Object.keys(PRESETS);
    for (var q = 0; q < keys.length; q++) {
      var f = PRESETS[keys[q]].f, ok = true;
      for (var k = 0; k < 16; k++) {
        if ((f(bit(k, 0), bit(k, 1), bit(k, 2), bit(k, 3)) & 1) !== mem[k]) { ok = false; break; }
      }
      if (ok) return keys[q];
    }
    return null;
  }
  function presetBits(key) {
    var f = PRESETS[key].f, out = [];
    for (var k = 0; k < 16; k++) out.push(f(bit(k, 0), bit(k, 1), bit(k, 2), bit(k, 3)) & 1);
    return out;
  }

  /* --------------------------------- LUT4 internals (SRAM + muxes) ---- */
  // 16 configuration cells feed a tree of 2:1 multiplexers. Input a steers the
  // first column (16 -> 8), b the second (8 -> 4), c the third, d the last.
  function lutSvg(mem, inp, wr) {
    var addr = addrOf(inp);
    var Y0 = 46, DY = 23, cellX = 40, cellW = 40, MW = 40, colX = [150, 235, 320, 405], W = 560;
    var H = Y0 + 15 * DY + 30;
    var rails = '', wires = '', shapes = '', i, L, j;
    var prevY = [], prevV = [];
    for (i = 0; i < 16; i++) { prevY.push(Y0 + i * DY); prevV.push(mem[i]); }

    // configuration cells
    shapes += '<text class="gt-name" x="6" y="14">16 SRAM cells</text><text class="gt-name" x="6" y="28">(address d c b a)</text>';
    for (i = 0; i < 16; i++) {
      var cy0 = Y0 + i * DY;
      shapes += '<text class="gt-name" x="6" y="' + (cy0 + 4) + '">' + bin4(i) + '</text>' +
        '<g class="clickable" data-cell="' + i + '"><rect class="cfg' + (mem[i] ? ' on' : '') + (i === addr ? ' act' : '') + (i === wr ? ' wr' : '') +
        '" x="' + cellX + '" y="' + (cy0 - 9) + '" width="' + cellW + '" height="18" rx="3"/>' +
        '<text class="cfg-val' + (mem[i] ? ' on' : '') + '" x="' + (cellX + cellW / 2) + '" y="' + (cy0 + 5) + '" text-anchor="middle">' + mem[i] + '</text></g>';
    }

    for (L = 1; L <= 4; L++) {
      var x = colX[L - 1], sel = inp[L - 1];
      var srcX = L === 1 ? cellX + cellW : colX[L - 2] + MW;
      var nextY = [], nextV = [], bottom = 0;
      for (j = 0; j < prevY.length / 2; j++) {
        var y0 = prevY[2 * j], y1 = prevY[2 * j + 1], cy = (y0 + y1) / 2, half = (y1 - y0) / 2, hm = 2 * half + 14;
        var onPath = (addr >> L) === j;
        var outV = sel ? prevV[2 * j + 1] : prevV[2 * j];
        wires += hline(srcX, x, y0, wcls(onPath && sel === 0, prevV[2 * j]));
        wires += hline(srcX, x, y1, wcls(onPath && sel === 1, prevV[2 * j + 1]));
        shapes += '<polygon class="mux' + (onPath ? ' act' : '') + '" points="' + x + ',' + (cy - hm / 2) + ' ' + (x + MW) + ',' + (cy - hm / 2 + 8) +
          ' ' + (x + MW) + ',' + (cy + hm / 2 - 8) + ' ' + x + ',' + (cy + hm / 2) + '"/>' +
          '<text class="gt-name" x="' + (x + 4) + '" y="' + (y0 + 3) + '">0</text><text class="gt-name" x="' + (x + 4) + '" y="' + (y1 + 3) + '">1</text>' +
          '<text class="gt-val' + (onPath && outV ? ' on' : '') + '" x="' + (x + MW + 3) + '" y="' + (cy - 5) + '">' + outV + '</text>';
        nextY.push(cy); nextV.push(outV);
        bottom = Math.max(bottom, cy + hm / 2);
      }
      var xr = x + MW / 2, name = ['a', 'b', 'c', 'd'][L - 1];
      rails += '<path class="rail' + (sel ? ' on' : '') + '" d="M' + xr + ' 30 V' + bottom + '"/>';
      shapes += '<g class="clickable" data-knob="' + (L - 1) + '"><circle class="knob' + (sel ? ' on' : '') + '" cx="' + xr + '" cy="18" r="10"/>' +
        '<text class="knob-val' + (sel ? ' on' : '') + '" x="' + xr + '" y="22" text-anchor="middle">' + sel + '</text></g>' +
        '<text class="gt-lbl" x="' + (xr - 24) + '" y="23">' + name + '</text>';
      prevY = nextY; prevV = nextV;
    }
    var yOut = prevV[0], xo = colX[3] + MW;
    wires += hline(xo, W - 88, prevY[0], wcls(true, yOut));
    shapes += '<circle class="pin' + (yOut ? ' on' : '') + '" cx="' + (W - 88) + '" cy="' + prevY[0] + '" r="4"/>' +
      '<text class="gt-lbl" x="' + (W - 78) + '" y="' + (prevY[0] + 5) + '">y = ' + yOut + '</text>';
    return '<svg class="gates-svg lut-svg" viewBox="0 0 ' + W + ' ' + H + '" role="img" aria-label="LUT4 internals: 16 configuration cells and a multiplexer tree">' +
      rails + wires + shapes + '</svg>';
  }

  function initLut(root) {
    var inputs = [0, 0, 0, 0];
    var mem = presetBits('and4');
    var wr = -1, busy = false;
    var sel = root.querySelector('#lut-preset');
    var loadBtn = root.querySelector('#lut-load');
    var bitsEl = root.querySelector('#lut-bits');
    var statusEl = root.querySelector('#lut-status');
    var svgEl = root.querySelector('#lut-internals');
    var gatesEl = root.querySelector('#lut-gates');
    var outEl = root.querySelector('#lut-out');
    var wordEl = root.querySelector('#lut-word');
    var addrEl = root.querySelector('#lut-addr');
    var fnEl = root.querySelector('#lut-fn');
    var hintEl = root.querySelector('#lut-hint');
    var vSram = root.querySelector('#view-sram');
    var vGates = root.querySelector('#view-gates');

    function setView(v) {
      vSram.setAttribute('aria-pressed', v === 'sram' ? 'true' : 'false');
      vGates.setAttribute('aria-pressed', v === 'gates' ? 'true' : 'false');
      svgEl.hidden = v !== 'sram';
      gatesEl.hidden = v !== 'gates';
      hintEl.textContent = v === 'sram'
        ? 'Bright wires carry the path being read; dim wires are not selected. Blue means the wire carries a 1. Click an SRAM cell to flip it.'
        : 'The same function as a network of gates: blue wires carry a 1. This is what you describe in SystemVerilog; the FPGA stores it in the LUT instead. Click the input circles to toggle them; the inputs are shared by both views.';
    }
    gatesEl.addEventListener('click', function (e) {
      var t = e.target.closest ? e.target.closest('[data-in]') : null;
      if (!t) return;
      inputs[Number(t.getAttribute('data-in'))] ^= 1; render();
    });
    vSram.addEventListener('click', function () { setView('sram'); });
    vGates.addEventListener('click', function () { setView('gates'); });

    function bitstreamText(key) {
      var b = presetBits(key), s = '';
      for (var k = 15; k >= 0; k--) { s += b[k]; if (k % 4 === 0 && k) s += ' '; }
      return s;
    }
    function render() {
      var addr = addrOf(inputs), word = 0, k;
      for (k = 0; k < 16; k++) word |= mem[k] << k;
      svgEl.innerHTML = lutSvg(mem, inputs, wr);
      var m = matchPreset(mem);
      gatesEl.innerHTML = m ? gateSvg(m, inputs)
        : '<p class="gates-note">The stored bits do not match any of the listed functions, so there is no gate drawing for them. The LUT does not need one: it just returns the stored bit.</p>';
      outEl.textContent = mem[addr];
      addrEl.textContent = "4'b" + bin4(addr) + ' = ' + addr;
      wordEl.textContent = "16'h" + ('0000' + word.toString(16)).slice(-4).toUpperCase();
      fnEl.textContent = m ? PRESETS[m].name : 'custom (your own bits)';
      bitsEl.textContent = bitstreamText(sel.value);
    }
    svgEl.addEventListener('click', function (e) {
      var t = e.target.closest ? e.target.closest('[data-knob],[data-cell]') : null;
      if (!t || busy) return;
      if (t.hasAttribute('data-knob')) { var q = Number(t.getAttribute('data-knob')); inputs[q] ^= 1; }
      else { var c = Number(t.getAttribute('data-cell')); mem[c] ^= 1; statusEl.textContent = 'You flipped one stored bit by hand: that is a different function now.'; }
      render();
    });
    Object.keys(PRESETS).forEach(function (key) {
      var o = el('option', null, PRESETS[key].name); o.value = key; sel.appendChild(o);
    });
    sel.value = 'xor4';
    sel.addEventListener('change', function () { bitsEl.textContent = bitstreamText(sel.value); });
    loadBtn.addEventListener('click', function () {
      if (busy) return;
      var target = presetBits(sel.value), k = 0;
      var fast = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      busy = true; loadBtn.disabled = true;
      function done() {
        wr = -1; busy = false; loadBtn.disabled = false;
        statusEl.textContent = 'Done. The LUT now computes: ' + PRESETS[sel.value].name + '. Nothing was rewired; only the 16 stored bits changed.';
        render();
      }
      function step() {
        if (k > 15) { done(); return; }
        mem[k] = target[k]; wr = k; k++;
        statusEl.textContent = 'Loading configuration bit ' + k + ' of 16...';
        render();
        if (fast) step(); else setTimeout(step, 70);
      }
      step();
    });
    setView('sram');
    statusEl.textContent = 'The LUT starts configured as a 4-input AND. Pick another function and press Load.';
    render();
  }

  /* ----------------------------------------------------- logic cell ---- */
  // LUT4 -> (optional) D flip-flop -> output multiplexer. The multiplexer
  // select is itself a configuration bit, like the 16 LUT bits.
  function cellSvg(st) {
    var mem = st.mem, inp = st.inp, w = mem[addrOf(inp)], regOut = st.reg === 1;
    var out = regOut ? st.q : w;
    var W = 640, H = 300, s = '', rails = '', i;
    var ys = [60, 105, 150, 195];
    // inputs
    ['a', 'b', 'c', 'd'].forEach(function (n, k) {
      rails += hline(56, 140, ys[k], wcls(true, inp[k]));
      s += '<g class="clickable" data-knob="' + k + '"><circle class="knob' + (inp[k] ? ' on' : '') + '" cx="46" cy="' + ys[k] + '" r="10"/>' +
        '<text class="knob-val' + (inp[k] ? ' on' : '') + '" x="46" y="' + (ys[k] + 4) + '" text-anchor="middle">' + inp[k] + '</text></g>' +
        '<text class="gt-lbl" x="14" y="' + (ys[k] + 5) + '">' + n + '</text>';
    });
    // LUT box with its 16 stored bits
    s += '<rect class="cell-box" x="140" y="30" width="130" height="190" rx="6"/>' +
      '<text class="gt-lbl" x="205" y="52" text-anchor="middle">LUT4</text>';
    var addr = addrOf(inp);
    for (i = 0; i < 16; i++) {
      var gx = 167 + (i % 4) * 19, gy = 66 + Math.floor(i / 4) * 19;
      s += '<rect class="cfg mini' + (mem[i] ? ' on' : '') + (i === addr ? ' act' : '') + '" x="' + gx + '" y="' + gy + '" width="16" height="16" rx="2"/>' +
        '<text class="cfg-val mini' + (mem[i] ? ' on' : '') + '" x="' + (gx + 8) + '" y="' + (gy + 12) + '" text-anchor="middle">' + mem[i] + '</text>';
    }
    s += '<text class="gt-name" x="205" y="165" text-anchor="middle">16 SRAM bits</text>' +
      '<text class="gt-name" x="205" y="182" text-anchor="middle">(read at the address</text>' +
      '<text class="gt-name" x="205" y="196" text-anchor="middle">d c b a)</text>' +
      '<text class="gt-name" x="205" y="212" text-anchor="middle">' + st.name + '</text>';
    // wires out of the LUT
    rails += hline(270, 300, 128, wcls(true, w));
    rails += '<path class="wire ' + wcls(!regOut, w) + '" d="M300 128 V110 H470"/>';
    rails += '<path class="wire ' + wcls(true, w) + '" d="M300 128 V172 H340"/>';
    rails += '<path class="wire ' + wcls(regOut, st.q) + '" d="M410 172 H440 V160 H470"/>';
    s += '<circle class="pin' + (w ? ' on' : '') + '" cx="300" cy="128" r="3"/>' +
      '<text class="gt-val' + (w ? ' on' : '') + '" x="278" y="120">' + w + '</text>';
    // D flip-flop
    s += '<rect class="cell-box" x="340" y="148" width="70" height="76" rx="5"/>' +
      '<text class="gt-name" x="375" y="142" text-anchor="middle">D flip-flop</text>' +
      '<text class="gt-lbl" x="347" y="177">D</text><text class="gt-lbl" x="395" y="177">Q</text>' +
      '<path class="gate" d="M340 199 L350 205 L340 211"/><text class="gt-name" x="354" y="209">clk</text>' +
      '<text class="gt-val' + (st.q ? ' on' : '') + '" x="414" y="165">' + st.q + '</text>' +
      '<text class="gt-name" x="375" y="240" text-anchor="middle">edges: ' + st.n + '</text>';
    // output multiplexer
    s += '<polygon class="mux act" points="470,85 510,93 510,177 470,185"/>' +
      '<text class="gt-name" x="474" y="113">0</text><text class="gt-name" x="474" y="163">1</text>';
    rails += hline(510, 570, 135, wcls(true, out));
    s += '<circle class="pin' + (out ? ' on' : '') + '" cx="570" cy="135" r="4"/>' +
      '<text class="gt-lbl" x="580" y="140">out = ' + out + '</text>';
    // select configuration bit
    rails += '<path class="wire act ' + (st.reg ? 'on' : '') + '" d="M490 222 V181"/>';
    s += '<g class="clickable" data-reg="1"><rect class="cfg' + (st.reg ? ' on' : '') + '" x="468" y="222" width="44" height="24" rx="3"/>' +
      '<text class="cfg-val' + (st.reg ? ' on' : '') + '" x="490" y="239" text-anchor="middle">' + st.reg + '</text></g>' +
      '<text class="gt-name" x="490" y="262" text-anchor="middle">1 SRAM bit selects the output:</text>' +
      '<text class="gt-name" x="490" y="276" text-anchor="middle">0 = LUT, 1 = flip-flop (click it)</text>';
    return '<svg class="gates-svg cell-svg" viewBox="0 0 ' + W + ' ' + H + '" role="img" aria-label="Logic cell: LUT4, D flip-flop and output multiplexer">' + rails + s + '</svg>';
  }

  function initCell(root) {
    var st = { inp: [0, 0, 0, 0], q: 0, n: 0, reg: 0, mem: presetBits('xor4'), name: 'a XOR b XOR c XOR d' };
    var sel = root.querySelector('#cell-fn');
    var clk = root.querySelector('#cell-clk');
    var host = root.querySelector('#cell-svg');
    var note = root.querySelector('#cell-note');

    function render() {
      host.innerHTML = cellSvg(st);
      var w = st.mem[addrOf(st.inp)];
      note.textContent = st.reg
        ? 'Output = flip-flop Q = ' + st.q + '. The LUT output is ' + w + (w === st.q ? ' (same, nothing to update).' : ': Q will copy it at the next clock edge.')
        : 'Output = LUT output = ' + w + '. It follows the inputs immediately.';
    }
    Object.keys(PRESETS).forEach(function (key) {
      var o = el('option', null, PRESETS[key].name); o.value = key; sel.appendChild(o);
    });
    sel.value = 'xor4';
    sel.addEventListener('change', function () { st.mem = presetBits(sel.value); st.name = PRESETS[sel.value].name; render(); });
    host.addEventListener('click', function (e) {
      var t = e.target.closest ? e.target.closest('[data-knob],[data-reg]') : null;
      if (!t) return;
      if (t.hasAttribute('data-knob')) { var q = Number(t.getAttribute('data-knob')); st.inp[q] ^= 1; }
      else st.reg ^= 1;
      render();
    });
    clk.addEventListener('click', function () { st.q = st.mem[addrOf(st.inp)]; st.n++; render(); });
    render();
  }

  /* ------------------------------------------------------- predict ---- */
  function initPredict(root) {
    var btn = root.querySelector('#predict-reveal');
    var msg = root.querySelector('#predict-msg');
    btn.addEventListener('click', function () {
      var right = 0, total = 0, empty = 0;
      Array.prototype.forEach.call(root.querySelectorAll('input[data-real]'), function (inp) {
        var cell = inp.parentNode;
        cell.classList.remove('ok', 'bad');
        if (inp.value === '') { empty++; return; }
        total++;
        var ok = Number(inp.value) === Number(inp.getAttribute('data-real'));
        cell.classList.add(ok ? 'ok' : 'bad');
        if (ok) right++;
      });
      Array.prototype.forEach.call(root.querySelectorAll('[data-reveal]'), function (s) {
        s.textContent = s.getAttribute('data-reveal');
      });
      msg.textContent = empty ? 'Fill every box first (' + empty + ' left); the measured values are shown anyway.'
        : right + ' of ' + total + ' predictions matched. Now run the real tool and compare.';
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    var l = document.getElementById('lut-widget'); if (l) initLut(l);
    var c = document.getElementById('cell-widget'); if (c) initCell(c);
    var p = document.getElementById('predict-widget'); if (p) initPredict(p);
  });
})();
