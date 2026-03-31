const app = document.getElementById('app');
const roleBadge = document.getElementById('roleBadge');
const requiredCasesLabel = document.getElementById('requiredCasesLabel');
const candidatesEl = document.getElementById('candidates');
const processListEl = document.getElementById('processList');
const processDetailEl = document.getElementById('processDetail');
const inputRequiredCases = document.getElementById('inputRequiredCases');
const settingsHint = document.getElementById('settingsHint');

const modalOverlay = document.getElementById('modalOverlay');
const modalTitle = document.getElementById('modalTitle');
const modalFields = document.getElementById('modalFields');
const modalConfirm = document.getElementById('modalConfirm');
const modalCancel = document.getElementById('modalCancel');

let state = {
  role: null,
  settings: null,
  candidates: [],
  processes: [],
  onlineMembers: [],
};

const toastEl = document.getElementById('toast');

function showToast(message) {
  if (!toastEl) return;
  toastEl.textContent = message || 'Ação concluída.';
  toastEl.classList.remove('hidden');
  clearTimeout(showToast._timer);
  showToast._timer = setTimeout(() => toastEl.classList.add('hidden'), 2800);
}

const postNui = async (action, data = {}) => {
  const res = await fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
};

const can = (perm) => !!(state.role?.can?.[perm]);

function switchTab(tab) {
  document.querySelectorAll('.tab').forEach((el) => el.classList.toggle('active', el.dataset.tab === tab));
  document.querySelectorAll('.panel').forEach((el) => el.classList.toggle('active', el.id === tab));
}

function roleLabel(role) {
  if (role === 'judge') return 'Juiz';
  if (role === 'prosecutor') return 'Promotor';
  if (role === 'lawyer') return 'Advogado';
  return role;
}

function buildRoleOptions(role) {
  return (state.onlineMembers || [])
    .filter((m) => m.role === role)
    .map((m) => `<option value="${m.citizenid}">${m.name} (${roleLabel(m.role)})</option>`)
    .join('');
}

function showModal(config) {
  return new Promise((resolve) => {
    modalTitle.textContent = config.title;
    modalFields.innerHTML = '';

    (config.fields || []).forEach((field) => {
      const wrapper = document.createElement('div');
      wrapper.className = 'field';
      const label = document.createElement('label');
      label.textContent = field.label;
      wrapper.appendChild(label);

      let input;
      if (field.type === 'textarea') {
        input = document.createElement('textarea');
      } else if (field.type === 'select') {
        input = document.createElement('select');
        input.innerHTML = field.options || '';
      } else {
        input = document.createElement('input');
        input.type = field.type || 'text';
      }

      input.id = `modal_${field.id}`;
      if (field.value !== undefined && field.value !== null) input.value = field.value;
      if (field.placeholder) input.placeholder = field.placeholder;
      if (field.min !== undefined) input.min = field.min;
      wrapper.appendChild(input);
      modalFields.appendChild(wrapper);
    });

    modalOverlay.classList.remove('hidden');

    const onConfirm = () => {
      const values = {};
      (config.fields || []).forEach((field) => {
        const el = document.getElementById(`modal_${field.id}`);
        values[field.id] = el ? el.value : null;
      });
      cleanup();
      resolve({ confirmed: true, values });
    };

    const onCancel = () => {
      cleanup();
      resolve({ confirmed: false, values: {} });
    };

    function cleanup() {
      modalOverlay.classList.add('hidden');
      modalConfirm.removeEventListener('click', onConfirm);
      modalCancel.removeEventListener('click', onCancel);
    }

    modalConfirm.addEventListener('click', onConfirm);
    modalCancel.addEventListener('click', onCancel);
  });
}

function renderCandidates() {
  candidatesEl.innerHTML = '';
  if (!state.candidates.length) {
    candidatesEl.innerHTML = '<p class="muted">Nenhum acusado atende ao critério atual.</p>';
    return;
  }

  state.candidates.forEach((c) => {
    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `
      <h3>${c.fullname}</h3>
      <p><b>CitizenID:</b> ${c.citizenid}</p>
      <p><b>Casos:</b> ${c.totalCases}</p>
      <p><b>Prisões:</b> ${c.arrests} | <b>Mandados:</b> ${c.warrants}</p>
      <p><b>Cenas suspeitas:</b> ${c.suspectedScenes} | <b>Vigilância forense:</b> ${c.forensicWatch}</p>
      <div class="actions">
        ${can('create') ? '<button class="btn-create">Distribuir processo</button>' : ''}
      </div>
    `;

    if (can('create')) {
      card.querySelector('.btn-create').addEventListener('click', async () => {
        const form = await showModal({
          title: 'Distribuir processo criminal',
          fields: [
            { id: 'summary', label: 'Resumo inicial', type: 'textarea', value: 'Distribuição automática por reincidência.' },
          ],
        });
        if (!form.confirmed) return;

        const result = await postNui('createProcess', {
          citizenid: c.citizenid,
          linkedCases: c.linkedCases,
          caseArea: 'criminal',
          claimType: 'Ação penal',
          originType: 'criminal',
          summary: form.values.summary,
        });

        if (!result.success) return showToast(result.error || 'Falha ao distribuir processo.');
        await refresh();
        switchTab('processes');
        openProcess(result.process.id);
      });
    }

    candidatesEl.appendChild(card);
  });
}

function renderProcesses() {
  processListEl.innerHTML = '';
  if (!state.processes.length) {
    processListEl.innerHTML = '<p class="muted">Nenhum processo cadastrado.</p>';
    return;
  }

  state.processes.forEach((p) => {
    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `
      <h3>${p.process_number}</h3>
      <p><b>Réu:</b> ${p.defendant_name || p.citizenid}</p>
      <p><b>Status:</b> ${p.status}</p>
      <p><b>Vara:</b> ${p.case_area || 'geral'} | <b>Causa:</b> ${p.claim_type || 'Não informada'}</p>
      <div class="actions"><button class="btn-open">Abrir</button></div>
    `;
    card.querySelector('.btn-open').addEventListener('click', () => openProcess(p.id));
    processListEl.appendChild(card);
  });
}

async function openProcess(id) {
  const result = await postNui('getProcess', { processId: id });
  if (!result.success) return showToast(result.error || 'Falha ao carregar processo.');

  const p = result.process;
  const fromLawyer = p.filed_by_role === 'lawyer';
  processDetailEl.classList.remove('hidden');
  processDetailEl.innerHTML = `
    <h3>${p.process_number} — ${p.defendant_name || p.citizenid}</h3>
    <p><b>Status:</b> ${p.status}</p>
    <p><b>Vara:</b> ${p.case_area || 'geral'} | <b>Causa:</b> ${p.claim_type || 'Não informado'}</p>
    <p><b>Autor:</b> ${p.plaintiff_name || '-'} (${p.plaintiff_citizenid || '-'})</p>
    <p><b>Promotor atual:</b> ${p.prosecutor_name || 'Não atribuído'}</p>
    <p><b>Advogado atual:</b> ${p.lawyer_name || 'Não atribuído'}</p>
    <p><b>Casos vinculados:</b> ${(p.linked_case_ids || []).join(', ') || 'Nenhum'}</p>

    <div class="row">
      <select id="assignProsecutor"><option value="">Selecionar promotor</option>${buildRoleOptions('prosecutor')}</select>
      ${fromLawyer ? '<span class="muted">Advogado já definido pela causa.</span>' : `<select id="assignLawyer"><option value="">Selecionar advogado</option>${buildRoleOptions('lawyer')}</select>`}
      ${can('verdict') ? '<button id="btnAssignParties">Atribuir partes</button>' : ''}
    </div>

    <p><b>Resumo:</b></p>
    <pre>${p.summary || 'Sem resumo.'}</pre>
    <p><b>Sentença / custas:</b></p>
    <pre>${p.sentence_text || 'Não definida.'}</pre>

    <h4>Andamentos</h4>
    <pre>${(p.events || []).map((e) => `[${e.created_at}] ${e.title}\n${e.description || ''}`).join('\n\n') || 'Sem movimentações.'}</pre>

    <div class="actions">
      ${can('schedule') ? '<button id="btnAddEvent">Adicionar andamento</button>' : ''}
      ${can('verdict') ? '<button id="btnReviewAccept">Aceitar entrada</button>' : ''}
      ${can('verdict') ? '<button id="btnReviewReject">Rejeitar entrada</button>' : ''}
      ${can('verdict') ? '<button id="btnAddVerdict">Registrar sentença</button>' : ''}
      ${can('verdict') ? '<button id="btnDirectPrison">Enviar direto à prisão (delay 5 min)</button>' : ''}
      ${can('defenseNotes') ? '<button id="btnDefense">Manifestação da defesa</button>' : ''}
    </div>
    ${can('verdict') ? '<p class="muted">Tudo funciona dentro do painel, sem janelas externas do sistema.</p>' : ''}
  `;

  if (can('verdict')) {
    const assignBtn = document.getElementById('btnAssignParties');
    if (assignBtn) {
      assignBtn.addEventListener('click', async () => {
        const prosecutorCitizenid = document.getElementById('assignProsecutor')?.value || '';
        const lawyerCitizenid = document.getElementById('assignLawyer')?.value || '';
        const resp = await postNui('assignProcessParties', { processId: p.id, prosecutorCitizenid, lawyerCitizenid });
        if (!resp.success) return showToast(resp.error || 'Erro ao atribuir partes.');
        if (resp.onlineMembers) state.onlineMembers = resp.onlineMembers;
        await refresh();
        openProcess(p.id);
      });
    }

    document.getElementById('btnReviewAccept').addEventListener('click', async () => {
      const form = await showModal({
        title: 'Aceitar entrada documental',
        fields: [{ id: 'reason', label: 'Justificativa', type: 'textarea', value: 'Documentação completa.' }],
      });
      if (!form.confirmed) return;
      const resp = await postNui('reviewIntake', { processId: p.id, accepted: true, reason: form.values.reason });
      if (!resp.success) return showToast(resp.error || 'Erro ao aceitar entrada.');
      await refresh();
      openProcess(p.id);
    });

    document.getElementById('btnReviewReject').addEventListener('click', async () => {
      const form = await showModal({
        title: 'Rejeitar entrada documental',
        fields: [{ id: 'reason', label: 'Justificativa', type: 'textarea' }],
      });
      if (!form.confirmed || !form.values.reason) return;
      const resp = await postNui('reviewIntake', { processId: p.id, accepted: false, reason: form.values.reason });
      if (!resp.success) return showToast(resp.error || 'Erro ao rejeitar entrada.');
      await refresh();
      openProcess(p.id);
    });

    document.getElementById('btnAddVerdict').addEventListener('click', async () => {
      const form = await showModal({
        title: 'Registrar sentença final',
        fields: [
          { id: 'sentenceText', label: 'Texto da sentença', type: 'textarea' },
          { id: 'loserParty', label: 'Parte perdedora', type: 'select', options: '<option value="reu">Réu</option><option value="autor">Autor</option><option value="nenhum">Nenhum</option>' },
        ],
      });
      if (!form.confirmed || !form.values.sentenceText) return;
      const resp = await postNui('finalizeJudgment', { processId: p.id, sentenceText: form.values.sentenceText, loserParty: form.values.loserParty });
      if (!resp.success) return showToast(resp.error || 'Erro ao registrar sentença.');
      await refresh();
      openProcess(p.id);
    });

    document.getElementById('btnDirectPrison').addEventListener('click', async () => {
      const form = await showModal({
        title: 'Agendar prisão direta (delay 5 min)',
        fields: [
          { id: 'sentence', label: 'Tempo de prisão', type: 'number', value: 30, min: 1 },
          { id: 'reason', label: 'Motivo da prisão direta', type: 'textarea', value: 'Ordem judicial imediata.' },
        ],
      });
      if (!form.confirmed) return;
      const resp = await postNui('scheduleDirectPrison', { processId: p.id, sentence: Number(form.values.sentence), reason: form.values.reason });
      if (!resp.success) return showToast(resp.error || 'Erro ao agendar prisão direta.');
      await refresh();
      openProcess(p.id);
    });
  }

  if (can('schedule')) {
    document.getElementById('btnAddEvent')?.addEventListener('click', async () => {
      const form = await showModal({
        title: 'Adicionar andamento processual',
        fields: [
          { id: 'title', label: 'Título', type: 'text' },
          { id: 'description', label: 'Descrição', type: 'textarea' },
          { id: 'status', label: 'Status', type: 'select', options: '<option value="triagem">Triagem</option><option value="audiencia_marcada">Audiência marcada</option><option value="em_julgamento">Em julgamento</option><option value="sentenciado">Sentenciado</option><option value="arquivado">Arquivado</option>' },
        ],
      });
      if (!form.confirmed || !form.values.title) return;
      const resp = await postNui('addEvent', { processId: p.id, title: form.values.title, description: form.values.description, status: form.values.status, eventType: 'andamento' });
      if (!resp.success) return showToast(resp.error || 'Erro ao adicionar andamento.');
      await refresh();
      openProcess(p.id);
    });
  }

  if (can('defenseNotes')) {
    document.getElementById('btnDefense')?.addEventListener('click', async () => {
      const form = await showModal({
        title: 'Manifestação da defesa',
        fields: [{ id: 'note', label: 'Texto da manifestação', type: 'textarea' }],
      });
      if (!form.confirmed || !form.values.note) return;
      const resp = await postNui('addDefenseNote', { processId: p.id, note: form.values.note });
      if (!resp.success) return showToast(resp.error || 'Erro ao salvar manifestação.');
      await refresh();
      openProcess(p.id);
    });
  }
}

function renderSettings() {
  requiredCasesLabel.textContent = state.settings.requiredCriminalCases;
  inputRequiredCases.value = state.settings.requiredCriminalCases;
  inputRequiredCases.min = state.settings.minRequiredCases;
  inputRequiredCases.max = state.settings.maxRequiredCases;

  if (!can('settings')) {
    inputRequiredCases.disabled = true;
    document.getElementById('btnSaveSettings').disabled = true;
    settingsHint.textContent = 'Apenas Juiz pode alterar o gatilho de distribuição.';
  } else {
    settingsHint.textContent = 'Defina quantos casos criminais vinculados tornam o acusado elegível automaticamente.';
  }
}

function renderAll() {
  roleBadge.textContent = `${state.role.label} (${state.role.name})`;
  renderCandidates();
  renderProcesses();
  renderSettings();
}

async function refresh() {
  const response = await postNui('refresh');
  if (!response.success) return showToast(response.error || 'Falha ao atualizar dados.');

  state = {
    role: response.role,
    settings: response.settings,
    candidates: response.candidates || [],
    processes: response.processes || [],
    onlineMembers: response.onlineMembers || [],
  };
  renderAll();
}

window.addEventListener('message', (event) => {
  const { action, payload } = event.data || {};
  if (action === 'open') {
    app.classList.remove('hidden');
    state = {
      role: payload.role,
      settings: payload.settings,
      candidates: payload.candidates || [],
      processes: payload.processes || [],
      onlineMembers: payload.onlineMembers || [],
    };
    switchTab('dashboard');
    renderAll();
  }

  if (action === 'close') {
    app.classList.add('hidden');
    processDetailEl.classList.add('hidden');
    modalOverlay.classList.add('hidden');
  }
});

document.querySelectorAll('.tab').forEach((btn) => btn.addEventListener('click', () => switchTab(btn.dataset.tab)));
document.getElementById('btnClose').addEventListener('click', () => postNui('close'));
document.getElementById('btnRefresh').addEventListener('click', refresh);

document.getElementById('btnSaveSettings').addEventListener('click', async () => {
  const requiredCriminalCases = Number(inputRequiredCases.value);
  const result = await postNui('updateSettings', { requiredCriminalCases });
  if (!result.success) return showToast(result.error || 'Erro ao salvar configuração.');
  state.settings.requiredCriminalCases = result.requiredCriminalCases;
  state.candidates = result.candidates || [];
  renderAll();
});

document.getElementById('btnNewProcess').addEventListener('click', async () => {
  if (!can('create')) return showToast('Seu perfil não pode distribuir processo.');

  const form = await showModal({
    title: 'Nova causa no tribunal',
    fields: [
      { id: 'caseArea', label: 'Vara', type: 'select', options: '<option value="geral">Processo Geral</option><option value="familia">Família</option><option value="trabalhista">Trabalhista</option><option value="criminal">Criminal</option>' },
      { id: 'claimType', label: 'Tipo da causa', type: 'text', value: 'Causa geral' },
      { id: 'plaintiffCitizenid', label: 'CitizenID do autor (opcional)', type: 'text' },
      { id: 'plaintiffName', label: 'Nome do autor (opcional)', type: 'text' },
      { id: 'citizenid', label: 'CitizenID do réu/acusado', type: 'text' },
      { id: 'summary', label: 'Resumo do caso', type: 'textarea' },
    ],
  });

  if (!form.confirmed || !form.values.citizenid) return;

  const result = await postNui('createProcess', {
    caseArea: form.values.caseArea,
    claimType: form.values.claimType,
    plaintiffCitizenid: form.values.plaintiffCitizenid,
    plaintiffName: form.values.plaintiffName,
    citizenid: form.values.citizenid,
    summary: form.values.summary,
    originType: form.values.caseArea === 'criminal' ? 'criminal' : 'civil',
    linkedCases: [],
  });

  if (!result.success) return showToast(result.error || 'Erro ao criar processo.');
  await refresh();
  switchTab('processes');
  openProcess(result.process.id);
});

document.addEventListener('keyup', (ev) => {
  if (ev.key === 'Escape') {
    if (!modalOverlay.classList.contains('hidden')) {
      modalOverlay.classList.add('hidden');
    } else {
      postNui('close');
    }
  }
});
