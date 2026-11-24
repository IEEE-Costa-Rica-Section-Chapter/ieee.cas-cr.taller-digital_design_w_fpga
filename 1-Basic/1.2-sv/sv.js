/* Module 1.2 widget: "Synthesizable or not?" */
'use strict';

(function () {
  var ITEMS = [
    { code: "assign y = a & b;",
      ans: 'synth', why: 'A continuous assignment describes a gate. It becomes one LUT input function.' },
    { code: "always #5 clk = ~clk;",
      ans: 'sim', why: 'Delays (#5) have no hardware meaning. This is how a testbench makes a clock; the FPGA gets its clock from the oscillator pin.' },
    { code: "always_ff @(posedge clk) q <= d;",
      ans: 'synth', why: 'The standard flip-flop. Every register you build in this course looks like this.' },
    { code: "$display(\"count = %0d\", count);",
      ans: 'sim', why: 'System tasks ($display, $finish, $fatal, $urandom...) exist only in simulation. Synthesis ignores or rejects them.' },
    { code: "logic [3:0] cnt = 4'd0;",
      ans: 'synth', why: 'An initial value on a register is synthesized: the FPGA starts the flip-flops at that value after loading the bitstream. That is why our designs work without a reset button.' },
    { code: "always_comb begin\n  case (s)\n    2'd0: y = 1'b1;\n    2'd1: y = 1'b0;\n  endcase\nend",
      ans: 'error', why: 'The cases s = 2 and s = 3 are missing, so y would have to remember its old value: that is a latch. Yosys stops with "Latch inferred". Add a default.' }
  ];

  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text !== undefined) e.textContent = text;
    return e;
  }

  document.addEventListener('DOMContentLoaded', function () {
    var host = document.getElementById('synth-quiz');
    if (!host) return;
    var score = el('p', 'widget-hint');
    var answered = {}, right = 0;
    ITEMS.forEach(function (it, i) {
      var box = el('div', 'synth-item');
      var pre = el('pre'); pre.className = 'synth-code'; pre.appendChild(el('code', null, it.code));
      var row = el('div', 'bit-row');
      var fb = el('div', 'quiz-fb');
      [['synth', 'Synthesizable'], ['sim', 'Simulation only'], ['error', 'Synthesis error']].forEach(function (o) {
        var b = el('button', 'bit-btn', o[1]); b.type = 'button';
        b.addEventListener('click', function () {
          if (answered[i]) return;
          answered[i] = true;
          var ok = o[0] === it.ans;
          if (ok) right++;
          b.setAttribute('aria-pressed', 'true');
          box.classList.add(ok ? 'right' : 'wrong');
          fb.textContent = (ok ? 'Correct. ' : 'Not quite. ') + it.why;
          score.textContent = right + ' of ' + Object.keys(answered).length + ' correct so far.';
        });
        row.appendChild(b);
      });
      box.appendChild(pre); box.appendChild(row); box.appendChild(fb);
      host.appendChild(box);
    });
    host.appendChild(score);
  });
})();
