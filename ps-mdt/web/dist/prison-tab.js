(() => {
  const RESOURCE = (window.GetParentResourceName && window.GetParentResourceName()) || 'ps-mdt';
  const state = {
    auth: null,
    permissions: [],
    config: { prisons: [] },
    selected: null,
    status: null,
    records: [],
    active: false,
    busy: false,
  };

  const selectors = {
    nav: '.mdt-navigation',
    main: '.mdt-main-content',
  };

  function hasAccess() {
    const auth = state.auth || {};
    return auth.authorized === true && auth.onDuty === true && (auth.jobType === 'leo' || auth.isLEO === true);
  }

  async function fetchNui(endpoint, payload = {}) {
    const response = await fetch(`https://${RESOURCE}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload || {}),
    });
    return response.json();
  }

  function notify(message, type = 'info') {
    renderBanner(message, type);
  }

  async function refreshAccessState() {
    try {
      const [auth, permissions, config] = await Promise.all([
        fetchNui('checkAuth', {}),
        fetchNui('getMyPermissions', {}),
        fetchNui('getPrisonConfig', {}),
      ]);
      state.auth = auth || null;
      state.permissions = permissions && Array.isArray(permissions.permissions) ? permissions.permissions : [];
      state.config = config && config.success ? config : { success: false, prisons: [] };
    } catch (error) {
      console.error('[ps-mdt][prison-tab] access refresh failed', error);
    }
  }

  function createNavButton() {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'psmdt-prison-nav-btn';
    button.id = 'psmdt-prison-nav-btn';
    button.innerHTML = '<span class="material-icons">account_balance</span><span>Prisão</span>';
    button.addEventListener('click', async (event) => {
      event.preventDefault();
      event.stopPropagation();
      await refreshAccessState();
      if (!hasAccess()) {
        notify('Você precisa estar em serviço e autorizado para usar a aba Prisão.', 'error');
        return;
      }
      activatePrisonTab();
    });
    return button;
  }

  function buildPage() {
    const page = document.createElement('section');
    page.id = 'psmdt-prison-page';
    page.className = 'psmdt-prison-page';
    page.innerHTML = `
      <div class="psmdt-prison-shell">
        <div class="psmdt-prison-card">
          <div class="psmdt-prison-topbar">
            <div>
              <h2>Prisão</h2>
              <p class="psmdt-prison-muted">Painel direto do <strong>pickle_prisons</strong> dentro do ps-mdt.</p>
            </div>
            <span class="psmdt-prison-badge" id="psmdt-prison-access-badge">Aguardando</span>
          </div>

          <div class="psmdt-prison-search">
            <input id="psmdt-prison-search-input" class="psmdt-prison-input" type="text" placeholder="Buscar por nome ou citizenid" />
            <button id="psmdt-prison-search-btn" class="psmdt-prison-btn primary" type="button">Buscar</button>
          </div>

          <div id="psmdt-prison-results" class="psmdt-prison-results">
            <div class="psmdt-prison-empty">Busque um cidadão para consultar ou gerenciar a prisão.</div>
          </div>
        </div>

        <div class="psmdt-prison-card">
          <div class="psmdt-prison-topbar">
            <div>
              <h3 id="psmdt-prison-target-name">Nenhum alvo selecionado</h3>
              <p id="psmdt-prison-target-meta" class="psmdt-prison-muted">Selecione um cidadão na lista para carregar o status real do pickle_prisons.</p>
            </div>
            <button id="psmdt-prison-refresh-btn" class="psmdt-prison-btn secondary" type="button">Atualizar dados</button>
          </div>

          <div class="psmdt-prison-grid">
            <label>
              <span class="psmdt-prison-muted">Unidade / prisão</span>
              <select id="psmdt-prison-select" class="psmdt-prison-select"></select>
            </label>
            <label>
              <span class="psmdt-prison-muted">Tempo (minutos)</span>
              <input id="psmdt-prison-time" class="psmdt-prison-input" type="number" min="1" step="1" placeholder="30" />
            </label>
          </div>

          <div style="margin-top:0.85rem;">
            <label>
              <span class="psmdt-prison-muted">Motivo / observação do MDT</span>
              <textarea id="psmdt-prison-reason" class="psmdt-prison-textarea" placeholder="Ex.: flagrante, cumprimento de sentença, ajuste de tempo..."></textarea>
            </label>
          </div>

          <div class="psmdt-prison-actions" style="margin-top:1rem;">
            <button id="psmdt-prison-jail-btn" class="psmdt-prison-btn primary" type="button">Prender</button>
            <button id="psmdt-prison-status-btn" class="psmdt-prison-btn secondary" type="button">Consultar situação</button>
            <button id="psmdt-prison-add-btn" class="psmdt-prison-btn warn" type="button">Adicionar tempo</button>
            <button id="psmdt-prison-reduce-btn" class="psmdt-prison-btn secondary" type="button">Reduzir tempo</button>
            <button id="psmdt-prison-release-btn" class="psmdt-prison-btn danger" type="button">Soltar preso</button>
          </div>

          <div class="psmdt-prison-stat-grid">
            <div class="psmdt-prison-stat">
              <span class="psmdt-prison-stat-label">Status atual</span>
              <span id="psmdt-prison-stat-status" class="psmdt-prison-stat-value">Não consultado</span>
            </div>
            <div class="psmdt-prison-stat">
              <span class="psmdt-prison-stat-label">Tempo restante</span>
              <span id="psmdt-prison-stat-time" class="psmdt-prison-stat-value">--</span>
            </div>
            <div class="psmdt-prison-stat">
              <span class="psmdt-prison-stat-label">Prisão configurada</span>
              <span id="psmdt-prison-stat-prison" class="psmdt-prison-stat-value">--</span>
            </div>
            <div class="psmdt-prison-stat">
              <span class="psmdt-prison-stat-label">Disponibilidade</span>
              <span id="psmdt-prison-stat-online" class="psmdt-prison-stat-value">--</span>
            </div>
          </div>

          <div id="psmdt-prison-banner" class="psmdt-prison-status-banner info">A aba Prisão usa as funções reais do pickle_prisons. Sem lógica paralela.</div>
        </div>
      </div>
    `;

    bindPageEvents(page);
    return page;
  }

  function getPage() {
    let page = document.getElementById('psmdt-prison-page');
    if (!page) {
      const main = document.querySelector(selectors.main);
      if (!main) return null;
      page = buildPage();
      main.appendChild(page);
    }
    return page;
  }

  function bindPageEvents(page) {
    page.querySelector('#psmdt-prison-search-btn')?.addEventListener('click', searchRecords);
    page.querySelector('#psmdt-prison-search-input')?.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') searchRecords();
    });
    page.querySelector('#psmdt-prison-refresh-btn')?.addEventListener('click', () => runAction('refresh'));
    page.querySelector('#psmdt-prison-status-btn')?.addEventListener('click', () => runAction('status'));
    page.querySelector('#psmdt-prison-jail-btn')?.addEventListener('click', () => runAction('jail'));
    page.querySelector('#psmdt-prison-add-btn')?.addEventListener('click', () => runAction('add_time'));
    page.querySelector('#psmdt-prison-reduce-btn')?.addEventListener('click', () => runAction('reduce_time'));
    page.querySelector('#psmdt-prison-release-btn')?.addEventListener('click', () => runAction('release'));
  }

  function ensureNavButton() {
    const nav = document.querySelector(selectors.nav);
    if (!nav) return;
    if (!hasAccess()) {
      const current = document.getElementById('psmdt-prison-nav-btn');
      if (current) current.remove();
      deactivatePrisonTab();
      return;
    }
    if (!document.getElementById('psmdt-prison-nav-btn')) {
      nav.appendChild(createNavButton());
    }
  }

  function hideDefaultMainContent() {
    const main = document.querySelector(selectors.main);
    if (!main) return;
    Array.from(main.children).forEach((child) => {
      if (child.id === 'psmdt-prison-page') return;
      if (!child.dataset.psmdtOriginalDisplay) {
        child.dataset.psmdtOriginalDisplay = child.style.display || '';
      }
      child.style.display = 'none';
    });
  }

  function restoreDefaultMainContent() {
    const main = document.querySelector(selectors.main);
    if (!main) return;
    Array.from(main.children).forEach((child) => {
      if (child.id === 'psmdt-prison-page') return;
      child.style.display = child.dataset.psmdtOriginalDisplay || '';
    });
  }

  function setButtonActive(active) {
    const button = document.getElementById('psmdt-prison-nav-btn');
    if (button) button.classList.toggle('active', !!active);
  }

  async function activatePrisonTab() {
    const page = getPage();
    if (!page) return;
    state.active = true;
    hideDefaultMainContent();
    page.classList.add('active');
    setButtonActive(true);
    await loadConfigIntoPage();
    renderSelected();
  }

  function deactivatePrisonTab() {
    state.active = false;
    const page = document.getElementById('psmdt-prison-page');
    if (page) page.classList.remove('active');
    restoreDefaultMainContent();
    setButtonActive(false);
  }

  async function loadConfigIntoPage() {
    const badge = document.getElementById('psmdt-prison-access-badge');
    if (badge) {
      badge.textContent = hasAccess() ? 'Acesso liberado' : 'Sem acesso';
    }

    const select = document.getElementById('psmdt-prison-select');
    if (!select) return;
    select.innerHTML = '';

    const prisons = Array.isArray(state.config?.prisons) ? state.config.prisons : [];
    if (!prisons.length) {
      const option = document.createElement('option');
      option.value = 'default';
      option.textContent = 'default';
      select.appendChild(option);
      return;
    }

    prisons.forEach((prison, index) => {
      const option = document.createElement('option');
      option.value = prison.index || 'default';
      option.textContent = prison.label || prison.index || `Prisão ${index + 1}`;
      select.appendChild(option);
    });

    if (state.status?.prison) {
      select.value = state.status.prison;
    }
  }

  function renderBanner(message, type = 'info') {
    const banner = document.getElementById('psmdt-prison-banner');
    if (!banner) return;
    banner.className = `psmdt-prison-status-banner ${type}`;
    banner.textContent = message;
  }

  function renderRecords() {
    const container = document.getElementById('psmdt-prison-results');
    if (!container) return;
    container.innerHTML = '';

    if (!state.records.length) {
      container.innerHTML = '<div class="psmdt-prison-empty">Nenhum cidadão encontrado para essa busca.</div>';
      return;
    }

    state.records.forEach((record) => {
      const element = document.createElement('button');
      element.type = 'button';
      element.className = 'psmdt-prison-result' + (state.selected && state.selected.citizenid === record.citizenid ? ' active' : '');
      const jailed = record.status?.jailed === true;
      element.innerHTML = `
        <div class="psmdt-prison-result-meta" style="text-align:left;">
          <strong>${escapeHtml(record.fullName || record.citizenid)}</strong>
          <span class="psmdt-prison-muted">CitizenID: ${escapeHtml(record.citizenid)}</span>
        </div>
        <div style="text-align:right;">
          <div class="psmdt-prison-badge">${jailed ? 'Preso' : 'Livre'}</div>
          <div class="psmdt-prison-muted" style="margin-top:0.35rem;">${record.online ? `Online${record.source ? ` #${record.source}` : ''}` : 'Offline'}</div>
        </div>
      `;
      element.addEventListener('click', () => selectRecord(record));
      container.appendChild(element);
    });
  }

  function renderSelected() {
    const targetName = document.getElementById('psmdt-prison-target-name');
    const targetMeta = document.getElementById('psmdt-prison-target-meta');
    const statusEl = document.getElementById('psmdt-prison-stat-status');
    const timeEl = document.getElementById('psmdt-prison-stat-time');
    const prisonEl = document.getElementById('psmdt-prison-stat-prison');
    const onlineEl = document.getElementById('psmdt-prison-stat-online');
    const select = document.getElementById('psmdt-prison-select');

    if (!state.selected) {
      if (targetName) targetName.textContent = 'Nenhum alvo selecionado';
      if (targetMeta) targetMeta.textContent = 'Selecione um cidadão na lista para carregar o status real do pickle_prisons.';
      if (statusEl) statusEl.textContent = 'Não consultado';
      if (timeEl) timeEl.textContent = '--';
      if (prisonEl) prisonEl.textContent = '--';
      if (onlineEl) onlineEl.textContent = '--';
      return;
    }

    const status = state.status || state.selected.status || null;
    if (targetName) targetName.textContent = state.selected.fullName || state.selected.citizenid;
    if (targetMeta) {
      const onlineText = state.selected.online ? `Online${state.selected.source ? ` • ID ${state.selected.source}` : ''}` : 'Offline';
      targetMeta.textContent = `CitizenID: ${state.selected.citizenid} • ${onlineText}`;
    }
    if (statusEl) statusEl.textContent = status?.jailed ? 'Preso no pickle_prisons' : 'Não preso';
    if (timeEl) timeEl.textContent = status?.jailed ? `${status.time ?? 0} min` : '0 min';
    if (prisonEl) prisonEl.textContent = status?.prisonLabel || status?.prison || '--';
    if (onlineEl) onlineEl.textContent = state.selected.online ? 'Online' : 'Offline';
    if (select && status?.prison) select.value = status.prison;
  }

  async function searchRecords() {
    const input = document.getElementById('psmdt-prison-search-input');
    const query = (input?.value || '').trim();
    if (query.length < 2) {
      renderBanner('Digite ao menos 2 caracteres para buscar um cidadão.', 'warn');
      return;
    }

    setBusy(true);
    try {
      const response = await fetchNui('searchPrisonRecords', { query });
      state.records = Array.isArray(response?.data) ? response.data : [];
      renderRecords();
      renderBanner(`${state.records.length} resultado(s) carregado(s).`, 'success');
    } catch (error) {
      console.error('[ps-mdt][prison-tab] search failed', error);
      renderBanner('Falha ao buscar cidadãos para a aba Prisão.', 'error');
    } finally {
      setBusy(false);
    }
  }

  async function selectRecord(record) {
    state.selected = record;
    state.status = record.status || null;
    renderRecords();
    renderSelected();
    await runAction('status', true);
  }

  function getActionPayload(action) {
    const time = Number(document.getElementById('psmdt-prison-time')?.value || 0);
    const prison = document.getElementById('psmdt-prison-select')?.value || 'default';
    const reason = document.getElementById('psmdt-prison-reason')?.value || '';
    return {
      action,
      citizenid: state.selected?.citizenid,
      time,
      prison,
      reason,
    };
  }

  async function runAction(action, silent = false) {
    if (!state.selected?.citizenid) {
      renderBanner('Selecione um cidadão antes de executar qualquer ação.', 'warn');
      return;
    }

    const endpoint = action === 'status' || action === 'refresh' ? 'getPrisonStatus' : 'submitPrisonAction';
    const payload = action === 'status' || action === 'refresh'
      ? { citizenid: state.selected.citizenid }
      : getActionPayload(action);

    setBusy(true);
    try {
      const response = await fetchNui(endpoint, payload);
      if (!response?.success) {
        renderBanner(response?.message || 'Ação não executada.', 'error');
        return;
      }

      if (response.target) {
        state.selected = { ...state.selected, ...response.target };
      }
      if (response.status) {
        state.status = response.status;
        state.selected = { ...state.selected, status: response.status };
      }

      state.records = state.records.map((record) => record.citizenid === state.selected.citizenid
        ? { ...record, ...state.selected, status: state.status || record.status }
        : record);

      renderRecords();
      renderSelected();
      if (!silent) {
        renderBanner(response.message || 'Ação concluída com sucesso.', 'success');
      }
    } catch (error) {
      console.error('[ps-mdt][prison-tab] action failed', action, error);
      renderBanner('Falha ao executar a ação na aba Prisão.', 'error');
    } finally {
      setBusy(false);
    }
  }

  function setBusy(busy) {
    state.busy = busy;
    ['search-btn', 'refresh-btn', 'jail-btn', 'status-btn', 'add-btn', 'reduce-btn', 'release-btn'].forEach((suffix) => {
      const button = document.getElementById(`psmdt-prison-${suffix}`);
      if (button) button.disabled = busy;
    });
  }

  function escapeHtml(value) {
    return String(value ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }

  function ensureInjected() {
    ensureNavButton();
    if (state.active) {
      getPage();
      renderSelected();
    }
  }

  async function handleAuthRefresh() {
    await refreshAccessState();
    ensureInjected();
  }

  function bindGlobalEvents() {
    window.addEventListener('message', (event) => {
      const action = event?.data?.action;
      if (action === 'updateAuth') {
        state.auth = event.data.data || null;
        ensureInjected();
      }
      if (action === 'setVisible' && event?.data?.data?.visible === false) {
        deactivatePrisonTab();
      }
    });

    document.addEventListener('click', (event) => {
      const nav = document.querySelector(selectors.nav);
      const prisonButton = document.getElementById('psmdt-prison-nav-btn');
      if (!state.active || !nav || !prisonButton) return;
      if (prisonButton.contains(event.target)) return;
      if (nav.contains(event.target)) {
        deactivatePrisonTab();
      }
    }, true);
  }

  async function bootstrap() {
    bindGlobalEvents();
    await handleAuthRefresh();
    const observer = new MutationObserver(() => ensureInjected());
    observer.observe(document.body, { childList: true, subtree: true });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bootstrap, { once: true });
  } else {
    bootstrap();
  }
})();
