/* ============================================================
   Digital Design with FPGA - shared course script
   - theme toggle, step sidebar, progress, OS tabs, copy buttons
   - persistent checklists, quiz, module completion
   Classic script (no modules, no fetch): works over file://
   Page contract: window.ROOT (path to repo root), window.MODULE
     { id: '0', title: '...', steps: [{id, num, title}], nextHref?, nextTitle? }
   ============================================================ */
'use strict';

(function () {
  var PREFIX = 'ddfpga:';
  var mem = {};                       // fallback when localStorage is blocked

  function load(key, dflt) {
    try {
      var v = window.localStorage.getItem(PREFIX + key);
      return v === null ? dflt : v;
    } catch (e) {
      return Object.prototype.hasOwnProperty.call(mem, key) ? mem[key] : dflt;
    }
  }
  function save(key, val) {
    mem[key] = String(val);
    try { window.localStorage.setItem(PREFIX + key, String(val)); } catch (e) { /* ignore */ }
  }
  window.CourseStore = { load: load, save: save };

  /* ---------- SystemVerilog for highlight.js ---------- */
  function registerSV() {
    if (typeof hljs === 'undefined') return;
    hljs.registerLanguage('systemverilog', function (h) {
      return {
        name: 'SystemVerilog',
        aliases: ['sv', 'verilog'],
        keywords: {
          keyword: 'module endmodule input output inout logic wire reg parameter localparam int integer ' +
            'bit byte always_ff always_comb always_latch always assign if else begin end case endcase ' +
            'default for generate endgenerate genvar posedge negedge initial typedef enum struct packed ' +
            'function endfunction task endtask interface endinterface package endpackage import unique ' +
            'priority return repeat while forever timescale'
        },
        contains: [
          h.C_LINE_COMMENT_MODE,
          h.C_BLOCK_COMMENT_MODE,
          h.QUOTE_STRING_MODE,
          { className: 'built-in', begin: '\\$\\w+' },
          { className: 'meta', begin: '`\\w+' },
          { className: 'number',
            begin: "\\b\\d*'[sS]?[bBoOdDhH][0-9a-fA-FxXzZ_]+|'[01xXzZ]\\b|\\b\\d[\\d_]*\\b" }
        ]
      };
    });
  }

  /* ---------- theme ---------- */
  function getTheme() { return load('theme', 'dark'); }
  function applyTheme(t) {
    document.documentElement.setAttribute('data-theme', t);
    save('theme', t);
    var d = document.getElementById('hljs-dark-css');
    var l = document.getElementById('hljs-light-css');
    if (d) d.disabled = (t !== 'dark');
    if (l) l.disabled = (t !== 'light');
    var b = document.getElementById('theme-toggle');
    if (b) b.textContent = (t === 'dark') ? '☀' : '☾';
  }

  /* ---------- progress model ---------- */
  var M = window.MODULE || { id: 'x', steps: [] };

  function checks(scope) {
    return Array.prototype.slice.call((scope || document).querySelectorAll('input[data-check]'));
  }
  function required(scope) {
    return checks(scope).filter(function (c) { return !c.hasAttribute('data-optional'); });
  }
  function stepDone(stepEl) {
    var req = required(stepEl);
    return req.length > 0 && req.every(function (c) { return c.checked; });
  }
  function quizPassed() { return load(M.id + ':quiz', '0') === '1'; }
  function moduleDone() { return load(M.id + ':complete', '0') === '1'; }

  function refreshProgress() {
    var steps = Array.prototype.slice.call(document.querySelectorAll('section.step[data-checks]'));
    var done = 0;
    steps.forEach(function (s) {
      var d = stepDone(s);
      if (d) done++;
      var li = document.querySelector('.sidebar-steps li[data-step="' + s.id + '"]');
      if (li) li.classList.toggle('done', d);
    });
    var total = steps.length;
    var fill = document.getElementById('progress-fill');
    var label = document.getElementById('progress-label');
    if (fill) fill.style.width = (total ? Math.round(100 * done / total) : 0) + '%';
    if (label) label.textContent = done + ' of ' + total + ' steps checked off';

    var allReq = required();
    var checked = allReq.filter(function (c) { return c.checked; }).length;
    var btn = document.getElementById('complete-btn');
    var req = document.getElementById('complete-req');
    var ready = checked === allReq.length && quizPassed();
    if (btn) btn.disabled = !(ready || moduleDone());
    if (req) {
      var miss = [];
      if (checked !== allReq.length) miss.push((allReq.length - checked) + ' checklist item(s) left');
      if (!quizPassed()) miss.push('quiz not passed yet');
      req.textContent = miss.length ? 'Still needed: ' + miss.join(', ') + '.' : 'Everything is in place.';
    }
    var box = document.getElementById('complete-box');
    if (box) box.classList.toggle('done', moduleDone());
    var msg = document.getElementById('complete-msg');
    if (msg) msg.hidden = !moduleDone();
  }

  /* ---------- sidebar ---------- */
  function buildSidebar() {
    var sb = document.getElementById('sidebar');
    if (!sb) return;
    var root = window.ROOT || '';
    var html = '<div class="sidebar-logo"><a href="' + root + 'index.html">Digital Design with FPGA</a></div>' +
      '<div class="sidebar-subtitle">Tang Nano 20K &nbsp;&middot;&nbsp; SystemVerilog</div>' +
      (M.hideProgress ? '' :
        '<div class="sidebar-progress"><span id="progress-label"></span>' +
        '<div class="progress-bar-track"><div class="progress-bar-fill" id="progress-fill"></div></div></div>') +
      '<ul class="sidebar-steps">';
    (M.steps || []).forEach(function (s) {
      html += '<li data-step="' + (s.id || '') + '"><a href="' + (s.href || '#' + s.id) + '"><span class="st-num">' + s.num +
        '</span><span>' + s.title + '</span></a></li>';
    });
    html += '</ul><div class="sidebar-footer"><a href="' + root + 'index.html" class="sidebar-home">&larr; Course home</a></div>';
    sb.innerHTML = html;

    // highlight the step being read
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) {
            var links = sb.querySelectorAll('.sidebar-steps a');
            Array.prototype.forEach.call(links, function (a) {
              a.classList.toggle('current', a.getAttribute('href') === '#' + e.target.id);
            });
          }
        });
      }, { rootMargin: '-15% 0px -75% 0px' });
      Array.prototype.forEach.call(document.querySelectorAll('section.step'), function (s) { io.observe(s); });
    }
    sb.addEventListener('click', function (e) {
      if (e.target.closest && e.target.closest('a')) sb.classList.remove('open');
    });
  }

  /* ---------- checklists ---------- */
  function initChecks() {
    checks().forEach(function (c) {
      var key = M.id + ':check:' + c.getAttribute('data-check');
      c.checked = load(key, '0') === '1';
      c.addEventListener('change', function () {
        save(key, c.checked ? '1' : '0');
        refreshProgress();
      });
    });
  }

  /* ---------- OS tabs ---------- */
  function detectOS() {
    var p = (navigator.userAgent || '') + ' ' + (navigator.platform || '');
    if (/Win/i.test(p)) return 'win';
    if (/Mac/i.test(p)) return 'mac';
    return 'linux';
  }
  function initOSTabs() {
    var groups = document.querySelectorAll('[data-os-tabs]');
    var os = load('os', detectOS());
    function select(which) {
      save('os', which);
      Array.prototype.forEach.call(document.querySelectorAll('[data-os-tabs] button'), function (b) {
        b.setAttribute('aria-selected', b.getAttribute('data-os') === which ? 'true' : 'false');
      });
      Array.prototype.forEach.call(document.querySelectorAll('.os-content'), function (p) {
        p.classList.toggle('active', p.getAttribute('data-os') === which);
      });
    }
    Array.prototype.forEach.call(groups, function (g) {
      Array.prototype.forEach.call(g.querySelectorAll('button'), function (b) {
        b.addEventListener('click', function () { select(b.getAttribute('data-os')); });
      });
    });
    if (groups.length) select(os);
  }

  /* ---------- copy buttons ---------- */
  function initCopy() {
    Array.prototype.forEach.call(document.querySelectorAll('.code-wrapper[data-copy] > pre'), function (pre) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'copy-btn';
      btn.textContent = 'Copy';
      btn.addEventListener('click', function () {
        var text = pre.innerText.replace(/\n$/, '');
        function ok() {
          btn.textContent = 'Copied'; btn.classList.add('copied');
          setTimeout(function () { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 1400);
        }
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(ok, function () { fallbackCopy(text); ok(); });
        } else { fallbackCopy(text); ok(); }
      });
      pre.parentNode.insertBefore(btn, pre);
    });
  }
  function fallbackCopy(text) {
    var t = document.createElement('textarea');
    t.value = text; t.style.position = 'fixed'; t.style.opacity = '0';
    document.body.appendChild(t); t.select();
    try { document.execCommand('copy'); } catch (e) { /* ignore */ }
    document.body.removeChild(t);
  }

  /* ---------- annotated lines ---------- */
  function initAnnot() {
    Array.prototype.forEach.call(document.querySelectorAll('.annot-line'), function (b) {
      b.setAttribute('aria-expanded', 'false');
      b.addEventListener('click', function () {
        b.setAttribute('aria-expanded', b.getAttribute('aria-expanded') === 'true' ? 'false' : 'true');
      });
    });
  }

  /* ---------- quiz ---------- */
  function initQuiz() {
    var btn = document.getElementById('quiz-check');
    if (!btn) return;
    var qs = Array.prototype.slice.call(document.querySelectorAll('.quiz-q'));
    btn.addEventListener('click', function () {
      var right = 0, answered = 0;
      qs.forEach(function (q, i) {
        var sel = q.querySelector('input[type=radio]:checked');
        var fb = q.querySelector('.quiz-fb');
        Array.prototype.forEach.call(q.querySelectorAll('label'), function (l) { l.classList.remove('right', 'wrong'); });
        if (!sel) { fb.textContent = 'Pick an answer.'; return; }
        answered++;
        var ok = sel.value === q.getAttribute('data-answer');
        sel.parentNode.classList.add(ok ? 'right' : 'wrong');
        fb.textContent = ok ? 'Correct. ' + q.getAttribute('data-explain') : 'Not quite. Re-read the step and try again.';
        if (ok) right++;
      });
      var res = document.getElementById('quiz-result');
      if (answered < qs.length) {
        res.textContent = 'Answer every question first (' + answered + '/' + qs.length + ').';
      } else {
        res.textContent = right + ' / ' + qs.length + ' correct' + (right === qs.length ? ' - quiz passed.' : '.');
        save(M.id + ':quiz', right === qs.length ? '1' : '0');
      }
      refreshProgress();
    });
    if (quizPassed()) {
      var res = document.getElementById('quiz-result');
      if (res) res.textContent = 'Quiz passed.';
    }
  }

  /* ---------- completion ---------- */
  function initComplete() {
    var btn = document.getElementById('complete-btn');
    if (!btn) return;
    btn.addEventListener('click', function () {
      save(M.id + ':complete', '1');
      refreshProgress();
    });
    var reset = document.getElementById('reset-btn');
    if (reset) reset.addEventListener('click', function () {
      if (!window.confirm('Reset all progress for this module?')) return;
      checks().forEach(function (c) { c.checked = false; save(M.id + ':check:' + c.getAttribute('data-check'), '0'); });
      save(M.id + ':quiz', '0'); save(M.id + ':complete', '0');
      Array.prototype.forEach.call(document.querySelectorAll('.quiz-q input:checked'), function (i) { i.checked = false; });
      Array.prototype.forEach.call(document.querySelectorAll('.quiz-q label'), function (l) { l.classList.remove('right', 'wrong'); });
      Array.prototype.forEach.call(document.querySelectorAll('.quiz-fb'), function (f) { f.textContent = ''; });
      var res = document.getElementById('quiz-result'); if (res) res.textContent = '';
      refreshProgress();
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    registerSV();
    applyTheme(getTheme());
    buildSidebar();
    initChecks();
    initOSTabs();
    initCopy();
    initAnnot();
    initQuiz();
    initComplete();
    refreshProgress();

    var tb = document.getElementById('theme-toggle');
    if (tb) tb.addEventListener('click', function () { applyTheme(getTheme() === 'dark' ? 'light' : 'dark'); });
    var mt = document.getElementById('menu-toggle');
    var sb = document.getElementById('sidebar');
    if (mt && sb) {
      mt.addEventListener('click', function () { sb.classList.toggle('open'); });
      document.addEventListener('click', function (e) {
        if (sb.classList.contains('open') && !sb.contains(e.target) && e.target !== mt) sb.classList.remove('open');
      });
    }
    if (typeof hljs !== 'undefined') hljs.highlightAll();
  });
})();
