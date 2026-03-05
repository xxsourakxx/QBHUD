const state = {
  visible: true,
  paused: false,
  low: { health: 25, hunger: 20, thirst: 20, stress: 80 },
  values: {
    health: 100,
    armor: 0,
    hunger: 100,
    thirst: 100,
    stress: 0,
  },
};

const hud = document.getElementById('hud');
const stressRow = document.getElementById('stress-row');
const voicePanel = document.getElementById('voicePanel');
const voiceLabel = document.getElementById('voiceLabel');
const voiceRange = document.getElementById('voiceRange');
const voiceIcon = document.getElementById('voiceIcon');

const rows = {
  health: document.querySelector(".status-row[data-key='health']"),
  armor: document.querySelector(".status-row[data-key='armor']"),
  hunger: document.querySelector(".status-row[data-key='hunger']"),
  thirst: document.querySelector(".status-row[data-key='thirst']"),
  stress: document.querySelector(".status-row[data-key='stress']"),
};

function setCss(name, value) {
  document.documentElement.style.setProperty(name, value);
}

function clamp(value) {
  return Math.max(0, Math.min(100, Number(value) || 0));
}

function renderVisibility() {
  hud.classList.toggle('hidden', !state.visible);
  hud.classList.toggle('paused', state.paused);
}

function updateStatus(key, value) {
  const percent = clamp(value);
  if (state.values[key] === percent) return;
  state.values[key] = percent;

  const fill = document.getElementById(`bar-${key}`);
  const valueEl = document.getElementById(`value-${key}`);
  if (!fill || !valueEl) return;

  fill.style.width = `${percent}%`;
  valueEl.textContent = `${Math.round(percent)}%`;

  if (rows[key]) {
    const isLow = key === 'stress' ? percent >= state.low.stress : percent <= (state.low[key] ?? -1);
    rows[key].classList.toggle('low', isLow);
  }
}

function updateVoice(data) {
  const label = data.label || 'Normal';
  const icon = data.icon || '🔉';
  voiceLabel.textContent = `${icon} ${label}`;
  voiceRange.textContent = `${Number(data.range || 8).toFixed(1)}m`;

  const color = data.color || '#60ffc6';
  voiceIcon.style.filter = `drop-shadow(0 0 7px ${color})`;
  voiceLabel.style.color = color;
  voicePanel.style.boxShadow = `0 0 14px ${color}40`;
  voicePanel.classList.toggle('talking', Boolean(data.talking));
}

function applyConfig(config) {
  if (config.position === 'bottom-left') {
    hud.classList.add('bottom-left');
  }

  setCss('--bar-width', `${config.barWidth}px`);
  setCss('--bar-height', `${config.barHeight}px`);
  setCss('--bar-spacing', `${config.barSpacing}px`);
  setCss('--bar-radius', `${config.barRadius}px`);
  setCss('--anim-speed', `${config.animationSpeed}ms`);
  setCss('--panel-opacity', String(config.panelOpacity));

  if (config.theme) {
    setCss('--health', config.theme.health);
    setCss('--armor', config.theme.armor);
    setCss('--hunger', config.theme.hunger);
    setCss('--thirst', config.theme.thirst);
    setCss('--stress', config.theme.stress);
    setCss('--panel-bg', config.theme.panel);
    setCss('--text-main', config.theme.text);
    setCss('--text-muted', config.theme.muted);
    setCss('--accent', config.theme.accent);
  }

  if (typeof config.enableStress === 'boolean') {
    stressRow.style.display = config.enableStress ? 'flex' : 'none';
  }

  if (config.low) {
    state.low = { ...state.low, ...config.low };
  }

  if (config.offsetX !== undefined) hud.style.left = `${config.offsetX}vw`;
  if (config.offsetY !== undefined) hud.style.bottom = `${config.offsetY}vh`;
}

window.addEventListener('message', (event) => {
  const msg = event.data;
  if (!msg || !msg.action) return;

  if (msg.action === 'status') updateStatus(msg.data.key, msg.data.value);
  if (msg.action === 'voice') updateVoice(msg.data);
  if (msg.action === 'toggle') {
    state.visible = Boolean(msg.data.visible);
    renderVisibility();
  }
  if (msg.action === 'pause') {
    state.paused = Boolean(msg.data.paused);
    renderVisibility();
  }
  if (msg.action === 'config') applyConfig(msg.data);
  if (msg.action === 'reset') {
    hud.style.left = '';
    hud.style.bottom = '';
  }
});

Object.keys(state.values).forEach((key) => updateStatus(key, state.values[key]));
renderVisibility();
