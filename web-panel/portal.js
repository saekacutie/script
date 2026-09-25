const byId = (id) => document.getElementById(id);
const state = {
  csrfToken: '',
  username: '',
  mustChangePassword: false,
  refreshTimer: null,
  requestPending: false,
  previousStatus: null,
};

async function request(path, { method = 'GET', body, csrf = true } = {}) {
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
  const text = await response.text();
  let data = text;
  if (response.headers.get('Content-Type')?.startsWith('application/json')) {
    try { data = JSON.parse(text); } catch { data = {}; }
  }
  if (response.status === 401) {
    showLogin(path === '/api/portal/account' ? 'Your account session ended. Sign in again.' : 'Sign in to continue.');
  }
  if (!response.ok) {
    const error = new Error(data?.error || `Request failed (${response.status}).`);
    error.status = response.status;
    throw error;
  }
  return data;
}

function formatDuration(seconds) {
  const total = Math.max(0, Math.floor(Number(seconds) || 0));
  if (total < 60) return 'Less than a minute';
  const days = Math.floor(total / 86400);
  const hours = Math.floor((total % 86400) / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  if (days) return `${days}d ${hours}h`;
  if (hours) return `${hours}h ${minutes}m`;
  return `${minutes}m`;
}

function formatBytes(value) {
  const bytes = Math.max(0, Number(value) || 0);
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

function formatDate(timestamp) {
  if (!timestamp) return 'No expiry';
  const date = new Date(timestamp * 1000);
  return Number.isNaN(date.getTime()) ? 'Date unavailable' : new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(date);
}

function relativeHandshake(ageSeconds) {
  if (ageSeconds === null || ageSeconds === undefined) return 'No handshake recorded';
  if (ageSeconds < 60) return 'Just now';
  return `${formatDuration(ageSeconds)} ago`;
}

function showActivity(message, error = false) {
  const notice = byId('activityPunch');
  byId('activityPunchText').textContent = message;
  notice.classList.toggle('is-error', error);
  notice.hidden = false;
  clearTimeout(showActivity.timeout);
  showActivity.timeout = setTimeout(() => { notice.hidden = true; }, 4200);
}

function showLogin(message = '') {
  if (state.refreshTimer) clearInterval(state.refreshTimer);
  state.refreshTimer = null;
  state.csrfToken = '';
  state.mustChangePassword = false;
  state.previousStatus = null;
  byId('portalDashboard').hidden = true;
  byId('portalLogin').hidden = false;
  byId('portalPasswordButton').hidden = true;
  byId('portalSignOutButton').hidden = true;
  byId('portalLoginError').textContent = message;
  byId('portalLoginError').hidden = !message;
  byId('portalPassword').value = '';
  if (byId('portalPasswordDialog').open) byId('portalPasswordDialog').close();
}

function openPasswordDialog(forced = false) {
  state.mustChangePassword = forced;
  byId('portalPasswordForm').reset();
  byId('portalPasswordError').hidden = true;
  byId('portalPasswordTitle').textContent = forced ? 'Set your password' : 'Change password';
  byId('portalPasswordCopy').textContent = forced
    ? 'Replace the temporary password before viewing your account. Use at least 14 characters.'
    : 'Choose a unique password with at least 14 characters.';
  byId('cancelPortalPassword').hidden = forced;
  byId('portalPasswordDialog').showModal();
  byId('portalCurrentPassword').focus();
}

function showDashboard(username) {
  state.username = username;
  byId('portalAccountName').textContent = username;
  byId('portalDashboard').hidden = false;
  byId('portalLogin').hidden = true;
  byId('portalPasswordButton').hidden = false;
  byId('portalSignOutButton').hidden = false;
  if (state.mustChangePassword) openPasswordDialog(true);
  else {
    loadAccount();
    state.refreshTimer = setInterval(() => {
      if (!document.hidden) loadAccount();
    }, 5000);
  }
}

async function restorePortalSession() {
  byId('portalHost').textContent = location.host;
  try {
    const session = await request('/api/portal/session', { csrf: false });
    if (!session.authenticated) {
      showLogin();
      return;
    }
    state.csrfToken = session.csrfToken;
    state.mustChangePassword = session.mustChangePassword;
    showDashboard(session.username);
  } catch (error) {
    showLogin(error.message);
  }
}

function renderAccount(account) {
  const previousStatus = state.previousStatus;
  state.previousStatus = account.status;
  const connected = account.status === 'connected';
  const statusText = connected ? 'Connected' : account.status === 'expired' ? 'Expired' : 'Idle';
  byId('accountStatus').textContent = statusText;
  byId('accountStatusHint').textContent = connected ? 'Recent WireGuard handshake' : account.status === 'expired' ? 'Access has ended' : 'No recent handshake detected';
  byId('portalLiveIndicator').classList.toggle('is-offline', !connected);
  byId('liveDot').className = `portal-live-dot ${connected ? 'is-online' : 'is-offline'}`;
  byId('liveLabel').textContent = connected ? 'Connected now' : account.status === 'expired' ? 'Access expired' : 'Not connected';
  byId('lastUpdated').textContent = `Updated ${new Intl.DateTimeFormat(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit' }).format(new Date())}`;
  byId('accountAddress').textContent = account.address;
  byId('accountAge').textContent = formatDuration(account.ageSeconds);
  byId('accountRemaining').textContent = account.remainingSeconds === null ? 'No expiry' : account.status === 'expired' ? 'Expired' : formatDuration(account.remainingSeconds);
  byId('accountExpiry').textContent = account.expiresAt ? formatDate(account.expiresAt) : 'Access does not expire';
  byId('accountEndpoint').textContent = account.endpoint || 'No endpoint observed';
  byId('accountHandshake').textContent = relativeHandshake(account.handshakeAgeSeconds);
  byId('accountUploaded').textContent = formatBytes(account.bytesReceived);
  byId('accountDownloaded').textContent = formatBytes(account.bytesSent);
  byId('accountTerm').textContent = account.durationDays ? `${account.durationDays} days` : 'No expiry';
  byId('accountCreated').textContent = formatDate(account.createdAt);
  document.querySelector('.portal-status-metric').classList.toggle('is-offline', !connected);
  if (previousStatus && previousStatus !== account.status) {
    showActivity(`VPN status changed: ${previousStatus} → ${account.status}.`, !connected);
  }
  byId('portalError').hidden = true;
}

async function loadAccount() {
  if (state.requestPending || state.mustChangePassword) return;
  state.requestPending = true;
  try {
    const response = await request('/api/portal/account');
    renderAccount(response.account);
  } catch (error) {
    if (error.status === 410) {
      showLogin('This account has expired or is no longer active. Contact your administrator.');
    } else if (error.status !== 401 && error.status !== 428) {
      byId('portalError').textContent = error.message;
      byId('portalError').hidden = false;
    }
  } finally {
    state.requestPending = false;
  }
}

async function signIn(event) {
  event.preventDefault();
  const button = byId('portalLoginSubmit');
  const error = byId('portalLoginError');
  error.hidden = true;
  button.disabled = true;
  button.querySelector('span').textContent = 'Signing in...';
  try {
    const session = await request('/api/portal/login', {
      method: 'POST',
      csrf: false,
      body: { username: byId('portalUsername').value.trim(), password: byId('portalPassword').value },
    });
    state.csrfToken = session.csrfToken;
    state.mustChangePassword = session.mustChangePassword;
    byId('portalPassword').value = '';
    showDashboard(session.username);
    showActivity('Signed in to your SAEKA VPN account.');
  } catch (requestError) {
    error.textContent = requestError.message;
    error.hidden = false;
  } finally {
    button.disabled = false;
    button.querySelector('span').textContent = 'Sign in';
  }
}

async function changePassword(event) {
  event.preventDefault();
  const error = byId('portalPasswordError');
  const button = byId('savePortalPassword');
  error.hidden = true;
  const nextPassword = byId('portalNewPassword').value;
  if (nextPassword !== byId('portalConfirmPassword').value) {
    error.textContent = 'The new passwords do not match.';
    error.hidden = false;
    return;
  }
  button.disabled = true;
  try {
    const session = await request('/api/portal/password', {
      method: 'POST',
      body: { oldPassword: byId('portalCurrentPassword').value, newPassword: nextPassword },
    });
    state.csrfToken = session.csrfToken;
    state.mustChangePassword = false;
    byId('portalPasswordDialog').close();
    showActivity('Password updated. Other account sessions were signed out.');
    if (!state.refreshTimer) {
      loadAccount();
      state.refreshTimer = setInterval(() => { if (!document.hidden) loadAccount(); }, 5000);
    } else {
      loadAccount();
    }
  } catch (requestError) {
    error.textContent = requestError.message;
    error.hidden = false;
  } finally {
    button.disabled = false;
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

async function downloadPortalConfig() {
  const button = byId('downloadPortalConfig');
  button.disabled = true;
  showActivity('Preparing your private WireGuard configuration...');
  try {
    const response = await fetch('/api/portal/config', { credentials: 'same-origin', cache: 'no-store' });
    const text = await response.text();
    if (!response.ok) {
      let message = `Request failed (${response.status}).`;
      try { message = JSON.parse(text).error || message; } catch {}
      throw new Error(message);
    }
    downloadConfig(state.username, text);
    showActivity('Configuration downloaded. Keep this file private.');
  } catch (error) {
    showActivity(error.message, true);
  } finally {
    button.disabled = false;
  }
}

async function signOut() {
  try {
    await request('/api/portal/logout', { method: 'POST', body: {} });
  } catch {}
  showLogin();
  showActivity('Signed out.');
}

byId('portalLoginForm').addEventListener('submit', signIn);
byId('portalPasswordButton').addEventListener('click', () => openPasswordDialog(false));
byId('portalSignOutButton').addEventListener('click', signOut);
byId('portalPasswordForm').addEventListener('submit', changePassword);
byId('portalPasswordDialog').addEventListener('cancel', (event) => { if (state.mustChangePassword) event.preventDefault(); });
byId('cancelPortalPassword').addEventListener('click', () => byId('portalPasswordDialog').close());
byId('downloadPortalConfig').addEventListener('click', downloadPortalConfig);
restorePortalSession();