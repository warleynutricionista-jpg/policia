// html/app.js
// Painel de Oficiais Ativos — NUI (PT-BR)
// Reescrito e aprimorado: utilitários centralizados, mensagens PT-BR, organização e robustez.

$(function () {
  //========================[ CONST / ESTADO ]========================//
  const RESOURCE = 'qb-activeofficers';

  // Mapa de categorias ⇄ canais (deve bater com client/server/config)
  const CHANNEL_MAP = {
    main: '1B',
    store: '2B',
    fleeca: '3B',
    pacific: '4B',
    jewelry: '5B',
    pursuit: '6B',
    traffic: '7B',
    investigation: '8B',
  };

  // Títulos das categorias em PT-BR
  const CATEGORY_TITLES = {
    main: 'Principal',
    store: 'Roubo em Loja',
    fleeca: 'Roubo ao Fleeca',
    pacific: 'Roubo ao Pacific',
    jewelry: 'Roubo à Joalheria',
    pursuit: 'Perseguição',
    traffic: 'Abordagem de Trânsito',
    investigation: 'Investigação',
  };

  const DEFAULT_AVATAR = 'img/default_avatar.png';

  // Estado de interface
  let panelDragging = false;
  let listDragging = false;
  let dragOffsetX = 0;
  let dragOffsetY = 0;
  let panelPosition = { x: 20, y: 20 };
  let listPosition = { x: 20, y: 20 };
  let isListVisible = false;
  let myServerId = null;
  let customImageUrl = '';
  let currentCategory = 'main';
  let isCommissioner = false;
  let callsignColorConfigs = [];
  let officersByCategoryCount = {};
  let totalOfficers = 0;
  let isResizing = false;

  //========================[ HELPERS / UTIL ]========================//
  const $officersContainer = $('#officers-container');
  const $officersListContainer = $('#officers-list-container');
  const $panelHeader = $('#panel-draggable-header');
  const $listHeader = $('#list-draggable-header');
  const $compactList = $('#compact-officers-list');
  const $panelList = $('#officers-panel-list');
  const $imageInput = $('#custom-image');
  const $imagePreview = $('#image-preview');
  const $callsign = $('#callsign');
  const $badge = $('#badge');

  function postNUI(endpoint, data = {}, cb) {
    try {
      $.post(`https://${RESOURCE}/${endpoint}`, JSON.stringify(data), cb);
    } catch (e) {
      // Evita travar a NUI em caso de erro
      // console.error(`[NUI] Falha no POST ${endpoint}`, e);
    }
  }

  function clamp(v, min, max) {
    return Math.max(min, Math.min(v, max));
  }

  function showToast(message, duration = 2500) {
    if ($('.tooltip').length === 0) $('body').append('<div class="tooltip"></div>');
    const $toast = $('.tooltip');
    $toast.text(message);
    setTimeout(() => {
      $toast.addClass('show');
      setTimeout(() => $toast.removeClass('show'), duration);
    }, 80);
  }

  function getCategoryTitle(cat) {
    return CATEGORY_TITLES[cat] || CATEGORY_TITLES.main;
  }

  function safeSetImg($target, url) {
    if (!url) return $target.attr('src', DEFAULT_AVATAR);
    const test = new Image();
    test.onload = () => $target.attr('src', url);
    test.onerror = () => $target.attr('src', DEFAULT_AVATAR);
    test.src = url;
  }

  function getCallsignColor(callsign) {
    if (!callsign || callsign === 'NO CALLSIGN') return '#ffcc00';
    const matches = callsign.match(/\d+/);
    if (!matches || !matches[0]) return '#ffcc00';
    const num = parseInt(matches[0]);
    for (const cfg of callsignColorConfigs) {
      if (num >= cfg.min && num <= cfg.max) return cfg.color;
    }
    return '#aaaaaa';
  }

  function getStatusIcon(status) {
    switch (status) {
      case 'vehicle': return 'fa-car';
      case 'aircraft': return 'fa-helicopter';
      case 'dead': return 'fa-skull';
      default: return 'fa-walking';
    }
  }

  function getStatusTitle(status) {
    switch (status) {
      case 'vehicle': return 'Em Veículo';
      case 'aircraft': return 'Em Aeronave';
      case 'dead': return 'Oficial Abatido';
      default: return 'A Pé';
    }
  }

  function countOfficersByCategory(officers) {
    officersByCategoryCount = {};
    totalOfficers = officers ? officers.length : 0;
    Object.keys(CHANNEL_MAP).forEach(cat => (officersByCategoryCount[cat] = 0));
    if (officers && officers.length) {
      officers.forEach(o => {
        if (o.category && officersByCategoryCount[o.category] !== undefined) {
          officersByCategoryCount[o.category]++;
        }
      });
    }
  }

  function updateToggleButton() {
    if (isListVisible) {
      $('#toggle-officers-list').addClass('active');
      $('.toggle-text-off').hide();
      $('.toggle-text-on').show();
    } else {
      $('#toggle-officers-list').removeClass('active');
      $('.toggle-text-off').show();
      $('.toggle-text-on').hide();
    }
  }

  function updateTalkingIndicator(serverId, isTalking) {
    const $targets = $(`.officer-item[data-source="${serverId}"] .talking-indicator, .compact-list-item[data-source="${serverId}"] .talking-indicator`);
    $targets.toggleClass('active', !!isTalking);

    if (isTalking) {
      const key = `talking_${serverId}`;
      if (window[key]) clearTimeout(window[key]);
      window[key] = setTimeout(() => {
        $targets.removeClass('active');
        window[key] = null;
      }, 5000);
    }
  }

  function updateCategoryDisplay(category, channel, officers) {
    const catName = getCategoryTitle(category);
    if (officers) countOfficersByCategory(officers);

    let countText = '';
    if (category === 'main') {
      countText = ` - (${totalOfficers || 0})`;
    } else if (officersByCategoryCount[category] !== undefined) {
      countText = ` - (${officersByCategoryCount[category] || 0})`;
    }

    $('#panel-category-name').text(catName);
    $('#panel-category-channel').text(channel);
    $('#panel-officer-count').text(countText);

    $('#list-category-name').text(catName);
    $('#list-category-channel').text(channel);
    $('#list-officer-count').text(countText);

    updateSubcategoriesList(officers);
  }

  function updateCategoryUI(category, channel, officers) {
    if (!channel) channel = CHANNEL_MAP[category] || '1B';
    $('.radio-category-btn').removeClass('active');
    $(`.radio-category-btn[data-category="${category}"]`).addClass('active');
    currentCategory = category;
    updateCategoryDisplay(category, channel, officers);
  }

  //========================[ SUBCATEGORIAS ]========================//
  function ensureSubcatContainer() {
    if (!$('#subcategories-list').length) {
      $('#compact-officers-list').before('<div id="subcategories-list" class="subcategories-list"></div>');
    }
    return $('#subcategories-list');
  }

  function updateSubcategoriesList(officers) {
    const $sub = ensureSubcatContainer();
    $sub.empty();

    const mainCount = officersByCategoryCount['main'] || 0;
    const isMainActive = currentCategory === 'main';
    $sub.append(`
      <div class="subcategory-item ${isMainActive ? 'active' : ''}" data-category="main">
        <span class="subcategory-name">Principal (1B)</span>
        <span class="subcategory-count">(${mainCount})</span>
      </div>
    `);

    Object.keys(officersByCategoryCount).forEach(cat => {
      if (cat !== 'main' && officersByCategoryCount[cat] > 0) {
        const title = getCategoryTitle(cat);
        const ch = CHANNEL_MAP[cat] || '1B';
        const cnt = officersByCategoryCount[cat];
        const active = currentCategory === cat ? 'active' : '';
        $sub.append(`
          <div class="subcategory-item ${active}" data-category="${cat}">
            <span class="subcategory-name">${title} (${ch})</span>
            <span class="subcategory-count">(${cnt})</span>
          </div>
        `);
      }
    });

    $('.subcategory-item').off('click').on('click', function () {
      const cat = $(this).data('category');
      if (!cat) return;
      currentCategory = cat;
      $('.subcategory-item').removeClass('active');
      $(this).addClass('active');
      postNUI('updateCategory', { category: cat, channel: CHANNEL_MAP[cat] });
    });
  }

  //========================[ POSIÇÕES INICIAIS ]========================//
  postNUI('getPosition', { type: 'panel' }, function (position) {
    if (position && typeof position.x === 'number' && typeof position.y === 'number') {
      panelPosition = position;
    }
    $officersContainer.css({ left: `${panelPosition.x}px`, top: `${panelPosition.y}px` });
  });

  postNUI('getPosition', { type: 'list' }, function (position) {
    if (position && typeof position.x === 'number' && typeof position.y === 'number') {
      listPosition = position;
    }
    $officersListContainer.css({ left: `${listPosition.x}px`, top: `${listPosition.y}px` });
  });

  //========================[ CORES POR CALLSIGN ]========================//
  postNUI('getCallsignColors', {}, function (colors) {
    callsignColorConfigs = Array.isArray(colors) ? colors : [];
    updateCommissionerPanel();
  });

  //========================[ INPUT DE IMAGEM ]========================//
  $imageInput.on('input', function () {
    const url = $(this).val().trim();
    safeSetImg($imagePreview, url || DEFAULT_AVATAR);
  });

  $(document).ready(function () {
    if (!$imageInput.val().trim()) safeSetImg($imagePreview, DEFAULT_AVATAR);
  });

  //========================[ BOTÕES DE CATEGORIA (RÁDIO) ]========================//
  $('.radio-category-btn').on('click', function () {
    const category = $(this).data('category');
    const channel = $(this).data('channel');
    currentCategory = category;

    $('.radio-category-btn').removeClass('active');
    $(this).addClass('active');

    updateCategoryDisplay(category, channel);
    postNUI('updateCategory', { category, channel });
  });

  //========================[ WAYPOINT (LOCALIZAÇÃO) ]========================//
  function handleLocationClick(e, serverId) {
    e?.stopPropagation?.();
    postNUI('setWaypoint', { serverId: parseInt(serverId) }, function (resp) {
      if (resp && resp.success) {
        showToast(`Waypoint definido para ${resp.officerName}`);
      } else {
        showToast('Não foi possível localizar o policial');
      }
    });
  }

  $(document).on('click', '.location-btn', function (e) {
    const serverId = $(this).data('source');
    handleLocationClick(e, serverId);
  });

  //========================[ RENDER DE LISTAS ]========================//
  function populateOfficersList(officers, targetElementId, isCompact = false, noReload = false) {
    const $target = $(`#${targetElementId}`);
    if (!noReload) $target.empty();

    countOfficersByCategory(officers);

    if (officers && officers.length) {
      officers.forEach(officer => {
        const callsignColor = getCallsignColor(officer.callsign);
        const callsignHtml = `<span class="callsign-badge" style="color:${callsignColor}">${officer.callsign}${!officer.onduty ? '-10-7' : ''}</span>`;
        const isCurrentUser = myServerId && officer.source == myServerId ? 'current-user' : '';
        const dutyClass = !officer.onduty ? 'officer-offduty' : '';
        const status = officer.status || 'standing';
        const statusIcon = getStatusIcon(status);
        const statusTitle = getStatusTitle(status);

        const radioActive = officer.radioChannel && officer.radioChannel > 0;
        const radioLabel = radioActive ? `${officer.radioChannel} Hz` : 'Sem Rádio';

        const avatar = officer.customImage
          ? `<img src="${officer.customImage}" onerror="this.parentNode.innerHTML='<i class=\\'fas fa-user\\'></i>'">`
          : `<i class="fas fa-user"></i>`;

        const existing = $target.find(`[data-source="${officer.source}"]`);
        if (noReload && existing.length) {
          updateOfficerItem(officer, isCompact, existing);
        } else {
          if (existing.length) existing.remove();

          const base = isCompact
            ? `
              <div class="compact-list-item ${isCurrentUser} ${dutyClass}" data-source="${officer.source}">
                <div class="compact-callsign">${callsignHtml}</div>
                <div class="player-avatar">${avatar}</div>
                <div class="compact-name">${officer.name} | ${officer.grade}</div>
                <div class="compact-radio-channel ${radioActive ? 'radio-active' : ''}">${radioLabel}</div>
                <div class="compact-controls">
                  <div class="location-btn" data-source="${officer.source}" title="Definir waypoint"><i class="fas fa-map-marker-alt"></i></div>
                  <div class="compact-talking"><div class="talking-indicator ${officer.isTalking ? 'active' : ''}"></div></div>
                </div>
                <div class="compact-status"><i class="fas ${statusIcon}" title="${statusTitle}"></i></div>
              </div>`
            : `
              <div class="officer-item ${isCurrentUser} ${dutyClass}" data-source="${officer.source}">
                <div class="officer-callsign">${callsignHtml}</div>
                <div class="player-avatar">${avatar}</div>
                <div class="officer-name">${officer.name} | ${officer.grade}</div>
                <div class="officer-radio-channel ${radioActive ? 'radio-active' : ''}">${radioLabel}</div>
                <div class="officer-controls">
                  <div class="location-btn" data-source="${officer.source}" title="Definir waypoint"><i class="fas fa-map-marker-alt"></i></div>
                  <div class="officer-talking"><div class="talking-indicator ${officer.isTalking ? 'active' : ''}"></div></div>
                </div>
                <div class="officer-status"><i class="fas ${statusIcon}" title="${statusTitle}"></i></div>
              </div>`;

          $target.append(base);

          const $newItem = $target.find(`[data-source="${officer.source}"]`);
          $newItem.find('.location-btn').on('click', function (e) {
            handleLocationClick(e, officer.source);
          });
        }

        // Atualizações do próprio usuário no painel completo
        if (myServerId && officer.source == myServerId && !isCompact) {
          $badge.val(officer.badge);
          safeSetImg($imagePreview, officer.customImage || DEFAULT_AVATAR);
          if (officer.category) updateCategoryUI(officer.category, officer.channel, officers);
        }
      });

      updateSubcategoriesList(officers);

      // Remover itens que saíram
      const ids = officers.map(o => o.source);
      $target.find('[data-source]').each(function () {
        const id = $(this).data('source');
        if (!ids.includes(parseInt(id))) $(this).remove();
      });
    } else if (!noReload) {
      $target.html('<div class="no-officers">Nenhum oficial ativo disponível</div>');
    }

    updateCategoryDisplay(currentCategory, $('#list-category-channel').text(), officers);
  }

  function updateOfficerItem(officer, isCompact, $el) {
    const callsignColor = getCallsignColor(officer.callsign);
    const callsignHtml = `<span class="callsign-badge" style="color:${callsignColor}">${officer.callsign}${!officer.onduty ? '-10-7' : ''}</span>`;
    $el.toggleClass('officer-offduty', !officer.onduty);

    $el.find(`.${isCompact ? 'compact' : 'officer'}-callsign`).html(callsignHtml);

    const radioActive = officer.radioChannel && officer.radioChannel > 0;
    const radioLabel = radioActive ? `${officer.radioChannel} Hz` : 'Sem Rádio';
    const $ch = $el.find(`.${isCompact ? 'compact' : 'officer'}-radio-channel`);
    $ch.text(radioLabel).toggleClass('radio-active', radioActive);

    $el.find(`.${isCompact ? 'compact' : 'officer'}-name`).text(`${officer.name} | ${officer.grade}`);

    const statusIcon = getStatusIcon(officer.status || 'standing');
    const statusTitle = getStatusTitle(officer.status || 'standing');
    $el.find(`.${isCompact ? 'compact' : 'officer'}-status i`)
      .removeClass()
      .addClass(`fas ${statusIcon}`)
      .attr('title', statusTitle);

    const $talk = $el.find('.talking-indicator');
    if ($talk.length && officer.isTalking !== undefined) $talk.toggleClass('active', !!officer.isTalking);

    if (officer.customImage) {
      const $avatar = $el.find('.player-avatar');
      const img = new Image();
      img.onload = function () {
        if ($avatar.find('i').length) {
          $avatar.empty().append($('<img>').attr('src', officer.customImage));
        } else {
          $avatar.find('img').attr('src', officer.customImage);
        }
      };
      img.onerror = function () {
        $avatar.empty().append($('<i class="fas fa-user"></i>'));
      };
      img.src = officer.customImage;
    }

    if (!$el.find('.location-btn').length) {
      const $controls = $el.find(`.${isCompact ? 'compact' : 'officer'}-controls`);
      if ($controls.length) {
        const $btn = $(
          `<div class="location-btn" data-source="${officer.source}" title="Definir waypoint"><i class="fas fa-map-marker-alt"></i></div>`
        );
        $controls.prepend($btn);
        $btn.on('click', function (e) {
          handleLocationClick(e, officer.source);
        });
      }
    }
  }

  function updateOfficerDataInLists(officers, myId, updatedFields) {
    const me = officers.find(o => o.source == myId);
    if (!me) return;
    updateSpecificFields('officers-panel-list', me, updatedFields, false);
    updateSpecificFields('compact-officers-list', me, updatedFields, true);
  }

  function updateSpecificFields(targetId, officer, updatedFields, isCompact) {
    const $target = $(`#${targetId}`);
    const selector = `.${isCompact ? 'compact' : 'officer'}-item[data-source="${officer.source}"]`;
    const $el = $target.find(selector);
    if (!$el.length) return;

    if (updatedFields.callsign) {
      const color = getCallsignColor(officer.callsign);
      const badge = `<span class="callsign-badge" style="color:${color}">${officer.callsign}${!officer.onduty ? '-10-7' : ''}</span>`;
      $el.find(`.${isCompact ? 'compact' : 'officer'}-callsign`).html(badge);
    }

    if (updatedFields.radioChannel) {
      const $ch = $el.find(`.${isCompact ? 'compact' : 'officer'}-radio-channel`);
      if (officer.radioChannel && officer.radioChannel > 0) {
        $ch.text(`${officer.radioChannel} Hz`).addClass('radio-active');
      } else {
        $ch.text('Sem Rádio').removeClass('radio-active');
      }
    }

    if (updatedFields.status) {
      const icon = getStatusIcon(officer.status);
      const title = getStatusTitle(officer.status);
      $el.find(`.${isCompact ? 'compact' : 'officer'}-status i`)
        .removeClass()
        .addClass(`fas ${icon}`)
        .attr('title', title);
    }

    if (updatedFields.customImage) {
      const $avatar = $el.find('.player-avatar');
      if (officer.customImage) {
        if ($avatar.find('i').length) {
          $avatar.empty().append($('<img>').attr('src', officer.customImage));
        } else {
          $avatar.find('img').attr('src', officer.customImage);
        }
        $avatar.find('img').on('error', function () {
          $avatar.empty().append($('<i class="fas fa-user"></i>'));
        });
      }
    }

    if (updatedFields.badge && !isCompact) $badge.val(officer.badge);

    if (updatedFields.dutyStatus !== undefined) {
      $el.toggleClass('officer-offduty', !officer.onduty);
    }

    if (!$el.find('.location-btn').length) {
      const $controls = $el.find(`.${isCompact ? 'compact' : 'officer'}-controls`);
      if ($controls.length) {
        const $btn = $(
          `<div class="location-btn" data-source="${officer.source}" title="Definir waypoint"><i class="fas fa-map-marker-alt"></i></div>`
        );
        $controls.prepend($btn);
        $btn.on('click', function (e) {
          handleLocationClick(e, officer.source);
        });
      }
    }
  }

  //========================[ NUI MESSAGES ]========================//
  window.addEventListener('message', function (event) {
    const data = event.data;
    switch (data.action) {
      case 'openActiveOfficersPanel': {
        $officersContainer.fadeIn(200);
        myServerId = data.myServerId;
        populateOfficersList(data.officers, 'officers-panel-list');

        $officersContainer.css({ left: `${panelPosition.x}px`, top: `${panelPosition.y}px` });

        if (data.currentCallsign) $callsign.val(data.currentCallsign);
        if (data.currentBadge) $badge.val(data.currentBadge);

        if (data.customImageUrl) {
          customImageUrl = data.customImageUrl;
          $imageInput.val(data.customImageUrl);
          safeSetImg($imagePreview, data.customImageUrl);
        } else {
          safeSetImg($imagePreview, DEFAULT_AVATAR);
        }

        if (data.currentCategory) {
          currentCategory = data.currentCategory;
          updateCategoryUI(data.currentCategory, data.currentChannel, data.officers);
        }

        isListVisible = !!data.listVisible;
        updateToggleButton();

        isCommissioner = !!data.isCommissioner;
        $('#show-commissioner-panel').toggle(isCommissioner);
        break;
      }

      case 'closeActiveOfficersPanel':
        $officersContainer.fadeOut(200);
        $('#commissioner-panel').hide();
        $('#main-settings-content').show();
        break;

      case 'refreshOfficers':
        populateOfficersList(data.officers, 'officers-panel-list', false, data.noReload);
        if (data.myServerId) myServerId = data.myServerId;
        updateCategoryDisplay(currentCategory, $('#panel-category-channel').text(), data.officers);
        break;

      case 'toggleOfficersList':
        isListVisible = !!data.visible;
        if (isListVisible) {
          $officersListContainer.fadeIn(200);
          $officersListContainer.css({ left: `${listPosition.x}px`, top: `${listPosition.y}px` });
          if (data.myServerId) myServerId = data.myServerId;
          populateOfficersList(data.officers, 'compact-officers-list', true, data.noReload);
          updateCategoryDisplay(currentCategory, $('#list-category-channel').text(), data.officers);
        } else {
          $officersListContainer.fadeOut(200);
        }
        updateToggleButton();
        break;

      case 'refreshOfficersList':
        populateOfficersList(data.officers, 'compact-officers-list', true, data.noReload);
        if (data.myServerId) myServerId = data.myServerId;
        updateCategoryDisplay(currentCategory, $('#list-category-channel').text(), data.officers);
        break;

      case 'updateLocalCallsign':
        $callsign.val(data.callsign);
        break;

      case 'updateCategory':
        currentCategory = data.category;
        updateCategoryUI(data.category, data.channel, data.officers);
        break;

      case 'updateOfficerData':
        updateOfficerDataInLists(data.officers, data.myServerId, data.updatedFields);
        updateCategoryDisplay(currentCategory, $('#panel-category-channel').text(), data.officers);
        break;

      case 'updateCustomImage':
        customImageUrl = data.imageUrl || '';
        $imageInput.val(customImageUrl);
        safeSetImg($imagePreview, customImageUrl || DEFAULT_AVATAR);
        break;

      case 'updateTalking':
        updateTalkingIndicator(data.serverId, data.isTalking, data.radioChannel);
        break;
    }
  });

  //========================[ BOTÕES / AÇÕES UI ]========================//
  $('#close-panel').on('click', function () {
    $officersContainer.fadeOut(200);
    $('#commissioner-panel').hide();
    $('#main-settings-content').show();
    postNUI('closePanel', {});
  });

  $('#show-commissioner-panel').on('click', function () {
    if (!isCommissioner) return;
    $('#main-settings-content').hide();
    $('#commissioner-panel').show();
    $(this).hide();
    $('#officers-container .officers-header h1').html('Painel do Comissário');
    updateCommissionerPanel();
  });

  $('#back-to-settings').on('click', function () {
    $('#commissioner-panel').hide();
    $('#main-settings-content').show();
    $('#show-commissioner-panel').show();
    const name = getCategoryTitle(currentCategory);
    const ch = $('#panel-category-channel').text();
    const cnt = $('#panel-officer-count').text();
    $('#officers-container .officers-header h1').html(
      `<span id="panel-category-name">${name}</span> (<span id="panel-category-channel">${ch}</span>)<span id="panel-officer-count">${cnt}</span>`
    );
  });

  $('#save-settings').on('click', function () {
    const callsign = ($callsign.val() || '').trim() || 'NO CALLSIGN';
    const imageUrl = ($imageInput.val() || '').trim();
    postNUI('updateSettings', { callsign, customImage: imageUrl });
    showToast('Configurações salvas!');
  });

  $('#toggle-officers-list').on('click', function () {
    const newState = !isListVisible;
    postNUI('toggleOfficersList', { visible: newState });
  });

  $('#close-list').on('click', function () {
    isListVisible = false;
    $officersListContainer.fadeOut(200);
    updateToggleButton();
    postNUI('toggleOfficersList', { visible: false });
  });

  $('#minimize-list').on('click', function () {
    $('.list-content').slideToggle(150);
    $(this).find('i').toggleClass('fa-minus fa-plus');
  });

  //========================[ ARRASTE / REDIMENSIONE ]========================//
  $('#resize-handle').on('mousedown', function (e) {
    isResizing = true;
    e.preventDefault();
  });

  $panelHeader.on('mousedown', function (e) {
    panelDragging = true;
    const $c = $officersContainer;
    dragOffsetX = e.clientX - $c.position().left;
    dragOffsetY = e.clientY - $c.position().top;
    $c.css('cursor', 'grabbing');
    e.preventDefault();
  });

  $listHeader.on('mousedown', function (e) {
    listDragging = true;
    const $c = $officersListContainer;
    dragOffsetX = e.clientX - $c.position().left;
    dragOffsetY = e.clientY - $c.position().top;
    $c.css('cursor', 'grabbing');
    e.preventDefault();
  });

  $(document).on('mousemove', function (e) {
    if (panelDragging) movePanel($officersContainer, e, 'panel');
    if (listDragging) movePanel($officersListContainer, e, 'list');
    if (isResizing) {
      const $c = $officersListContainer;
      const newW = e.clientX - $c.offset().left;
      const newH = e.clientY - $c.offset().top;
      $c.css({
        width: `${clamp(newW, 270, 500)}px`,
        height: `${clamp(newH, 150, 800)}px`,
      });
    }
  });

  $(document).on('mouseup', function () {
    if (panelDragging) {
      panelDragging = false;
      $officersContainer.css('cursor', 'default');
      postNUI('savePosition', { type: 'panel', x: panelPosition.x, y: panelPosition.y });
    }
    if (listDragging) {
      listDragging = false;
      $officersListContainer.css('cursor', 'default');
      postNUI('savePosition', { type: 'list', x: listPosition.x, y: listPosition.y });
    }
    if (isResizing) isResizing = false;
  });

  function movePanel($el, e, type) {
    const newX = e.clientX - dragOffsetX;
    const newY = e.clientY - dragOffsetY;
    const WW = $(window).width();
    const WH = $(window).height();
    const CW = $el.width();
    const CH = $el.height();

    const x = clamp(newX, 0, WW - CW);
    const y = clamp(newY, 0, WH - CH);
    $el.css({ left: `${x}px`, top: `${y}px` });

    if (type === 'panel') panelPosition = { x, y };
    if (type === 'list') listPosition = { x, y };
  }

  //========================[ COMISSÁRIO: CORES ]========================//
  function updateCommissionerPanel() {
    const $container = $('#colors-container');
    $container.empty();
    (callsignColorConfigs || []).forEach((cfg, idx) => addColorConfigRow(cfg, idx));
  }

  function addColorConfigRow(cfg, index) {
    const row = $(`
      <div class="color-config-row" data-index="${index}">
        <div class="color-preview" style="background-color:${cfg.color}"></div>
        <div class="color-input-group">
          <input type="text" class="config-name" value="${cfg.name || ''}" placeholder="Nome do Intervalo">
          <input type="number" class="config-min" value="${cfg.min || 0}" placeholder="Mín">
          <span>-</span>
          <input type="number" class="config-max" value="${cfg.max || 0}" placeholder="Máx">
          <input type="text" class="config-color" value="${cfg.color || '#ffffff'}" placeholder="#Cor">
        </div>
        <div class="color-delete-btn" title="Remover"><i class="fas fa-trash"></i></div>
      </div>
    `);

    row.find('.config-color').on('input', function () {
      row.find('.color-preview').css('background-color', $(this).val());
    });

    row.find('.color-delete-btn').on('click', function () {
      row.remove();
    });

    $('#colors-container').append(row);
  }

  $('#add-color-config').on('click', function () {
    addColorConfigRow({ name: 'Novo Intervalo', min: 100, max: 199, color: '#ffffff' }, callsignColorConfigs.length);
  });

  $('#save-colors').on('click', function () {
    const configs = [];
    $('.color-config-row').each(function () {
      const $r = $(this);
      configs.push({
        name: $r.find('.config-name').val(),
        min: parseInt($r.find('.config-min').val()) || 0,
        max: parseInt($r.find('.config-max').val()) || 0,
        color: $r.find('.config-color').val() || '#ffffff',
      });
    });
    callsignColorConfigs = configs;
    postNUI('saveCallsignColors', { colors: configs });
    showToast('Configurações de cor salvas!');
  });

  //========================[ ESC / FECHAR RÁPIDO ]========================//
  document.onkeyup = function (ev) {
    if (ev.key === 'Escape') {
      if ($('#commissioner-panel').is(':visible')) {
        $('#back-to-settings').click();
      } else {
        $officersContainer.fadeOut(200);
        postNUI('closePanel', {});
      }
    }
  };
});
