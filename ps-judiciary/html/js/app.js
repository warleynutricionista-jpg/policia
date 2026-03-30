const app = document.getElementById('app');
const roleBadge = document.getElementById('roleBadge');
const requiredCasesLabel = document.getElementById('requiredCasesLabel');
const candidatesEl = document.getElementById('candidates');
const processListEl = document.getElementById('processList');
const processDetailEl = document.getElementById('processDetail');
const inputRequiredCases = document.getElementById('inputRequiredCases');
const settingsHint = document.getElementById('settingsHint');

let state = {
  role: null,
  settings: null,
  candidates: [],
  processes: [],
};

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
        const summary = prompt('Resumo inicial do processo:') || 'Distribuição automática por reincidência.';
        const result = await postNui('createProcess', {
          citizenid: c.citizenid,
          linkedCases: c.linkedCases,
          originType: 'criminal',
          summary,
        });

        if (!result.success) {
          alert(result.error || 'Falha ao distribuir processo.');
          return;
        }

        state.processes.unshift(result.process);
        renderProcesses();
        alert(`Processo criado: ${result.process.process_number}`);
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
      <p><b>Origem:</b> ${p.origin_type}</p>
      <div class="actions">
        <button class="btn-open">Abrir</button>
      </div>
    `;

    card.querySelector('.btn-open').addEventListener('click', () => openProcess(p.id));
    processListEl.appendChild(card);
  });
}

async function openProcess(id) {
  const result = await postNui('getProcess', { processId: id });
  if (!result.success) {
    alert(result.error || 'Falha ao carregar processo.');
    return;
  }

  const p = result.process;
  processDetailEl.classList.remove('hidden');
  processDetailEl.innerHTML = `
    <h3>${p.process_number} — ${p.defendant_name || p.citizenid}</h3>
    <p><b>Status:</b> ${p.status}</p>
    <p><b>Vara:</b> ${p.case_area || 'geral'}</p>
    <p><b>Tipo da causa:</b> ${p.claim_type || 'Não informado'}</p>
    <p><b>Autor:</b> ${p.plaintiff_name || '-'} (${p.plaintiff_citizenid || '-'})</p>
    <p><b>Casos vinculados:</b> ${(p.linked_case_ids || []).join(', ') || 'Nenhum'}</p>
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
    ${can('verdict') ? '<p class="muted">Atenção Juiz: ao clicar em \"Enviar direto à prisão\", o sistema aguardará 5 minutos para dar tempo de conduzir o réu até uma cela/sala, e só então executará a prisão automática.</p>' : ''}
  `;

  if (can('schedule')) {
    document.getElementById('btnAddEvent').addEventListener('click', async () => {
      const title = prompt('Título do andamento:');
      if (!title) return;
      const description = prompt('Descrição:') || '';
      const status = prompt('Status (triagem/audiencia_marcada/em_julgamento/sentenciado/arquivado):') || p.status;
      const resp = await postNui('addEvent', { processId: p.id, title, description, status, eventType: 'andamento' });
      if (!resp.success) return alert(resp.error || 'Erro ao adicionar andamento.');
      await refresh();
      openProcess(p.id);
    });
  }

  if (can('verdict')) {
    document.getElementById('btnReviewAccept').addEventListener('click', async () => {
      const reason = prompt('Justificativa do aceite documental:') || 'Documentação completa.';
      const resp = await postNui('reviewIntake', { processId: p.id, accepted: true, reason });
      if (!resp.success) return alert(resp.error || 'Erro ao aceitar entrada.');
      await refresh();
      openProcess(p.id);
    });

    document.getElementById('btnReviewReject').addEventListener('click', async () => {
      const reason = prompt('Justificativa da rejeição documental:');
      if (!reason) return;
      const resp = await postNui('reviewIntake', { processId: p.id, accepted: false, reason });
      if (!resp.success) return alert(resp.error || 'Erro ao rejeitar entrada.');
      await refresh();
      openProcess(p.id);
    });

    document.getElementById('btnAddVerdict').addEventListener('click', async () => {
      const sentenceText = prompt('Texto da sentença:');
      if (!sentenceText) return;
      const loserParty = prompt('Parte perdedora (autor/reu/nenhum):', 'reu') || 'reu';
      const resp = await postNui('finalizeJudgment', {
        processId: p.id,
        sentenceText,
        loserParty,
      });
      if (!resp.success) return alert(resp.error || 'Erro ao registrar sentença.');
      await refresh();
      openProcess(p.id);
    });

    document.getElementById('btnDirectPrison').addEventListener('click', async () => {
      const sentence = Number(prompt('Tempo de prisão para execução automática (ex: 30):', '30'));
      if (!sentence || sentence <= 0) return;
      const reason = prompt('Motivo da prisão direta:') || 'Ordem judicial imediata.';
      const resp = await postNui('scheduleDirectPrison', {
        processId: p.id,
        sentence,
        reason,
      });
      if (!resp.success) return alert(resp.error || 'Erro ao agendar prisão direta.');
      alert('Prisão direta agendada. Execução automática em 5 minutos.');
      await refresh();
      openProcess(p.id);
    });
  }

  if (can('defenseNotes')) {
    document.getElementById('btnDefense').addEventListener('click', async () => {
      const note = prompt('Manifestação da defesa:');
      if (!note) return;
      const resp = await postNui('addDefenseNote', { processId: p.id, note });
      if (!resp.success) return alert(resp.error || 'Erro ao salvar manifestação.');
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
  if (!response.success) {
    alert(response.error || 'Falha ao atualizar dados.');
    return;
  }

  state = {
    role: response.role,
    settings: response.settings,
    candidates: response.candidates || [],
    processes: response.processes || [],
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
    };
    switchTab('dashboard');
    renderAll();
  }

  if (action === 'close') {
    app.classList.add('hidden');
    processDetailEl.classList.add('hidden');
  }
});

document.querySelectorAll('.tab').forEach((btn) => {
  btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

document.getElementById('btnClose').addEventListener('click', () => postNui('close'));
document.getElementById('btnRefresh').addEventListener('click', refresh);

document.getElementById('btnSaveSettings').addEventListener('click', async () => {
  const requiredCriminalCases = Number(inputRequiredCases.value);
  const result = await postNui('updateSettings', { requiredCriminalCases });
  if (!result.success) {
    alert(result.error || 'Erro ao salvar configuração.');
    return;
  }

  state.settings.requiredCriminalCases = result.requiredCriminalCases;
  state.candidates = result.candidates || [];
  renderAll();
});

document.getElementById('btnNewProcess').addEventListener('click', async () => {
  if (!can('create')) {
    return alert('Seu perfil não pode distribuir processo.');
  }

  const caseArea = (prompt('Vara (familia/trabalhista/geral/criminal):', 'geral') || 'geral').toLowerCase();
  const claimType = prompt('Tipo da causa (livre):') || 'Causa geral';
  const plaintiffCitizenid = prompt('CitizenID do autor (opcional):') || '';
  const plaintiffName = prompt('Nome do autor (opcional):') || '';
  const citizenid = prompt('CitizenID do réu/acusado:');
  if (!citizenid) return;
  const summary = prompt('Resumo do caso:') || '';

  const result = await postNui('createProcess', {
    caseArea,
    claimType,
    plaintiffCitizenid,
    plaintiffName,
    citizenid,
    summary,
    originType: caseArea === 'criminal' ? 'criminal' : 'civil',
    linkedCases: [],
  });

  if (!result.success) {
    return alert(result.error || 'Erro ao criar processo.');
  }

  await refresh();
  switchTab('processes');
  openProcess(result.process.id);
});

document.addEventListener('keyup', (ev) => {
  if (ev.key === 'Escape') postNui('close');
});
