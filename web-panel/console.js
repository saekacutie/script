const services = [
  { key: 'nginx', name: 'Nginx', unit: 'nginx', ports: '80 / 443', role: 'TLS front end and admin panel' },
  { key: 'wireguard', name: 'WireGuard', unit: 'wg-quick@wg0', ports: '51820 / UDP', role: 'WireGuard VPN interface' },
  { key: 'openvpn', name: 'OpenVPN', unit: 'openvpn', ports: '1194 / UDP', role: 'OpenVPN server' },
  { key: 'ipsec', name: 'IPsec', unit: 'strongswan', ports: '500, 4500 / UDP', role: 'IKEv2 and IPsec service' },
];

const protocols = [
  { key: 'wireguard', name: 'WireGuard', symbol: 'WG' },
  { key: 'openvpn', name: 'OpenVPN', symbol: 'OV' },
  { key: 'ipsec', name: 'IPsec', symbol: 'IP' },
];

const views = {
  overview: ['Overview', 'NODE / OVERVIEW', 'Current health and activity for your VPN node.'],
  services: ['Services', 'NODE / SERVICES', 'Inspect service state and perform allowlisted actions.'],
  sessions: ['Sessions', 'NODE / SESSIONS', 'Current aggregate activity across VPN protocols.'],
  security: ['Security', 'NODE / SECURITY', 'Reported controls and checks for this VPS.'],
  clients: ['VPN accounts', 'USER ACCESS / WIREGUARD', 'Create, inspect, and revoke individual WireGuard credentials.'],
  admins: ['Admin users', 'ACCESS / ADMINISTRATORS', 'Manage administrator access to this VPS.'],
};

const byId = (id) => document.getElementById(id);
const state = { csrfToken: '', username: '', mustChangePassword: false, status: null, selectedService: 'nginx', refreshTimer: null, requestPending: false, clientsPending: false, clientStatuses: null, forcedPasswordChange: false, createdClientConfig: null };

function safeCount(value) {
  const number = Number(value);
  return Number.isFinite(number) && number > 0 ? Math.floor(number) : 0;
}

async function api(path, { method = 'GET', body, csrf = true } = {}) {
  const headers = new Headers();
  if (body !== undefined) headers.set('Content-Type', 'application/json');
  if (csrf && method !== 'GET' && state.csrfToken) headers.set('X-CSRF-Token', state.csrfToken);
  const response = await fetch(path, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
    credentials: 'same-origin',
    cache: 'no-store',
  });
  const data = await response.json().catch(() => ({}));
  if (response.status === 401 && data.error === 'Authentication required.') {
    showLogin('Your session has expired. Sign in again.');
  }
  if (!response.ok) throw new Error(data.error || `Request failed (${response.status}).`);
  return data;
}

async function apiText(path) {
  const response = await fetch(path, { credentials: 'same-origin', cache: 'no-store' });
  const text = await response.text();
  if (response.status === 401) showLogin('Your session has expired. Sign in again.');
  if (!response.ok) {
    let message = `Request failed (${response.status}).`;
    try { message = JSON.parse(text).error || message; } catch {}
    throw new Error(message);
  }
  return text;
}

function showLogin(message = '') {
  state.csrfToken = '';
  state.username = '';
  state.mustChangePassword = false;
  state.clientStatuses = null;
  if (state.refreshTimer) clearInterval(state.refreshTimer);
  state.refreshTimer = null;
  byId('consoleShell').hidden = true;
  byId('loginShell').hidden = false;
  byId('loginError').textContent = message;
  byId('loginError').hidden = !message;
  byId('loginPassword').value = '';
}

function showConsole() {
  byId('loginShell').hidden = true;
  byId('consoleShell').hidden = false;
  byId('accountName').textContent = state.username;
  setView(location.hash.slice(1));
  configureRefresh();
}

async function restoreSession() {
  try {
    const session = await api('/api/session', { csrf: false });
    if (!session.authenticated) {
      showLogin();
      return;
    }
    state.username = session.username;
    state.csrfToken = session.csrfToken;
    state.mustChangePassword = session.mustChangePassword;
    showConsole();
    if (state.mustChangePassword) openPasswordDialog(true);
    else refreshStatus();
  } catch {
    showLogin('The admin service is unavailable. Try again shortly.');
  }
}

function setNotice(message, error = false) {
  const notice = byId('actionNotice');
  notice.textContent = message;
  notice.classList.toggle('is-error', error);
  notice.hidden = false;
  clearTimeout(setNotice.timeout);
  setNotice.timeout = setTimeout(() => { notice.hidden = true; }, 6000);
}

function setDot(node, status) {
  node.className = `status-dot ${status === 'active' ? 'is-active' : status === 'inactive' ? 'is-inactive' : 'is-unknown'}`;
}

function addStatusLabel(node, status) {
  node.className = `state-label ${status === 'active' ? 'is-active' : status === 'inactive' ? 'is-inactive' : 'is-unknown'}`;
  node.replaceChildren();
  const dot = document.createElement('span');
  setDot(dot, status);
  const text = document.createElement('span');
  text.textContent = status === 'active' ? 'Active' : status === 'inactive' ? 'Inactive' : 'Unknown';
  node.append(dot, text);
}

function serviceStatus(key) {
  return state.status?.protocols?.services?.[key] || 'unknown';
}

function serviceUnit(service) {
  return state.status?.protocols?.service_units?.[service.key] || service.unit;
}

function protocolCount(key) {
  const item = state.status?.protocols?.[key];
  return safeCount(item?.active_clients ?? item?.active_tunnels);
}

function firewallStatus() {
  const enabled = state.status?.protocols?.firewall?.enabled;
  return enabled === true ? 'Enabled' : enabled === false ? 'Inactive' : 'Unknown';
}

function formatTime(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'Timestamp unavailable';
  return new Intl.DateTimeFormat(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit' }).format(date);
}

function formatDuration(seconds) {
  const total = safeCount(seconds);
  if (total < 60) return 'Less than a minute';
  const days = Math.floor(total / 86400);
  const hours = Math.floor((total % 86400) / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  if (days) return `${days}d ${hours}h`;
  if (hours) return `${hours}h ${minutes}m`;
  return `${minutes}m`;
}

function formatClientDate(value) {
  if (!value) return 'No expiry';
  const date = new Date(value * 1000);
  return Number.isNaN(date.getTime()) ? 'Date unavailable' : new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(date);
}

function relativeClientTime(value) {
  if (!value) return 'No handshake yet';
  return `${formatDuration(Date.now() / 1000 - value)} ago`;
}

function formatBytes(value) {
  const bytes = safeCount(value);
  if (bytes < 1024) return `${bytes} B`;
  const units = ['KB', 'MB', 'GB', 'TB'];
  let amount = bytes / 1024;
  let index = 0;
  while (amount >= 1024 && index < units.length - 1) {
    amount /= 1024;
    index += 1;
  }
  return `${amount.toFixed(amount >= 100 ? 0 : 1)} ${units[index]}`;
}

function renderOverview() {
  const serviceData = state.status?.protocols?.services || {};
  const activeServices = services.filter((service) => serviceData[service.key] === 'active').length;
  const activeSessions = protocols.reduce((sum, protocol) => sum + protocolCount(protocol.key), 0);
  const firewall = firewallStatus();

  byId('activeSessions').textContent = String(activeSessions);
  byId('onlineServices').textContent = String(activeServices);
  byId('serviceTotal').textContent = `/ ${services.length}`;
  byId('firewallMetric').textContent = firewall;
  byId('securityFirewall').textContent = firewall;
  byId('securitySsh').textContent = `Mode ${state.status?.ssh_banner || 'Unknown'}`;
  byId('securityCert').textContent = 'Not checked';

  const maximum = Math.max(1, ...protocols.map((protocol) => protocolCount(protocol.key)));
  const list = byId('overviewProtocols');
  list.replaceChildren();
  for (const protocol of protocols) {
    const active = protocolCount(protocol.key);
    const row = document.createElement('div');
    row.className = 'protocol-row';
    const name = document.createElement('div');
    name.className = 'protocol-name';
    const symbol = document.createElement('span');
    symbol.className = 'protocol-symbol';
    symbol.textContent = protocol.symbol;
    const label = document.createElement('span');
    label.textContent = protocol.name;
    name.append(symbol, label);
    const track = document.createElement('div');
    track.className = 'protocol-track';
    const fill = document.createElement('div');
    fill.className = 'protocol-fill';
    fill.style.width = `${Math.round(active / maximum * 100)}%`;
    track.append(fill);
    const count = document.createElement('span');
    count.className = 'protocol-count';
    count.textContent = String(active);
    row.append(name, track, count);
    list.append(row);
  }

  const summary = byId('overviewServices');
  summary.replaceChildren();
  for (const service of services) {
    const row = document.createElement('div');
    row.className = 'service-mini';
    const dot = document.createElement('span');
    setDot(dot, serviceData[service.key]);
    const name = document.createElement('strong');
    name.textContent = service.name;
    const value = document.createElement('span');
    value.textContent = serviceData[service.key] || 'Unknown';
    row.append(dot, name, value);
    summary.append(row);
  }
}

function renderInspector() {
  const service = services.find((entry) => entry.key === state.selectedService) || services[0];
  const status = serviceStatus(service.key);
  byId('selectedServiceName').textContent = service.name;
  byId('selectedServiceStatus').textContent = status === 'unknown' ? 'Unknown' : status;
  byId('selectedServiceUnit').textContent = serviceUnit(service);
  byId('selectedServicePorts').textContent = service.ports;
  byId('selectedServiceDescription').textContent = service.role;
  byId('restartServiceButton').disabled = state.mustChangePassword;
  setDot(byId('selectedServiceDot'), status);
}

function renderServices() {
  const query = byId('serviceSearch').value.trim().toLowerCase();
  const filter = byId('serviceFilter').value;
  const matches = services.filter((service) => {
    const status = serviceStatus(service.key);
    const textMatch = `${service.name} ${service.unit} ${service.role}`.toLowerCase().includes(query);
    const statusMatch = filter === 'all' || (filter === 'active' ? status === 'active' : status !== 'active');
    return textMatch && statusMatch;
  });

  const body = byId('serviceTableBody');
  body.replaceChildren();
  for (const service of matches) {
    const status = serviceStatus(service.key);
    const row = document.createElement('tr');
    row.classList.toggle('is-selected', service.key === state.selectedService);
    const nameCell = document.createElement('td');
    const select = document.createElement('button');
    select.className = 'service-select';
    select.type = 'button';
    select.dataset.service = service.key;
    select.setAttribute('aria-pressed', String(service.key === state.selectedService));
    select.textContent = service.name;
    nameCell.append(select);
    const unitCell = document.createElement('td');
    unitCell.textContent = serviceUnit(service);
    const stateCell = document.createElement('td');
    const stateLabel = document.createElement('span');
    addStatusLabel(stateLabel, status);
    stateCell.append(stateLabel);
    const portCell = document.createElement('td');
    portCell.textContent = service.ports;
    row.append(nameCell, unitCell, stateCell, portCell);
    body.append(row);
  }
  byId('serviceResultCount').textContent = `${matches.length} of ${services.length} services`;
  byId('servicesEmpty').hidden = matches.length > 0;
  renderInspector();
}

function renderSessions() {
  const filter = byId('sessionFilter').value;
  const records = protocols.map((protocol) => {
    const details = state.status?.protocols?.[protocol.key] || {};
    const active = safeCount(details.active_clients ?? details.active_tunnels);
    return { ...protocol, active, total: protocol.key === 'wireguard' ? safeCount(details.total_clients) : active };
  }).filter((record) => filter === 'all' || (filter === 'active' ? record.active > 0 : record.active === 0));
  const maximum = Math.max(1, ...records.map((record) => record.active));
  const list = byId('sessionList');
  list.replaceChildren();
  for (const record of records) {
    const row = document.createElement('div');
    row.className = 'session-row';
    const name = document.createElement('div');
    name.className = 'session-protocol';
    const symbol = document.createElement('span');
    symbol.className = 'protocol-symbol';
    symbol.textContent = record.symbol;
    const label = document.createElement('span');
    label.textContent = record.name;
    name.append(symbol, label);
    const meter = document.createElement('div');
    meter.className = 'session-meter';
    const fill = document.createElement('span');
    fill.style.width = `${Math.round(record.active / maximum * 100)}%`;
    meter.append(fill);
    const count = document.createElement('div');
    count.className = 'session-total';
    const amount = document.createElement('strong');
    amount.textContent = String(record.active);
    count.append(amount, document.createTextNode(record.key === 'wireguard' ? ` active / ${record.total} peers` : ' active'));
    const badge = document.createElement('span');
    badge.className = `session-state ${record.active > 0 ? 'is-active' : 'is-idle'}`;
    badge.textContent = record.active > 0 ? 'Activity' : 'Idle';
    row.append(name, meter, count, badge);
    list.append(row);
  }
  byId('sessionsEmpty').hidden = records.length > 0;
}

function renderSecurity() {
  const firewall = firewallStatus();
  const banner = `Mode ${state.status?.ssh_banner || 'Unknown'}`;
  byId('firewallDetail').textContent = firewall;
  byId('sshDetail').textContent = banner;
  byId('certificateDetail').textContent = 'Not checked';
}

function renderAdblock(stateData) {
  const enabled = stateData?.enabled === true;
  const count = Number(stateData?.hostCount) || 0;
  const toggle = byId('adblockToggle');
  byId('adblockStatus').textContent = enabled ? 'On' : 'Off';
  byId('adblockSummary').textContent = enabled
    ? `VPN clients only · ${count.toLocaleString()} blocked hosts`
    : 'VPN clients only · filtered resolver is off';
  byId('adblockDetails').textContent = stateData?.lastError
    ? `Last update error: ${stateData.lastError}`
    : stateData?.updatedAt
      ? `Updated ${formatTime(stateData.updatedAt)} · ${stateData.source || 'managed hosts list'}`
      : 'Waiting for resolver status';
  toggle.textContent = enabled ? 'Disable' : 'Enable';
  toggle.setAttribute('aria-pressed', String(enabled));
  toggle.disabled = state.requestPending;
}

async function loadAdblock() {
  try {
    const response = await api('/api/adblock');
    renderAdblock(response.adblock);
  } catch (error) {
    byId('adblockDetails').textContent = error.message;
  }
}

async function toggleAdblock() {
  const toggle = byId('adblockToggle');
  const enabled = toggle.getAttribute('aria-pressed') !== 'true';
  toggle.disabled = true;
  toggle.textContent = enabled ? 'Enabling...' : 'Disabling...';
  setNotice(`${enabled ? 'Enabling' : 'Disabling'} VPN DNS ad blocking...`);
  try {
    const response = await api('/api/adblock', { method: 'POST', body: { enabled } });
    renderAdblock(response.adblock);
    setNotice(`VPN DNS ad blocking ${enabled ? 'enabled' : 'disabled'}.`);
  } catch (error) {
    renderAdblock({ enabled: !enabled, lastError: error.message });
    setNotice(error.message, true);
  }
}

function renderStatus() {
  const data = state.status;
  const statuses = data.protocols?.services || {};
  const activeServices = services.filter((service) => statuses[service.key] === 'active').length;
  const reportDate = new Date(data.generated_at);
  const age = Number.isNaN(reportDate.getTime()) ? null : Math.max(0, (Date.now() - reportDate.getTime()) / 1000);
  const stale = age !== null && age > 90;
  const domain = data.domain || 'Domain not reported';

  byId('domainLabel').textContent = domain;
  byId('workspaceDomain').textContent = domain;
  byId('nodeHealth').className = `health-badge ${stale ? 'is-stale' : activeServices === services.length ? 'is-online' : activeServices ? 'is-stale' : 'is-offline'}`;
  byId('nodeHealthLabel').textContent = stale ? 'Stale report' : activeServices === services.length ? 'Operational' : activeServices ? 'Degraded' : 'No services online';
  byId('sidebarStatus').textContent = stale ? 'Telemetry stale' : 'Connected';
  byId('sidebarUpdated').textContent = age === null ? 'Timestamp unavailable' : `Report ${formatTime(data.generated_at)}`;
  byId('updatedAt').textContent = age === null ? 'Timestamp unavailable' : `Last report ${formatTime(data.generated_at)}`;
  renderOverview();
  renderServices();
  renderSessions();
  renderSecurity();
  loadAdblock();
}

function markUnavailable() {
  byId('errorBanner').hidden = false;
  byId('sidebarStatus').textContent = 'Disconnected';
  byId('sidebarUpdated').textContent = 'No telemetry received';
  byId('nodeHealth').className = 'health-badge is-offline';
  byId('nodeHealthLabel').textContent = 'Unavailable';
  byId('updatedAt').textContent = 'Status endpoint unavailable';
}

async function refreshStatus() {
  if (state.requestPending) return;
  state.requestPending = true;
  const button = byId('refreshButton');
  button.disabled = true;
  button.classList.add('is-loading');
  try {
    const data = await api('/api/status');
    if (!data.protocols) throw new Error('Status payload is invalid.');
    state.status = data;
    byId('errorBanner').hidden = true;
    renderStatus();
  } catch {
    markUnavailable();
  } finally {
    state.requestPending = false;
    button.disabled = false;
    button.classList.remove('is-loading');
  }
}

function setView(name, updateHash = false) {
  const view = views[name] ? name : 'overview';
  for (const panel of document.querySelectorAll('[data-view-panel]')) panel.hidden = panel.dataset.viewPanel !== view;
  for (const button of document.querySelectorAll('.nav-button[data-view]')) {
    if (button.dataset.view === view) button.setAttribute('aria-current', 'page');
    else button.removeAttribute('aria-current');
  }
  byId('viewHeading').textContent = views[view][0];
  byId('viewKicker').textContent = views[view][1];
  byId('viewDescription').textContent = views[view][2];
  if (updateHash && location.hash !== `#${view}`) history.pushState(null, '', `#${view}`);
  if (view === 'admins') loadAdminUsers();
  if (view === 'clients') loadVPNClients();
}

function configureRefresh() {
  if (state.refreshTimer) clearInterval(state.refreshTimer);
  const seconds = Number(byId('refreshRate').value);
  if (seconds > 0) state.refreshTimer = setInterval(() => {
    if (document.hidden) return;
    refreshStatus();
    if (location.hash === '#clients') loadVPNClients();
  }, seconds * 1000);
}

function openPasswordDialog(forced = false) {
  state.forcedPasswordChange = forced;
  byId('passwordForm').reset();
  byId('passwordError').hidden = true;
  byId('passwordDialogTitle').textContent = forced ? 'Set a new password' : 'Change password';
  byId('passwordDialogCopy').textContent = forced
    ? 'Your temporary password must be replaced before using the control panel. Choose at least 14 characters.'
    : 'Choose a unique password with at least 14 characters.';
  byId('cancelPasswordButton').hidden = forced;
  byId('passwordDialog').showModal();
  byId('currentPassword').focus();
}

async function loadAdminUsers() {
  try {
    const response = await api('/api/users');
    const list = byId('adminUsersList');
    list.replaceChildren();
    for (const user of response.users) {
      const row = document.createElement('div');
      row.className = 'admin-user-row';
      const identity = document.createElement('div');
      identity.className = 'admin-user-identity';
      const avatar = document.createElement('span');
      avatar.className = 'admin-avatar';
      avatar.textContent = user.username.slice(0, 2).toUpperCase();
      const username = document.createElement('strong');
      username.textContent = user.username;
      identity.append(avatar, username);
      const role = document.createElement('span');
      role.className = 'admin-user-role';
      role.textContent = user.username === state.username ? 'Current admin' : 'Administrator';
      const remove = document.createElement('button');
      remove.className = 'admin-remove-button';
      remove.type = 'button';
      remove.textContent = user.username === state.username ? 'You' : 'Remove';
      remove.disabled = user.username === state.username || response.users.length === 1;
      remove.setAttribute('aria-label', `Remove admin ${user.username}`);
      remove.addEventListener('click', () => removeAdmin(user.username));
      row.append(identity, role, remove);
      list.append(row);
    }
    byId('adminCount').textContent = `${response.users.length} account${response.users.length === 1 ? '' : 's'}`;
    byId('adminUsersEmpty').hidden = response.users.length > 0;
  } catch (error) {
    setNotice(error.message, true);
  }
}

async function removeAdmin(username) {
  if (!window.confirm(`Remove administrator ${username}? Their active sessions will stop working.`)) return;
  try {
    await api(`/api/users/${encodeURIComponent(username)}`, { method: 'DELETE' });
    setNotice(`Administrator ${username} removed.`);
    await loadAdminUsers();
  } catch (error) {
    setNotice(error.message, true);
  }
}

async function signIn(event) {
  event.preventDefault();
  const button = event.submitter || event.currentTarget.querySelector('[type="submit"]');
  const error = byId('loginError');
  error.hidden = true;
  button.disabled = true;
  try {
    const response = await api('/api/login', {
      method: 'POST',
      csrf: false,
      body: { username: byId('loginUsername').value.trim(), password: byId('loginPassword').value },
    });
    state.username = response.username;
    state.csrfToken = response.csrfToken;
    state.mustChangePassword = response.mustChangePassword;
    byId('loginPassword').value = '';
    showConsole();
    if (state.mustChangePassword) openPasswordDialog(true);
    else refreshStatus();
  } catch (requestError) {
    error.textContent = requestError.message;
    error.hidden = false;
  } finally {
    button.disabled = false;
  }
}

async function changePassword(event) {
  event.preventDefault();
  const error = byId('passwordError');
  error.hidden = true;
  const next = byId('newPassword').value;
  if (next !== byId('confirmPassword').value) {
    error.textContent = 'The new passwords do not match.';
    error.hidden = false;
    return;
  }
  try {
    const response = await api('/api/password', {
      method: 'POST',
      body: { oldPassword: byId('currentPassword').value, newPassword: next },
    });
    state.csrfToken = response.csrfToken;
    state.mustChangePassword = false;
    byId('passwordDialog').close();
    setNotice('Password updated. Other sessions for this account were signed out.');
    refreshStatus();
  } catch (requestError) {
    error.textContent = requestError.message;
    error.hidden = false;
  }
}

async function createAdmin(event) {
  event.preventDefault();
  const form = byId('addAdminForm');
  const error = byId('addAdminError');
  error.hidden = true;
  try {
    const response = await api('/api/users', {
      method: 'POST',
      body: { username: byId('newAdminUsername').value.trim(), password: byId('newAdminPassword').value },
    });
    form.reset();
    setNotice(`Admin ${response.username} created. They will be required to change the temporary password at first sign-in.`);
    await loadAdminUsers();
  } catch (requestError) {
    error.textContent = requestError.message;
    error.hidden = false;
  }
}

function downloadConfig(username, config) {
  const blobUrl = URL.createObjectURL(new Blob([config], { type: 'text/plain;charset=utf-8' }));
  const link = document.createElement('a');
  link.href = blobUrl;
  link.download = `${username}.conf`;
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(blobUrl), 1000);
}

function renderVPNClients(clients) {
  const list = byId('clientList');
  list.replaceChildren();
  for (const client of clients) {
    const row = document.createElement('article');
    row.className = 'client-row';
    const heading = document.createElement('div');
    heading.className = 'client-identity';
    const name = document.createElement('h4');
    name.textContent = client.username;
    const status = document.createElement('span');
    status.className = `client-state is-${client.status}`;
    status.textContent = client.status === 'connected' ? 'Connected' : client.status === 'expired' ? 'Expired' : 'Idle';
    heading.append(name, status);

    const details = document.createElement('dl');
    details.className = 'client-details';
    const fields = [
      ['Protocol / address', `WireGuard · ${client.address}`],
      ['Server endpoint', client.endpoint || 'No endpoint observed'],
      ['Account age', formatDuration(client.ageSeconds)],
      ['Access remaining', client.remainingSeconds === null ? 'No expiry' : formatDuration(client.remainingSeconds)],
      ['Uploaded', formatBytes(client.bytesReceived)],
      ['Downloaded', formatBytes(client.bytesSent)],
      ['Last handshake', relativeClientTime(client.lastHandshake)],
    ];
    for (const [label, value] of fields) {
      const item = document.createElement('div');
      const term = document.createElement('dt');
      term.textContent = label;
      const description = document.createElement('dd');
      description.textContent = value;
      item.append(term, description);
      details.append(item);
    }

    const actions = document.createElement('div');
    actions.className = 'client-actions';
    const download = document.createElement('button');
    download.className = 'button button-quiet';
    download.type = 'button';
    download.textContent = 'Download config';
    download.addEventListener('click', () => downloadVPNClientConfig(client));
    const reset = document.createElement('button');
    reset.className = 'button button-quiet';
    reset.type = 'button';
    reset.textContent = client.portalReady ? 'Reset login' : 'Enable login';
    reset.addEventListener('click', () => resetVPNClientPassword(client));
    const revoke = document.createElement('button');
    revoke.className = 'client-revoke-button';
    revoke.type = 'button';
    revoke.textContent = 'Revoke';
    revoke.addEventListener('click', () => revokeVPNClient(client));
    actions.append(download, reset, revoke);
    row.append(heading, details, actions);
    list.append(row);
  }
  byId('clientCount').textContent = `${clients.length} account${clients.length === 1 ? '' : 's'}`;
  byId('clientsEmpty').hidden = clients.length > 0;
}

async function loadVPNClients() {
  if (state.clientsPending) return;
  state.clientsPending = true;
  try {
    const response = await api('/api/clients');
    if (state.clientStatuses) {
      for (const client of response.clients) {
        const previous = state.clientStatuses[client.id];
        if (previous && previous !== client.status) {
          setNotice(`${client.username} status: ${previous} -> ${client.status}.`, client.status !== 'connected');
        }
      }
    }
    state.clientStatuses = Object.fromEntries(response.clients.map((client) => [client.id, client.status]));
    renderVPNClients(response.clients);
  } catch (error) {
    setNotice(error.message, true);
  } finally {
    state.clientsPending = false;
  }
}

async function createVPNClient(event) {
  event.preventDefault();
  const form = byId('createClientForm');
  const button = byId('createClientButton');
  const error = byId('createClientError');
  error.hidden = true;
  button.disabled = true;
  button.querySelector('span').textContent = 'Creating account...';
  setNotice('Creating WireGuard account...');
  try {
    const response = await api('/api/clients', {
      method: 'POST',
      body: { username: byId('newClientUsername').value.trim(), durationDays: Number(byId('clientDuration').value) },
    });
    state.createdClientConfig = { username: response.client.username, config: response.config, temporaryPassword: response.client.temporaryPassword };
    byId('clientConfigTitle').textContent = `${response.client.username} created`;
    byId('clientConfigCopy').textContent = `VPN address ${response.client.address} · ${response.client.expiresAt ? `expires ${formatClientDate(response.client.expiresAt)}` : 'no expiry'}.`;
    byId('createdPortalUsername').textContent = response.client.username;
    byId('createdPortalPassword').textContent = response.client.temporaryPassword;
    byId('downloadCreatedConfigButton').hidden = false;
    form.reset();
    byId('clientDuration').value = '30';
    byId('clientConfigDialog').showModal();
    setNotice(`VPN account ${response.client.username} created. Download its configuration to connect.`);
    await loadVPNClients();
  } catch (requestError) {
    error.textContent = requestError.message;
    error.hidden = false;
    setNotice(requestError.message, true);
  } finally {
    button.disabled = false;
    button.querySelector('span').textContent = 'Create account';
  }
}

async function downloadVPNClientConfig(client) {
  try {
    const config = await apiText(`/api/clients/${encodeURIComponent(client.id)}/config`);
    downloadConfig(client.username, config);
    setNotice(`Downloaded WireGuard config for ${client.username}. Keep it private.`);
  } catch (error) {
    setNotice(error.message, true);
  }
}

async function revokeVPNClient(client) {
  if (!window.confirm(`Revoke VPN access for ${client.username}? The client will be disconnected.`)) return;
  setNotice(`Revoking VPN account ${client.username}...`);
  try {
    await api(`/api/clients/${encodeURIComponent(client.id)}`, { method: 'DELETE' });
    setNotice(`VPN account ${client.username} revoked.`);
    await loadVPNClients();
  } catch (error) {
    setNotice(error.message, true);
  }
}

async function resetVPNClientPassword(client) {
  if (!window.confirm(`Reset the portal password for ${client.username}? Their active portal sessions will end.`)) return;
  setNotice(`Resetting portal login for ${client.username}...`);
  try {
    const result = await api(`/api/clients/${encodeURIComponent(client.id)}/password`, { method: 'POST', body: {} });
    state.createdClientConfig = { username: result.username, temporaryPassword: result.temporaryPassword, config: null };
    byId('clientConfigTitle').textContent = 'Portal password reset';
    byId('clientConfigCopy').textContent = 'Share the temporary password securely. The user must change it at their next sign-in.';
    byId('createdPortalUsername').textContent = result.username;
    byId('createdPortalPassword').textContent = result.temporaryPassword;
    byId('downloadCreatedConfigButton').hidden = true;
    byId('clientConfigDialog').showModal();
    setNotice(`Portal login reset for ${result.username}.`);
    await loadVPNClients();
  } catch (error) {
    setNotice(error.message, true);
  }
}

function downloadCreatedClientConfig() {
  if (!state.createdClientConfig?.config) return;
  downloadConfig(state.createdClientConfig.username, state.createdClientConfig.config);
  setNotice(`Downloaded WireGuard config for ${state.createdClientConfig.username}. Keep it private.`);
  byId('clientConfigDialog').close();
}

function openRestartDialog() {
  const service = services.find((entry) => entry.key === state.selectedService);
  if (!service) return;
  byId('restartTarget').textContent = `${service.name} (${service.unit})`;
  byId('restartError').hidden = true;
  byId('restartDialog').showModal();
}

async function restartService(event) {
  event.preventDefault();
  const button = byId('confirmRestartButton');
  const error = byId('restartError');
  button.disabled = true;
  error.hidden = true;
  try {
    const result = await api(`/api/services/${state.selectedService}/restart`, { method: 'POST', body: {} });
    byId('restartDialog').close();
    setNotice(`${services.find((service) => service.key === result.service).name} restart requested.`);
    await refreshStatus();
  } catch (requestError) {
    error.textContent = requestError.message;
    error.hidden = false;
  } finally {
    button.disabled = false;
  }
}

async function signOut() {
  try {
    await api('/api/logout', { method: 'POST', body: {} });
  } catch {
    // The session may already have expired.
  }
  byId('passwordDialog').close();
  showLogin();
}

document.querySelectorAll('[data-view]').forEach((button) => button.addEventListener('click', () => setView(button.dataset.view, true)));
window.addEventListener('popstate', () => setView(location.hash.slice(1)));
window.addEventListener('hashchange', () => setView(location.hash.slice(1)));
byId('loginForm').addEventListener('submit', signIn);
byId('logoutButton').addEventListener('click', signOut);
byId('changePasswordButton').addEventListener('click', () => openPasswordDialog(false));
byId('passwordForm').addEventListener('submit', changePassword);
byId('passwordDialog').addEventListener('cancel', (event) => { if (state.forcedPasswordChange) event.preventDefault(); });
byId('cancelPasswordButton').addEventListener('click', () => byId('passwordDialog').close());
byId('addAdminForm').addEventListener('submit', createAdmin);
byId('reloadAdminsButton').addEventListener('click', loadAdminUsers);
byId('createClientForm').addEventListener('submit', createVPNClient);
byId('reloadClientsButton').addEventListener('click', loadVPNClients);
byId('downloadCreatedConfigButton').addEventListener('click', downloadCreatedClientConfig);
byId('copyCreatedPasswordButton').addEventListener('click', async () => {
  if (!state.createdClientConfig?.temporaryPassword) return;
  try {
    await navigator.clipboard.writeText(state.createdClientConfig.temporaryPassword);
    setNotice('Temporary password copied. Share it securely.');
  } catch {
    setNotice('Clipboard access is unavailable. Select and copy the displayed password.', true);
  }
});
byId('closeClientConfigButton').addEventListener('click', () => byId('clientConfigDialog').close());
byId('clientConfigDialog').addEventListener('close', () => {
  state.createdClientConfig = null;
  byId('createdPortalUsername').textContent = '—';
  byId('createdPortalPassword').textContent = '—';
});
byId('refreshButton').addEventListener('click', refreshStatus);
byId('retryButton').addEventListener('click', refreshStatus);
byId('adblockToggle').addEventListener('click', toggleAdblock);
byId('refreshRate').addEventListener('change', configureRefresh);
byId('serviceSearch').addEventListener('input', renderServices);
byId('serviceFilter').addEventListener('change', renderServices);
byId('sessionFilter').addEventListener('change', renderSessions);
byId('serviceTableBody').addEventListener('click', (event) => {
  const select = event.target.closest('[data-service]');
  if (!select) return;
  state.selectedService = select.dataset.service;
  renderServices();
});
byId('restartServiceButton').addEventListener('click', openRestartDialog);
byId('restartForm').addEventListener('submit', restartService);
byId('cancelRestartButton').addEventListener('click', () => byId('restartDialog').close());

restoreSession();