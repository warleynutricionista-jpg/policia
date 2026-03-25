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
        <div class="psmdt-prison-card">
          <div class="psmdt-prison-header">
            <div>
              <h2>Prisão</h2>
              <p>Integração nativa do MDT com <strong>pickle_prisons</strong> (sem sistema paralelo).</p>
            </div>
            <button id="psmdt-prison-refresh" class="psmdt-prison-button ghost" type="button">Atualizar</button>
          </div>

          <div class="psmdt-prison-toolbar">
            <input id="psmdt-prison-search" class="psmdt-prison-input" type="text" placeholder="Buscar jogador online por nome ou citizenid" />
            <input id="psmdt-prison-time" class="psmdt-prison-input small" type="number" min="1" step="1" placeholder="Tempo" />
            <input id="psmdt-prison-reason" class="psmdt-prison-input" type="text" placeholder="Motivo da prisão/alteração" />
            <button id="psmdt-prison-search-btn" class="psmdt-prison-button" type="button">Buscar</button>
          </div>
        </div>

        <div class="psmdt-prison-layout">
          <div class="psmdt-prison-panel psmdt-prison-card">
            <div class="psmdt-prison-panel-title">Jogadores online</div>
            <div id="psmdt-prison-results" class="psmdt-prison-results"></div>
          </div>

          <div class="psmdt-prison-panel psmdt-prison-card">
            <div class="psmdt-prison-panel-title">Status do preso</div>
            <div id="psmdt-prison-selected" class="psmdt-prison-selected">Selecione um jogador para gerenciar a prisão.</div>
            <div id="psmdt-prison-links" class="psmdt-prison-selected">Sem vínculo com relatório/caso.</div>
            <div class="psmdt-prison-actions">
              <button id="psmdt-prison-jail" class="psmdt-prison-button" type="button">Prender</button>
              <button id="psmdt-prison-unjail" class="psmdt-prison-button danger" type="button">Soltar preso</button>
            </div>
            <div id="psmdt-prison-status" class="psmdt-prison-status">Aguardando seleção.</div>
          </div>
        </div>

        <div class="psmdt-prison-card">
          <div class="psmdt-prison-panel-title">Ações rápidas</div>
          <div class="psmdt-prison-quick-grid">
            <div class="psmdt-prison-quick-item">
              <h4>Prender a partir do relatório</h4>
              <input id="psmdt-prison-quick-report" class="psmdt-prison-input" type="number" min="1" step="1" placeholder="Report ID" />
              <input id="psmdt-prison-quick-citizen-report" class="psmdt-prison-input" type="text" placeholder="CitizenID" />
              <button id="psmdt-prison-jail-report" class="psmdt-prison-button" type="button">Prender do relatório</button>
            </div>
            <div class="psmdt-prison-quick-item">
              <h4>Gerar prisão a partir do mandado</h4>
              <input id="psmdt-prison-quick-warrant" class="psmdt-prison-input" type="number" min="1" step="1" placeholder="Report ID do mandado" />
              <input id="psmdt-prison-quick-citizen-warrant" class="psmdt-prison-input" type="text" placeholder="CitizenID" />
              <button id="psmdt-prison-jail-warrant" class="psmdt-prison-button" type="button">Prender do mandado</button>
            </div>
          </div>
        </div>

        <div class="psmdt-prison-card">
          <div class="psmdt-prison-panel-title">Histórico de alterações de pena</div>
          <div id="psmdt-prison-history" class="psmdt-prison-history"></div>
        </div>
      </div>
    `;

    page.querySelector('#psmdt-prison-search-btn')?.addEventListener('click', loadTargets);
    page.querySelector('#psmdt-prison-refresh')?.addEventListener('click', refreshSelectedStatus);
    page.querySelector('#psmdt-prison-jail')?.addEventListener('click', jailSelected);
    page.querySelector('#psmdt-prison-unjail')?.addEventListener('click', unjailSelected);
    page.querySelector('#psmdt-prison-jail-report')?.addEventListener('click', jailFromReport);
    page.querySelector('#psmdt-prison-jail-warrant')?.addEventListener('click', jailFromWarrant);
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

  function renderHistory(history) {
    const container = document.getElementById('psmdt-prison-history');
    if (!container) return;

    if (!Array.isArray(history) || history.length === 0) {
      container.innerHTML = '<div class="psmdt-prison-empty">Nenhuma alteração de pena registrada.</div>';
      return;
    }

    container.innerHTML = history.map((item) => {
      const links = [];
      if (item.reportId) links.push(`Relatório #${item.reportId}`);
      if (item.caseId) links.push(`Caso #${item.caseId}`);
      if (item.warrantReportId) links.push(`Mandado do relatório #${item.warrantReportId}`);
      return `
        <div class="psmdt-prison-history-item">
          <div class="psmdt-prison-history-top">
            <strong>${escapeHtml(item.action || 'alteração')}</strong>
            <span>${escapeHtml(item.createdAt || '-')}</span>
          </div>
          <div>Tempo restante: <strong>${Number(item.timeAfter || 0)} min</strong></div>
          <div>Motivo: ${escapeHtml(item.reason || 'Não informado')}</div>
          <div>Aplicou: ${escapeHtml(item.appliedBy || item.changedBy || '-')}</div>
          <div>Soltou: ${escapeHtml(item.releasedBy || '-')}</div>
          <div>${escapeHtml(links.join(' • ') || 'Sem vínculo')}</div>
        </div>
      `;
    }).join('');
  }

  function renderSelected() {
    const selected = document.getElementById('psmdt-prison-selected');
    const links = document.getElementById('psmdt-prison-links');
    if (!selected || !links) return;

    if (!state.selected) {
      selected.textContent = 'Selecione um jogador para gerenciar a prisão.';
      links.textContent = 'Sem vínculo com relatório/caso.';
      renderHistory([]);
      return;
    }

    const status = state.status || {};
    selected.innerHTML = `
      <strong>${escapeHtml(state.selected.fullName || 'Sem nome')}</strong><br>
      CitizenID: ${escapeHtml(state.selected.citizenid || 'Sem citizenid')}<br>
      ID atual: ${state.selected.source || '-'}<br>
      Status atual: ${escapeHtml(status.status || state.selected.status || 'Livre')}<br>
      Tempo restante: <strong>${Number(status.jailTime || 0)} min</strong><br>
      Motivo: ${escapeHtml(status.reason || 'Não informado')}<br>
      Quem aplicou: ${escapeHtml(status.appliedBy || '-')}<br>
      Quem soltou: ${escapeHtml(status.releasedBy || '-')}
    `;

    const relation = [];
    if (status.reportId) relation.push(`Relatório #${status.reportId}`);
    if (status.caseId) relation.push(`Caso #${status.caseId}`);
    if (status.warrantReportId) relation.push(`Mandado #${status.warrantReportId}`);
    links.textContent = relation.join(' • ') || 'Sem vínculo com relatório/caso.';

    renderHistory(status.history || []);
  }

  function getReason() {
    return document.getElementById('psmdt-prison-reason')?.value || '';
  }

  function getSentence() {
    return Number(document.getElementById('psmdt-prison-time')?.value || 0);
  }

  async function loadTargets() {
    const query = document.getElementById('psmdt-prison-search')?.value || '';
    setBusy(true);
    try {
      const response = await nui('getPrisonTargets', { query });
      state.targets = Array.isArray(response?.data) ? response.data : [];
      if (state.selected) {
        state.selected = state.targets.find((item) => item.source === state.selected.source) || state.selected;
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
    document.getElementById('psmdt-prison-quick-citizen-report').value = target.citizenid || '';
    document.getElementById('psmdt-prison-quick-citizen-warrant').value = target.citizenid || '';
    renderTargets();
    await refreshSelectedStatus();
  }

  async function refreshSelectedStatus() {
    if (!state.selected?.source && !state.selected?.citizenid) {
      setStatus('Selecione um jogador para consultar a situação.', 'warning');
      renderSelected();
      return;
    }

    setBusy(true);
    try {
      let response;
      if (state.selected?.source) {
        response = await nui('getPrisonTargetStatus', { source: state.selected.source });
      } else {
        response = await nui('getPrisonStatusByCitizen', { citizenid: state.selected.citizenid });
      }

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

    const sentence = getSentence();
    if (!sentence || sentence <= 0) {
      setStatus('Informe um tempo válido para a prisão.', 'warning');
      return;
    }

    setBusy(true);
    try {
      const response = await nui('prisonTabJail', { source: state.selected.source, sentence, reason: getReason() });
      setStatus(response?.message || 'Ação de prisão enviada.', response?.success ? 'success' : 'error');
      if (response?.success) {
        state.status = response.data || state.status;
      }
      await new Promise((resolve) => setTimeout(resolve, 200));
      await loadTargets();
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
      const response = await nui('prisonTabUnjail', { source: state.selected.source, reason: getReason() });
      setStatus(response?.message || 'Ação de soltura enviada.', response?.success ? 'success' : 'error');
      if (response?.success) {
        state.status = response.data || state.status;
      }
      await new Promise((resolve) => setTimeout(resolve, 200));
      await loadTargets();
      await refreshSelectedStatus();
    } catch (error) {
      console.error('[ps-mdt][prison-tab]', error);
      setStatus('Falha ao acionar o pickle_prisons para soltar.', 'error');
    } finally {
      setBusy(false);
    }
  }

  async function jailFromReport() {
    const reportId = Number(document.getElementById('psmdt-prison-quick-report')?.value || 0);
    const citizenid = (document.getElementById('psmdt-prison-quick-citizen-report')?.value || '').trim();
    const sentence = getSentence();

    if (!reportId || !citizenid || !sentence) {
      setStatus('Informe reportId, citizenID e tempo para prender do relatório.', 'warning');
      return;
    }

    setBusy(true);
    try {
      const response = await nui('prisonFromReport', { reportId, citizenid, sentence, reason: getReason() });
      setStatus(response?.message || 'Ação de prisão via relatório enviada.', response?.success ? 'success' : 'error');
      if (response?.success) {
        state.selected = { ...(state.selected || {}), citizenid, source: response?.data?.source, fullName: response?.data?.fullName || state?.selected?.fullName };
        state.status = response.data || null;
      }
      await loadTargets();
      await refreshSelectedStatus();
    } catch (error) {
      console.error('[ps-mdt][prison-tab]', error);
      setStatus('Falha ao prender a partir do relatório.', 'error');
    } finally {
      setBusy(false);
    }
  }

  async function jailFromWarrant() {
    const reportId = Number(document.getElementById('psmdt-prison-quick-warrant')?.value || 0);
    const citizenid = (document.getElementById('psmdt-prison-quick-citizen-warrant')?.value || '').trim();
    const sentence = getSentence();

    if (!reportId || !citizenid || !sentence) {
      setStatus('Informe reportId do mandado, citizenID e tempo para prender do mandado.', 'warning');
      return;
    }

    setBusy(true);
    try {
      const response = await nui('prisonFromWarrant', { reportId, citizenid, sentence, reason: getReason() });
      setStatus(response?.message || 'Ação de prisão via mandado enviada.', response?.success ? 'success' : 'error');
      if (response?.success) {
        state.selected = { ...(state.selected || {}), citizenid, source: response?.data?.source, fullName: response?.data?.fullName || state?.selected?.fullName };
        state.status = response.data || null;
      }
      await loadTargets();
      await refreshSelectedStatus();
    } catch (error) {
      console.error('[ps-mdt][prison-tab]', error);
      setStatus('Falha ao gerar prisão a partir do mandado.', 'error');
    } finally {
      setBusy(false);
    }
  }

  function setBusy(busy) {
    state.busy = busy;
    ['search-btn', 'refresh', 'jail', 'unjail', 'jail-report', 'jail-warrant'].forEach((id) => {
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
