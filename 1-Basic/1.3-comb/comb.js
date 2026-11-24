/* Module 1.3 widget: 3-bit ripple-carry adder built from full adders */
'use strict';

(function () {
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text !== undefined) e.textContent = text;
    return e;
  }

  document.addEventListener('DOMContentLoaded', function () {
    var host = document.getElementById('adder-widget');
    if (!host) return;
    var a = [0, 0, 0], b = [0, 0, 0];        // index 0 = least significant bit
    var grid = host.querySelector('#adder-grid');
    var info = host.querySelector('#adder-info');

    function render() {
      var cin = 0, sum = [], cout = [], c = [0];      // c[i] = carry INTO bit i
      for (var i = 0; i < 3; i++) {
        var t = a[i] + b[i] + cin;
        sum[i] = t & 1; cout[i] = t >> 1; cin = cout[i]; c[i + 1] = cin;
      }
      grid.textContent = '';
      // columns: bit 2, bit 1, bit 0 (left to right), like writing the numbers on paper
      [2, 1, 0].forEach(function (i) {
        var col = el('div', 'fa-col');
        col.appendChild(el('div', 'fa-head', 'bit ' + i));
        var ba = el('button', 'bit-btn', 'a' + i + ' = ' + a[i]); ba.type = 'button'; ba.setAttribute('aria-pressed', a[i] ? 'true' : 'false');
        var bb = el('button', 'bit-btn', 'b' + i + ' = ' + b[i]); bb.type = 'button'; bb.setAttribute('aria-pressed', b[i] ? 'true' : 'false');
        ba.addEventListener('click', function () { a[i] ^= 1; render(); });
        bb.addEventListener('click', function () { b[i] ^= 1; render(); });
        col.appendChild(ba); col.appendChild(bb);
        var cell = el('div', 'fa-cell');
        cell.appendChild(el('div', 'fa-lbl', 'full adder'));
        cell.appendChild(el('div', 'fa-eq', a[i] + ' + ' + b[i] + ' + ' + c[i] + ' (carry in)'));
        cell.appendChild(el('div', 'fa-res', '= sum ' + sum[i] + ', carry out ' + cout[i]));
        col.appendChild(cell);
        col.appendChild(el('div', 'fa-sum' + (sum[i] ? ' on' : ''), 'sum' + i + ' = ' + sum[i]));
        col.appendChild(el('div', 'fa-carry' + (cout[i] ? ' on' : ''), i === 2 ? 'cout = ' + cout[i] : 'carry to bit ' + (i + 1) + ' = ' + cout[i]));
        grid.appendChild(col);
      });
      var A = a[0] + 2 * a[1] + 4 * a[2], B = b[0] + 2 * b[1] + 4 * b[2];
      var S = sum[0] + 2 * sum[1] + 4 * sum[2] + 8 * cout[2];
      info.textContent = A + ' + ' + B + ' = ' + S + '   (as {cout, sum} = 4\'b' +
        cout[2] + sum[2] + sum[1] + sum[0] + '). The carry travels from bit 0 to bit 2: a "ripple".';
    }
    render();
  });
})();
