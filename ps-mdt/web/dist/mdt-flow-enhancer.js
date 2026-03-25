(function () {
  const STORAGE_PREFIX = 'psmdt:flow:v1:';
  const MAX_RECENTS = 12;
  const MAX_HISTORY = 24;
  const MAX_FAVORITES = 10;

  const state = {
    officerKey: 'global',
    lastReportSnapshot: null,
    isMdtVisible: false,
    observerStarted: false,
    bootstrapTimer: null,
  };

  function normalize(text) {
    return (text || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
  }

  function textIncludes(el, txt) {
    return el && normalize(el.textContent || '').includes(normalize(txt));
  }

  function byText(selector, txt) {
    const nodes = Array.from(document.querySelectorAll(selector));
    return nodes.find((el) => textIncludes(el, txt));
  }

  function navTo(label) {
    const candidates = [
      ...Array.from(document.querySelectorAll('button, a, div, span')).filter((el) => {
        const t = normalize(el.textContent || '');
        return t === normalize(label) || t.includes(normalize(label));
      }),
    ];
    const target = candidates.find((el) => el.closest('button, a, [role="button"]'));
    const clickable = target ? target.closest('button, a, [role="button"]') : null;
    if (clickable) {
      clickable.click();
      return true;
    }
    return false;
  }

  function getStorageKey(scope) {
    return `${STORAGE_PREFIX}${state.officerKey}:${scope}`;
  }

  function read(scope, fallback) {
    try {
      return JSON.parse(localStorage.getItem(getStorageKey(scope))) ?? fallback;
    } catch (e) {
      return fallback;
    }
  }

  function write(scope, value) {
    localStorage.setItem(getStorageKey(scope), JSON.stringify(value));
  }

  function upsertRecent(entry) {
    const recents = read('recents', []);
    const filtered = recents.filter((x) => !(x.type === entry.type && x.ref === entry.ref));
    filtered.unshift({ ...entry, ts: Date.now() });
    write('recents', filtered.slice(0, MAX_RECENTS));
    renderWidgets();
  }

  function pushHistory(action, context) {
    const history = read('history', []);
    history.unshift({ action, context, ts: Date.now() });
    write('history', history.slice(0, MAX_HISTORY));
    renderWidgets();
  }

  function toggleFavorite(entry) {
    const favorites = read('favorites', []);
    const idx = favorites.findIndex((x) => x.type === entry.type && x.ref === entry.ref);
    if (idx >= 0) favorites.splice(idx, 1);
    else favorites.unshift(entry);
    write('favorites', favorites.slice(0, MAX_FAVORITES));
    renderWidgets();
  }

  function isFavorite(entry) {
    return read('favorites', []).some((x) => x.type === entry.type && x.ref === entry.ref);
  }

  function removeEnhancerUI() {
    const quickbar = document.getElementById('mdt-quickbar');
    if (quickbar) quickbar.remove();
    const widgets = document.getElementById('mdt-flow-widgets');
    if (widgets) widgets.remove();
    const duplicateBtn = document.getElementById('mdt-duplicate-report');
    if (duplicateBtn) duplicateBtn.remove();
  }

  function findOfficerIdentity() {
    const badges = Array.from(document.querySelectorAll('[class*="officer"], [class*="badge"], [class*="profile"], span, div'));
    const candidate = badges
      .map((el) => (el.textContent || '').trim())
      .find((txt) => /\b[A-Z]{2,5}-?\d{0,4}\b/.test(txt) || /\boficial\b/i.test(txt) || /\bcallsign\b/i.test(txt));
    const sanitized = (candidate || 'global').replace(/\s+/g, '_').slice(0, 60);
    state.officerKey = sanitized || 'global';
  }

  function createQuickBar() {
    if (document.getElementById('mdt-quickbar')) return;
    const bar = document.createElement('div');
    bar.id = 'mdt-quickbar';
    bar.innerHTML = `
      <button data-action="create-report">Criar relatório</button>
      <button data-action="search-citizen">Consultar cidadão</button>
      <button data-action="search-vehicle">Consultar veículo</button>
      <button data-action="arrest">Prender</button>
      <button data-action="warrant">Emitir mandado</button>
      <button data-action="forensics">Abrir cena forense</button>
    `;
    const app = document.querySelector('#app');
    if (!app) return;
    app.prepend(bar);

    bar.addEventListener('click', (e) => {
      const btn = e.target.closest('button[data-action]');
      if (!btn) return;
      const action = btn.dataset.action;

      if (action === 'create-report') {
        navTo('Relatórios');
        setTimeout(() => {
          const createBtn = byText('button, [role="button"]', 'Criar') || byText('button, [role="button"]', 'Novo');
          createBtn && createBtn.click();
        }, 120);
        pushHistory('Criou relatório', 'operação');
      }

      if (action === 'search-citizen') {
        navTo('Cidadãos');
        const input = document.querySelector('input[placeholder*="Buscar" i], input[placeholder*="Search" i]');
        input && input.focus();
        pushHistory('Consultou cidadão', 'consulta');
      }

      if (action === 'search-vehicle') {
        navTo('Veículos');
        const input = document.querySelector('input[placeholder*="placa" i], input[placeholder*="Buscar" i], input[placeholder*="Search" i]');
        input && input.focus();
        pushHistory('Consultou veículo', 'consulta');
      }

      if (action === 'arrest') {
        navTo('Relatórios');
        setTimeout(() => {
          const createBtn = byText('button, [role="button"]', 'Criar') || byText('button, [role="button"]', 'Novo');
          createBtn && createBtn.click();
          setTimeout(() => {
            const select = document.querySelector('select#type-select, select');
            if (select) {
              const option = Array.from(select.options || []).find((o) => normalize(o.textContent).includes('prisao'));
              if (option) {
                select.value = option.value;
                select.dispatchEvent(new Event('change', { bubbles: true }));
              }
            }
          }, 120);
        }, 100);
        pushHistory('Iniciou prisão', 'operação');
      }

      if (action === 'warrant') {
        navTo('Mandados');
        setTimeout(() => {
          const issue = byText('button, [role="button"]', 'Issue warrant') || byText('button, [role="button"]', 'Emitir') || byText('button, [role="button"]', 'Mandado');
          issue && issue.click();
        }, 120);
        pushHistory('Iniciou mandado', 'operação');
      }

      if (action === 'forensics') {
        if (!navTo('Evid') && !navTo('Casos') && !navTo('Forense')) {
          navTo('Relatórios');
        }
        pushHistory('Abriu contexto forense', 'forense');
      }
    });
  }

  function renderWidgets() {
    const app = document.querySelector('#app');
    if (!app) return;
    let wrap = document.getElementById('mdt-flow-widgets');
    if (!wrap) {
      wrap = document.createElement('div');
      wrap.id = 'mdt-flow-widgets';
      app.prepend(wrap);
    }

    const recents = read('recents', []);
    const favorites = read('favorites', []);
    const history = read('history', []);

    const renderEntry = (entry) => `
      <button class="mini-entry" data-type="${entry.type}" data-ref="${entry.ref}" data-label="${(entry.label || '').replace(/"/g, '&quot;')}">
        <span class="mini-type">${entry.type}</span>
        <span class="mini-label">${entry.label || entry.ref}</span>
        <span class="mini-pin">${isFavorite(entry) ? '★' : '☆'}</span>
      </button>
    `;

    wrap.innerHTML = `
      <div class="widget-row">
        <details open>
          <summary>Últimos consultados</summary>
          <div class="mini-list">${recents.slice(0, 6).map(renderEntry).join('') || '<span class="mini-empty">Sem consultas</span>'}</div>
        </details>
        <details>
          <summary>Favoritos fixados</summary>
          <div class="mini-list">${favorites.slice(0, 6).map(renderEntry).join('') || '<span class="mini-empty">Sem favoritos</span>'}</div>
        </details>
        <details>
          <summary>Histórico recente</summary>
          <div class="mini-list">${history.slice(0, 6).map((h) => `<span class="mini-history">${h.action} · ${h.context}</span>`).join('') || '<span class="mini-empty">Sem histórico</span>'}</div>
        </details>
      </div>
    `;

    wrap.querySelectorAll('.mini-entry').forEach((btn) => {
      btn.addEventListener('click', () => {
        const entry = {
          type: btn.dataset.type,
          ref: btn.dataset.ref,
          label: btn.dataset.label,
        };
        if (entry.type === 'citizen') {
          navTo('Cidadãos');
          const input = document.querySelector('input[placeholder*="Buscar" i], input[placeholder*="Search" i]');
          if (input) {
            input.value = entry.ref;
            input.dispatchEvent(new Event('input', { bubbles: true }));
          }
        }
        if (entry.type === 'vehicle') {
          navTo('Veículos');
          const input = document.querySelector('input[placeholder*="placa" i], input[placeholder*="Buscar" i], input[placeholder*="Search" i]');
          if (input) {
            input.value = entry.ref;
            input.dispatchEvent(new Event('input', { bubbles: true }));
          }
        }
        toggleFavorite(entry);
      });
    });
  }

  function attachDuplicateButton() {
    if (document.getElementById('mdt-duplicate-report')) return;
    const header = byText('div, h1, h2, span', 'Editar Relatório') || byText('div, h1, h2, span', 'Criar Novo Relatório');
    if (!header) return;
    const container = header.closest('div');
    if (!container) return;

    const btn = document.createElement('button');
    btn.id = 'mdt-duplicate-report';
    btn.className = 'mdt-inline-btn';
    btn.textContent = 'Duplicar relatório';
    btn.addEventListener('click', () => {
      const title = document.querySelector('input[placeholder*="Título" i]');
      const body = document.querySelector('textarea');
      state.lastReportSnapshot = {
        title: title ? title.value : '',
        body: body ? body.value : '',
      };
      const createBtn = byText('button, [role="button"]', 'Criar') || byText('button, [role="button"]', 'Novo');
      createBtn && createBtn.click();
      setTimeout(() => {
        const nextTitle = document.querySelector('input[placeholder*="Título" i]');
        const nextBody = document.querySelector('textarea');
        if (nextTitle) {
          nextTitle.value = `Cópia - ${state.lastReportSnapshot.title || 'Relatório'}`;
          nextTitle.dispatchEvent(new Event('input', { bubbles: true }));
        }
        if (nextBody) {
          nextBody.value = state.lastReportSnapshot.body || '';
          nextBody.dispatchEvent(new Event('input', { bubbles: true }));
        }
      }, 150);
      pushHistory('Duplicou relatório', 'operação');
    });
    container.appendChild(btn);
  }

  function detectRecentsFromDOM() {
    const idNode = byText('span, div', 'ID:');
    if (idNode) {
      const txt = (idNode.textContent || '').trim();
      const id = txt.split(':').pop().trim();
      if (id && id.length > 2) upsertRecent({ type: 'citizen', ref: id, label: txt });
    }

    const plateNode = document.querySelector('[class*="vehicle-plate"], [class*="plate"]');
    if (plateNode) {
      const plate = (plateNode.textContent || '').trim();
      if (plate && plate.length > 1) upsertRecent({ type: 'vehicle', ref: plate, label: plate });
    }
  }

  function simplifyForms() {
    document.querySelectorAll('details').forEach((d) => {
      if (!d.closest('#mdt-flow-widgets')) d.open = false;
    });
    document.querySelectorAll('[class*="advanced"], [class*="details"]').forEach((el) => {
      if (!el.closest('#mdt-flow-widgets')) {
        el.classList.add('mdt-collapsed');
      }
    });
  }

  function bootstrap() {
    if (!state.isMdtVisible) return;
    findOfficerIdentity();
    createQuickBar();
    renderWidgets();
    attachDuplicateButton();
    detectRecentsFromDOM();
    simplifyForms();
  }

  const obs = new MutationObserver(() => {
    if (!state.isMdtVisible) return;
    bootstrap();
  });

  function startEnhancer() {
    if (state.observerStarted) return;
    if (!document.body) return;
    state.observerStarted = true;
    obs.observe(document.body, { childList: true, subtree: true });
    state.bootstrapTimer = setInterval(() => {
      if (!state.isMdtVisible) return;
      bootstrap();
    }, 2500);
  }

  function stopEnhancer() {
    if (!state.observerStarted) {
      removeEnhancerUI();
      return;
    }
    state.observerStarted = false;
    obs.disconnect();
    if (state.bootstrapTimer) {
      clearInterval(state.bootstrapTimer);
      state.bootstrapTimer = null;
    }
    removeEnhancerUI();
  }

  function setMdtVisible(visible) {
    const next = visible === true;
    if (state.isMdtVisible === next) {
      if (next) bootstrap();
      return;
    }

    state.isMdtVisible = next;
    if (next) {
      startEnhancer();
      bootstrap();
    } else {
      stopEnhancer();
    }
  }

  function parseVisibleFromMessage(payload) {
    if (payload.action !== 'setVisible') return null;

    const data = payload.data;
    if (typeof data === 'boolean') return data;
    if (data && typeof data.visible === 'boolean') return data.visible;
    if (typeof payload.visible === 'boolean') return payload.visible;
    if (data && (data.visible === 1 || data.visible === '1' || data.visible === 'true')) return true;
    if (data && (data.visible === 0 || data.visible === '0' || data.visible === 'false')) return false;
    return null;
  }

  window.addEventListener('message', (event) => {
    const payload = event && event.data;
    if (!payload || typeof payload !== 'object') return;

    const nextVisible = parseVisibleFromMessage(payload);
    if (nextVisible !== null) {
      setMdtVisible(nextVisible);
      return;
    }

    if (state.isMdtVisible) {
      bootstrap();
    }
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      setMdtVisible(false);
    });
  } else {
    setMdtVisible(false);
  }
})();
