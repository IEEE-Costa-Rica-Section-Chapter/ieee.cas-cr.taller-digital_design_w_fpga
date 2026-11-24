/* Module 0 widgets: build-flow explorer and blink calculator */
'use strict';

(function () {
  /* ---------------------------------------------------------- flow ---- */
  var FLOWS = {
    hw: [
      { file: 'src/*.sv' },
      { tool: 'yosys', title: 'yosys - synthesis',
        what: 'Reads your SystemVerilog and turns it into a netlist of FPGA primitives (LUT4, flip-flops, carry ALUs, ...). It decides WHAT hardware exists, not where it sits.',
        input: 'src/*.sv', output: 'build/top.json', look: 'build/yosys.log (cell counts, warnings about latches or unused signals)',
        cmd: 'synth_gowin -top top -family gw2a -json build/top.json' },
      { file: 'top.json' },
      { tool: 'nextpnr', title: 'nextpnr-himbaechel - place & route',
        what: 'Chooses which physical LUT / flip-flop / pin every cell uses (placement), connects them through the routing fabric (routing), obeys your .cst pin assignments, and checks timing against the clock target.',
        input: 'build/top.json + constraints/*.cst', output: 'build/top_pnr.json',
        look: 'Resource usage table and the "Max frequency" line (PASS/FAIL at 27 MHz)',
        cmd: 'nextpnr-himbaechel --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=... --freq 27' },
      { file: 'top_pnr.json' },
      { tool: 'gowin_pack', title: 'gowin_pack - bitstream',
        what: 'Translates the placed-and-routed design into the configuration bits of the GW2AR-18 chip (what every LUT stores, which switches are closed).',
        input: 'build/top_pnr.json', output: 'build/top.fs (about 4.5 MB)', look: 'Nothing to read: it either produces the file or fails',
        cmd: 'gowin_pack -d GW2A-18C -o build/top.fs build/top_pnr.json' },
      { file: 'top.fs' },
      { tool: 'openFPGALoader', title: 'openFPGALoader - programming',
        what: 'Sends the bitstream over USB to the on-board BL616 chip, which drives the FPGA JTAG port. "prog" loads it into SRAM (instant, lost at power-off). "flash" stores it in the SPI flash (kept).',
        input: 'build/top.fs', output: 'A configured FPGA', look: 'Messages like "Load SRAM: [====] 100%" / "Done"',
        cmd: 'openFPGALoader -b tangnano20k build/top.fs     (add -f to write flash)' },
      { file: 'Tang Nano 20K' }
    ],
    sim: [
      { file: 'tb/*_tb.sv + src/*.sv' },
      { tool: 'iverilog', title: 'iverilog - compile',
        what: 'Compiles design and testbench together into a simulation program. Catches syntax errors and many mistakes before any hardware is involved.',
        input: 'tb/<name>_tb.sv, src/*.sv', output: 'build/<name>_tb.vvp', look: 'Errors and warnings with file:line',
        cmd: 'iverilog -g2012 -Wall -s blink_tb -o build/blink_tb.vvp tb/blink_tb.sv src/*.sv' },
      { file: 'blink_tb.vvp' },
      { tool: 'vvp', title: 'vvp - run the simulation',
        what: 'Executes the simulation. Your testbench drives inputs, checks outputs, prints PASS or calls $fatal, and writes every signal over time into a waveform file.',
        input: 'build/<name>_tb.vvp', output: 'PASS / FAIL + build/<name>_tb.vcd', look: 'The word PASS, or the FATAL message with the time it failed',
        cmd: 'vvp build/blink_tb.vvp' },
      { file: 'blink_tb.vcd' },
      { tool: 'surfer', title: 'Surfer / GTKWave - waveform viewer',
        what: 'Shows signals as waveforms so you can see what the hardware does cycle by cycle. This is how you debug when a testbench fails.',
        input: 'build/<name>_tb.vcd', output: '(your eyes)', look: 'clk, counter and out: does out toggle where you expect?',
        cmd: 'make wave' }
    ]
  };

  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text !== undefined) e.textContent = text;
    return e;
  }

  function buildFlow(host) {
    var items = FLOWS[host.getAttribute('data-flow')];
    var row = el('div', 'flow-row');
    var detail = el('div', 'flow-detail');
    var buttons = [];

    function show(it, btn) {
      buttons.forEach(function (b) { b.setAttribute('aria-pressed', b === btn ? 'true' : 'false'); });
      detail.textContent = '';
      detail.appendChild(el('h4', null, it.title));
      detail.appendChild(el('p', null, it.what));
      var dl = el('dl');
      [['Input', it.input], ['Output', it.output], ['Look at', it.look], ['Command', it.cmd]].forEach(function (kv) {
        dl.appendChild(el('dt', null, kv[0]));
        var dd = el('dd');
        if (kv[0] === 'Command') dd.appendChild(el('code', null, kv[1])); else dd.textContent = kv[1];
        dl.appendChild(dd);
      });
      detail.appendChild(dl);
    }

    items.forEach(function (it, i) {
      if (i > 0) row.appendChild(el('span', 'flow-arrow', '→'));
      if (it.file) {
        row.appendChild(el('div', 'flow-file', it.file));
      } else {
        var b = el('button', 'flow-tool', it.tool);
        b.type = 'button';
        b.setAttribute('aria-pressed', 'false');
        b.addEventListener('click', function () { show(it, b); });
        buttons.push(b);
        row.appendChild(b);
      }
    });
    host.appendChild(row);
    host.appendChild(detail);
    detail.appendChild(el('p', null, 'Click a tool to see what it does.'));
  }

  /* ----------------------------------------------------- calculator ---- */
  var HZ = [1, 2, 4, 5, 10, 50, 100, 1000];

  function initCalc(root) {
    var slider = root.querySelector('#calc-hz');
    var clkSel = root.querySelector('#calc-clk');
    var out = {
      hz: root.querySelector('#out-hz'), half: root.querySelector('#out-half'),
      w: root.querySelector('#out-w'), ms: root.querySelector('#out-ms'),
      led: root.querySelector('#out-led'), note: root.querySelector('#out-note')
    };
    var led0 = root.querySelector('#led0');
    var timer = null, state = 0;

    function clog2(n) { var w = 0; while ((1 << w) < n && w < 40) w++; return w; }  // n fits 31 bits here

    function update() {
      var hz = HZ[Number(slider.value)];
      var clk = Number(clkSel.value);
      var half = Math.floor(clk / (hz * 2));
      out.hz.textContent = hz + ' Hz';
      out.half.textContent = half.toLocaleString('en-US');
      out.w.textContent = clog2(half) + ' bits';
      out.ms.textContent = (500 / hz) + ' ms';
      if (timer) clearInterval(timer);
      state = 0;
      function paint() {
        led0.classList.toggle('on', state === 1);
        out.led.textContent = "6'b" + '11111' + (state === 1 ? '0' : '1');
      }
      paint();
      if (hz <= 10) {
        out.note.textContent = '';
        timer = setInterval(function () { state ^= 1; paint(); }, 500 / hz);
      } else {
        out.note.textContent = 'At ' + hz + ' Hz the eye cannot follow it: the LED just looks steady (and dimmer).';
        led0.classList.add('on');
        out.led.textContent = "6'b111110 / 6'b111111 (toggling)";
      }
    }
    slider.addEventListener('input', update);
    clkSel.addEventListener('change', update);
    update();
  }

  document.addEventListener('DOMContentLoaded', function () {
    Array.prototype.forEach.call(document.querySelectorAll('[data-flow]'), buildFlow);
    var c = document.getElementById('blink-calc');
    if (c) initCalc(c);
  });
})();
