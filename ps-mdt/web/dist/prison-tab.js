(() => {
  const RESOURCE = (window.GetParentResourceName && window.GetParentResourceName()) || 'ps-mdt';
  const state = {
    auth: null,
    active: false,
    targets: [],
    selected: null,
    status: null,
    busy: false,
  };

  const qs = {
    navPills: '.nav-pills',
    main: '.mdt-main-content',
  };

  async function nui(action, data = {}) {
    const response = await fetch(`https://${RESOURCE}/${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {}),
    });
    return response.json();
  }

  function canUsePrisonTab() {
    const auth = state.auth || {};
    return auth.authorized === true && auth.onDuty === true && (auth.jobType === 'leo' || auth.isLEO === true);
  }

  function getBodycamsButton() {
    const buttons = Array.from(document.querySelectorAll('.nav-pills .nav-pill'));
    return buttons.find((button) => /Bodycams/i.test(button.textContent || '')) || null;
  }

  function getAllNavButtons() {
    return Array.from(document.querySelectorAll('.nav-pills .nav-pill'));
  }

  function ensureTabButton() {
    const navPills = document.querySelector(qs.navPills);
    if (!navPills) return null;

    const existing = document.getElementById('psmdt-prison-nav');
    if (!canUsePrisonTab()) {
      existing?.remove();
      deactivateTab();
      return null;
    }

    if (existing) return existing;

    const anchor = getBodycamsButton();
    const button = document.createElement('button');
    button.id = 'psmdt-prison-nav';
    button.type = 'button';
    button.className = 'nav-pill svelte-1xdik73 psmdt-prison-nav';
    button.innerHTML = '<span class="material-icons nav-icon svelte-1xdik73">account_balance</span><span class="svelte-1xdik73">Prisão</span>';
    button.addEventListener('click', async (event) => {
      event.preventDefault();
      event.stopPropagation();
      await activateTab();
    });

    if (anchor && anchor.parentNode) {
      anchor.insertAdjacentElement('afterend', button);
    } else {
      navPills.appendChild(button);
    }

    return button;
  }

  function ensurePage() {
    const main = document.querySelector(qs.main);
    if (!main) return null;

    let page = document.getElementById('psmdt-prison-page');
    if (page) return page;

    page = document.createElement('section');
    page.id = 'psmdt-prison-page';
    page.className = 'psmdt-prison-page';
    page.innerHTML = `
      <div class="psmdt-prison-wrapper">
        <div class="psmdt-prison-header">
          <div>
            <h2>Prisão</h2>
            <p>Integração simples com o <strong>pickle_prisons</strong> usando apenas ações já existentes.</p>
          </div>
          <button id="psmdt-prison-refresh" class="psmdt-prison-button ghost" type="button">Atualizar</button>
        </div>

        <div class="psmdt-prison-toolbar">
          <input id="psmdt-prison-search" class="psmdt-prison-input" type="text" placeholder="Buscar jogador online por nome ou citizenid" />
          <input id="psmdt-prison-time" class="psmdt-prison-input small" type="number" min="1" step="1" placeholder="Tempo" />
          <button id="psmdt-prison-search-btn" class="psmdt-prison-button" type="button">Buscar</button>
        </div>

        <div class="psmdt-prison-layout">
          <div class="psmdt-prison-panel">
            <div class="psmdt-prison-panel-title">Jogadores online</div>
            <div id="psmdt-prison-results" class="psmdt-prison-results"></div>
          </div>

          <div class="psmdt-prison-panel">
            <div class="psmdt-prison-panel-title">Ações</div>
            <div id="psmdt-prison-selected" class="psmdt-prison-selected">Selecione um jogador para gerenciar a prisão.</div>
            <div class="psmdt-prison-actions">
              <button id="psmdt-prison-jail" class="psmdt-prison-button" type="button">Prender</button>
              <button id="psmdt-prison-unjail" class="psmdt-prison-button danger" type="button">Soltar preso</button>
            </div>
            <div id="psmdt-prison-status" class="psmdt-prison-status">Aguardando seleção.</div>
          </div>
        </div>
      </div>
    `;

    page.querySelector('#psmdt-prison-search-btn')?.addEventListener('click', loadTargets);
    page.querySelector('#psmdt-prison-refresh')?.addEventListener('click', refreshSelectedStatus);
    page.querySelector('#psmdt-prison-jail')?.addEventListener('click', jailSelected);
    page.querySelector('#psmdt-prison-unjail')?.addEventListener('click', unjailSelected);
    page.querySelector('#psmdt-prison-search')?.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') loadTargets();
    });

    main.appendChild(page);
    return page;
  }

  function showOnlyPrisonPage() {
    const main = document.querySelector(qs.main);
    if (!main) return;

    Array.from(main.children).forEach((child) => {
      if (child.id === 'psmdt-prison-page') {
        child.style.display = 'block';
        return;
      }
      if (!child.dataset.psmdtDisplay) child.dataset.psmdtDisplay = child.style.display || '';
      child.style.display = 'none';
    });
  }

  function restoreDefaultPages() {
    const main = document.querySelector(qs.main);
    if (!main) return;

    Array.from(main.children).forEach((child) => {
      if (child.id === 'psmdt-prison-page') {
        child.style.display = 'none';
        return;
      }
      child.style.display = child.dataset.psmdtDisplay || '';
    });
  }

  function setTabActive(active) {
    const button = document.getElementById('psmdt-prison-nav');
    if (button) button.classList.toggle('active', !!active);
  }

  function setStatus(message, type = 'info') {
    const status = document.getElementById('psmdt-prison-status');
    if (!status) return;
    status.className = `psmdt-prison-status ${type}`;
    status.textContent = message;
  }

  function renderTargets() {
    const container = document.getElementById('psmdt-prison-results');
    if (!container) return;
    container.innerHTML = '';

    if (!state.targets.length) {
      container.innerHTML = '<div class="psmdt-prison-empty">Nenhum jogador online encontrado.</div>';
      return;
    }

    state.targets.forEach((target) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = `psmdt-prison-target ${state.selected && state.selected.source === target.source ? 'active' : ''}`;
      button.innerHTML = `
        <div>
          <strong>${escapeHtml(target.fullName || 'Sem nome')}</strong>
          <span>${escapeHtml(target.citizenid || 'Sem citizenid')} • ID ${target.source}</span>
        </div>
        <div class="psmdt-prison-chip ${target.jailTime > 0 ? 'danger' : 'success'}">${target.jailTime > 0 ? `${target.jailTime} min` : 'Livre'}</div>
      `;
      button.addEventListener('click', () => selectTarget(target));
      container.appendChild(button);
    });
  }

  function renderSelected() {
    const selected = document.getElementById('psmdt-prison-selected');
    if (!selected) return;

    if (!state.selected) {
      selected.textContent = 'Selecione um jogador para gerenciar a prisão.';
      return;
    }

    selected.innerHTML = `
      <strong>${escapeHtml(state.selected.fullName || 'Sem nome')}</strong><br>
      CitizenID: ${escapeHtml(state.selected.citizenid || 'Sem citizenid')}<br>
      ID atual: ${state.selected.source}<br>
      Situação: ${escapeHtml(state.status?.status || state.selected.status || 'Livre')}${(state.status?.jailTime || 0) > 0 ? ` • ${state.status.jailTime} min restantes` : ''}
    `;
  }

  async function loadTargets() {
    const query = document.getElementById('psmdt-prison-search')?.value || '';
    setBusy(true);
    try {
      const response = await nui('getPrisonTargets', { query });
      state.targets = Array.isArray(response?.data) ? response.data : [];
      if (state.selected) {
        state.selected = state.targets.find((item) => item.source === state.selected.source) || null;
      }
      renderTargets();
      renderSelected();
      setStatus(`${state.targets.length} jogador(es) carregado(s).`, 'success');
    } catch (error) {
      console.error('[ps-mdt][prison-tab]', error);
      setStatus('Falha ao buscar jogadores online para a aba Prisão.', 'error');
    } finally {
      setBusy(false);
    }
  }

  async function selectTarget(target) {
    state.selected = target;
    renderTargets();
    await refreshSelectedStatus();
  }

  async function refreshSelectedStatus() {
    if (!state.selected?.source) {
      setStatus('Selecione um jogador para consultar a situação.', 'warning');
      renderSelected();
      return;
    }

    setBusy(true);
    try {
      const response = await nui('getPrisonTargetStatus', { source: state.selected.source });
      if (!response?.success) {
        setStatus(response?.message || 'Falha ao consultar situação do jogador.', 'error');
        return;
      }
      state.status = response.data;
      state.selected = { ...state.selected, ...response.data };
      state.targets = state.targets.map((item) => item.source === state.selected.source ? { ...item, ...response.data } : item);
      renderTargets();
      renderSelected();
      setStatus('Situação atualizada com sucesso.', 'success');
    } catch (error) {
      console.error('[ps-mdt][prison-tab]', error);
      setStatus('Falha ao consultar a situação do preso.', 'error');
    } finally {
      setBusy(false);
    }
  }

  async function jailSelected() {
    if (!state.selected?.source) {
      setStatus('Selecione um jogador antes de prender.', 'warning');
      return;
    }

    const sentence = Number(document.getElementById('psmdt-prison-time')?.value || 0);
    if (!sentence || sentence <= 0) {
      setStatus('Informe um tempo válido para a prisão.', 'warning');
      return;
    }

    setBusy(true);
    try {
      const response = await nui('prisonTabJail', { source: state.selected.source, sentence });
      setStatus(response?.message || 'Ação de prisão enviada.', response?.success ? 'success' : 'error');
      await new Promise((resolve) => setTimeout(resolve, 250));
      await refreshSelectedStatus();
    } catch (error) {
      console.error('[ps-mdt][prison-tab]', error);
      setStatus('Falha ao acionar o pickle_prisons para prender.', 'error');
    } finally {
      setBusy(false);
    }
  }

  async function unjailSelected() {
    if (!state.selected?.source) {
      setStatus('Selecione um preso antes de soltar.', 'warning');
      return;
    }

    setBusy(true);
    try {
      const response = await nui('prisonTabUnjail', { source: state.selected.source });
      setStatus(response?.message || 'Ação de soltura enviada.', response?.success ? 'success' : 'error');
      await new Promise((resolve) => setTimeout(resolve, 250));
      await refreshSelectedStatus();
    } catch (error) {
      console.error('[ps-mdt][prison-tab]', error);
      setStatus('Falha ao acionar o pickle_prisons para soltar.', 'error');
    } finally {
      setBusy(false);
    }
  }

  function setBusy(busy) {
    state.busy = busy;
    ['search-btn', 'refresh', 'jail', 'unjail'].forEach((id) => {
      const button = document.getElementById(`psmdt-prison-${id}`);
      if (button) button.disabled = busy;
    });
  }

  async function activateTab() {
    if (!canUsePrisonTab()) return;
    ensurePage();
    state.active = true;
    showOnlyPrisonPage();
    setTabActive(true);
    if (!state.targets.length) {
      await loadTargets();
    } else {
      renderTargets();
      renderSelected();
    }
  }

  function deactivateTab() {
    state.active = false;
    restoreDefaultPages();
    setTabActive(false);
  }

  function escapeHtml(value) {
    return String(value ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }

  function bindNavReset() {
    document.addEventListener('click', (event) => {
      if (!state.active) return;
      const prisonButton = document.getElementById('psmdt-prison-nav');
      if (prisonButton && prisonButton.contains(event.target)) return;
      const clickedNav = getAllNavButtons().find((button) => button.contains(event.target));
      if (clickedNav) {
        deactivateTab();
      }
    }, true);
  }

  async function refreshAuth() {
    try {
      state.auth = await nui('checkAuth', {});
    } catch (error) {
      console.error('[ps-mdt][prison-tab]', error);
    }
    ensureTabButton();
  }

  function observeUi() {
    const observer = new MutationObserver(() => ensureTabButton());
    observer.observe(document.body, { childList: true, subtree: true });
  }

  function bindMessages() {
    window.addEventListener('message', (event) => {
      if (event?.data?.action === 'updateAuth') {
        state.auth = event.data.data || null;
        ensureTabButton();
      }
      if (event?.data?.action === 'setVisible' && event?.data?.data?.visible === false) {
        deactivateTab();
      }
    });
  }

  async function bootstrap() {
    bindMessages();
    bindNavReset();
    observeUi();
    await refreshAuth();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bootstrap, { once: true });
  } else {
    bootstrap();
  }
})();
