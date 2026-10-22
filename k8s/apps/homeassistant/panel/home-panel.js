// home-panel: a full-screen dashboard card. Entity IDs come from the card
// config in dashboards/glass.yaml. This file holds only layout and logic.
import { LitElement, html, css, nothing } from "./lit-core.min.js";

const ACTIVE = ["on", "open", "opening", "cleaning", "playing", "heating", "armed_home", "armed_away", "armed_night", "triggered"];
const ALERT = ["on", "open", "opening", "triggered", "problem"];
const WEATHER_ICONS = {
  "clear-night": "mdi:weather-night", cloudy: "mdi:weather-cloudy", fog: "mdi:weather-fog",
  hail: "mdi:weather-hail", lightning: "mdi:weather-lightning", "lightning-rainy": "mdi:weather-lightning-rainy",
  partlycloudy: "mdi:weather-partly-cloudy", pouring: "mdi:weather-pouring", rainy: "mdi:weather-rainy",
  snowy: "mdi:weather-snowy", "snowy-rainy": "mdi:weather-snowy-rainy", sunny: "mdi:weather-sunny",
  windy: "mdi:weather-windy", "windy-variant": "mdi:weather-windy-variant", exceptional: "mdi:alert-circle-outline",
};

const num = (v, d = 0) => (isNaN(parseFloat(v)) ? "–" : parseFloat(v).toFixed(d).replace(".", ","));

class HomePanel extends LitElement {
  static properties = {
    hass: { attribute: false },
    _tab: { state: true },
    _player: { state: true },
    _forecast: { state: true },
    _prices: { state: true },
    _now: { state: true },
  };

  setConfig(config) {
    if (!config.rooms?.length) throw new Error("home-panel: rooms is required");
    this._config = config;
    this._tab = config.rooms[0].group;
    this._now = new Date();
  }

  getCardSize() {
    return 20;
  }

  connectedCallback() {
    super.connectedCallback();
    this._clock = setInterval(() => (this._now = new Date()), 10_000);
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    clearInterval(this._clock);
    this._unsubForecast?.then((unsub) => unsub());
    this._unsubForecast = undefined;
  }

  updated() {
    if (!this.hass) return;
    const c = this._config;
    if (!this._unsubForecast && c.weather) {
      this._unsubForecast = this.hass.connection.subscribeMessage((ev) => (this._forecast = ev.forecast), {
        type: "weather/subscribe_forecast",
        forecast_type: "daily",
        entity_id: c.weather,
      });
    }
    this._loadPrices();
  }

  // Nord Pool prices for today, one fetch per day.
  async _loadPrices() {
    const entry = this._config.energy?.nordpool_entry;
    const day = this._now.toLocaleDateString("sv-SE");
    if (!entry || this._pricesDay === day) return;
    this._pricesDay = day;
    try {
      const { response } = await this.hass.callService("nordpool", "get_prices_for_date", { config_entry: entry, date: day }, undefined, false, true);
      this._prices = Object.values(response)[0] ?? [];
    } catch (err) {
      console.warn("home-panel: no Nord Pool prices", err);
      this._prices = [];
    }
  }

  _s(id) {
    return this.hass.states[id];
  }

  _state(id) {
    const s = this._s(id);
    return s ? this.hass.formatEntityState(s) : "–";
  }

  _moreInfo(entityId) {
    this.dispatchEvent(new CustomEvent("hass-more-info", { detail: { entityId }, bubbles: true, composed: true }));
  }

  _call(service, data = {}) {
    const [domain, name] = service.split(".");
    return this.hass.callService(domain, name, data);
  }

  _tap(item) {
    if (item.service) {
      if (item.confirm && !confirm(item.confirm)) return;
      this._call(item.service, item.data);
    } else if (item.toggle) {
      this._call("homeassistant.toggle", { entity_id: item.entity });
    } else {
      this._moreInfo(item.entity);
    }
  }

  _isActive(id) {
    const s = this._s(id);
    if (!s) return false;
    if (ACTIVE.includes(s.state)) return true;
    return id.startsWith("sensor.") && parseFloat(s.state) > 0;
  }

  // Header

  _header() {
    const c = this._config;
    const h = this._now.getHours();
    const greeting = h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
    const w = this._s(c.weather);
    const alerts = (c.alerts ?? []).map((id) => this._s(id)).filter((s) => s && ALERT.includes(s.state));
    return html`
      <header>
        <div class="hello">
          <h1>${greeting}, ${this.hass.user?.name?.split(" ")[0] ?? ""}</h1>
          <p>${this._now.toLocaleDateString(this.hass.locale?.language, { weekday: "long", day: "numeric", month: "long" })}</p>
        </div>
        <div class="pills">
          <button class="pill people" @click=${() => this._moreInfo(c.people[0])}>
            ${c.people.map((id) => {
              const p = this._s(id);
              const home = p?.state === "home";
              return p?.attributes.entity_picture
                ? html`<img class=${home ? "" : "away"} src=${p.attributes.entity_picture} title=${p.attributes.friendly_name} />`
                : html`<span class="avatar ${home ? "" : "away"}">${p?.attributes.friendly_name?.[0] ?? "?"}</span>`;
            })}
          </button>
          ${w
            ? html`<button class="pill" @click=${() => this._moreInfo(c.weather)}>
                <ha-icon class="sun" .icon=${WEATHER_ICONS[w.state] ?? "mdi:weather-cloudy"}></ha-icon>
                <b>${num(this._s(c.outside)?.state ?? w.attributes.temperature)}°</b>
                <span class="dim">${this._state(c.weather)}</span>
              </button>`
            : nothing}
          <button class="pill" @click=${() => alerts[0] && this._moreInfo(alerts[0].entity_id)}>
            <span class="dot ${alerts.length ? "bad" : ""}"></span>
            ${alerts.length ? alerts.map((a) => a.attributes.friendly_name).join(", ") : "All systems normal"}
          </button>
          <div class="clock">${this._now.toLocaleTimeString("sv-SE", { hour: "2-digit", minute: "2-digit" })}</div>
        </div>
      </header>
    `;
  }

  // Energy

  _energy() {
    const e = this._config.energy;
    const price = parseFloat(this._s(e.price)?.state);
    const avg = parseFloat(this._s(e.average)?.state);
    const level = !avg ? "" : price < avg * 0.85 ? "cheap" : price > avg * 1.15 ? "expensive" : "normal";
    return html`
      <section class="card energy" style="order:3">
        <div class="head"><h2>Electricity</h2><span class="tag ${level}">${level ? `${level[0].toUpperCase()}${level.slice(1)} now` : ""}</span></div>
        <button class="price" @click=${() => this._moreInfo(e.price)}>
          <div class="ring ${level}">
            <ha-icon icon="mdi:flash"></ha-icon>
            <b>${num(price, 2)}</b>
            <small>kr/kWh</small>
          </div>
        </button>
        ${this._chart()}
        <div class="stats">
          ${[
            ["Low", e.low],
            ["Avg", e.average],
            ["High", e.high],
            ["Next", e.next],
          ].map(([label, id]) => html`<button class="stat" @click=${() => this._moreInfo(id)}><small>${label}</small><b>${num(this._s(id)?.state, 2)}</b></button>`)}
        </div>
        <div class="stats">
          ${(e.stats ?? []).map(
            (t) => html`<button class="stat" @click=${() => this._moreInfo(t.entity)}>
              <small>${t.name}</small><b>${num(this._s(t.entity)?.state, t.decimals ?? 0)}<i>${t.unit ?? this._s(t.entity)?.attributes.unit_of_measurement ?? ""}</i></b>
            </button>`
          )}
        </div>
      </section>
    `;
  }

  _chart() {
    const p = this._prices;
    if (!p?.length) return nothing;
    const max = Math.max(...p.map((x) => x.price));
    const now = this._now.getTime();
    return html`
      <div class="chart">
        ${p.map((x) => {
          const cur = new Date(x.start).getTime() <= now && now < new Date(x.end).getTime();
          const past = new Date(x.end).getTime() <= now;
          return html`<span class="${cur ? "cur" : past ? "past" : ""}" style="height:${Math.max(4, (x.price / max) * 100)}%"></span>`;
        })}
      </div>
      <div class="axis"><span>00</span><span>06</span><span>12</span><span>18</span><span>24</span></div>
    `;
  }

  // Quick actions

  _quick() {
    return html`
      <section class="card" style="order:1">
        <div class="head"><h2>Quick actions</h2></div>
        <div class="tiles">
          ${this._config.quick.map((q) => {
            const on = this._isActive(q.entity);
            return html`<button class="tile ${on ? "on" : ""}" style="--c:${q.color ?? "#facc15"}" @click=${() => this._tap(q)} @contextmenu=${(ev) => (ev.preventDefault(), this._moreInfo(q.entity))}>
              <span class="ico"><ha-icon .icon=${q.icon}></ha-icon></span>
              <b>${q.name}</b>
              <small>${q.label ? q.label.replace("{state}", this._s(q.entity)?.state ?? "–") : this._state(q.entity)}</small>
            </button>`;
          })}
        </div>
      </section>
    `;
  }

  // Rooms

  _lightsOn(id) {
    const s = this._s(id);
    if (!s) return 0;
    const members = s.attributes.entity_id;
    return members ? members.filter((m) => this._s(m)?.state === "on").length : s.state === "on" ? 1 : 0;
  }

  _rooms() {
    const rooms = this._config.rooms;
    const groups = [...new Set(rooms.map((r) => r.group))];
    const lit = rooms.filter((r) => this._s(r.light)?.state === "on").length;
    return html`
      <section class="card" style="order:2">
        <div class="head"><h2>Rooms</h2><span class="dim">${lit} ${lit === 1 ? "room" : "rooms"} lit</span></div>
        <div class="tabs">
          ${groups.map((g) => {
            const n = rooms.filter((r) => r.group === g && this._s(r.light)?.state === "on").length;
            return html`<button class=${g === this._tab ? "sel" : ""} @click=${() => (this._tab = g)}>${g}${n ? html`<span class="count">${n}</span>` : nothing}</button>`;
          })}
        </div>
        <div class="rooms">
          ${rooms
            .filter((r) => r.group === this._tab)
            .map((r) => {
              const on = this._s(r.light)?.state === "on";
              const n = this._lightsOn(r.light);
              const temp = r.temp && this._s(r.temp) ? `${num(this._s(r.temp).state)}°` : "";
              const status = [temp, on ? `${n} ${n === 1 ? "light" : "lights"}` : "Off"].filter(Boolean).join(" · ");
              return html`<div class="room ${on ? "on" : ""}">
                <button class="room-main" @click=${() => this._moreInfo(r.light)}>
                  <span class="ico"><ha-icon .icon=${r.icon}></ha-icon></span>
                  <span><b>${r.name}</b><small>${status}</small></span>
                </button>
                <button class="bulb" aria-label="Toggle ${r.name}" @click=${() => this._call("light.toggle", { entity_id: r.light })}>
                  <ha-icon .icon=${on ? "mdi:lightbulb-on" : "mdi:lightbulb-outline"}></ha-icon>
                </button>
              </div>`;
            })}
        </div>
      </section>
    `;
  }

  // Weather

  _weather() {
    const id = this._config.weather;
    const w = this._s(id);
    if (!w) return nothing;
    const today = this._forecast?.[0];
    const sunset = this._s("sun.sun")?.attributes.next_setting;
    return html`
      <section class="card" style="order:4">
        <div class="head">
          <h2>Weather</h2>
          ${sunset ? html`<span class="chip">Sunset ${new Date(sunset).toLocaleTimeString("sv-SE", { hour: "2-digit", minute: "2-digit" })}</span>` : nothing}
        </div>
        <button class="now" @click=${() => this._moreInfo(id)}>
          <ha-icon class="big sun" .icon=${WEATHER_ICONS[w.state] ?? "mdi:weather-cloudy"}></ha-icon>
          <div>
            <b class="temp">${num(this._s(this._config.outside)?.state ?? w.attributes.temperature)}<sup>°</sup></b>
            <div>${this._state(id)}</div>
            ${today ? html`<small class="dim">High ${num(today.temperature)}° · Low ${num(today.templow)}°</small><br />` : nothing}
            <small class="dim">${num(w.attributes.humidity)}% humidity · wind ${num(w.attributes.wind_speed)} ${w.attributes.wind_speed_unit ?? ""}</small>
          </div>
        </button>
        <div class="days">
          ${(this._forecast ?? []).slice(0, 5).map(
            (d, i) => html`<div class="day">
              <small>${i === 0 ? "Today" : new Date(d.datetime).toLocaleDateString(this.hass.locale?.language, { weekday: "short" })}</small>
              <ha-icon class="sun" .icon=${WEATHER_ICONS[d.condition] ?? "mdi:weather-cloudy"}></ha-icon>
              <b>${num(d.temperature)}°</b>
              <small class="dim">${num(d.templow)}°</small>
              ${d.precipitation ? html`<small class="rain">${num(d.precipitation, 1)} mm</small>` : nothing}
            </div>`
          )}
        </div>
      </section>
    `;
  }

  // Charger

  _charger() {
    const ch = this._config.charger;
    if (!ch) return nothing;
    const kw = (parseFloat(this._s(ch.power)?.state) || 0) / 1000;
    return html`
      <section class="card" style="order:5">
        <div class="head"><h2>${ch.name ?? "Charger"}</h2><span class="dim">${this._state(ch.status)}</span></div>
        <button class="ev" @click=${() => this._moreInfo(ch.status)}>
          <b class="temp">${num(kw, 1)}<sup>kW</sup></b>
          <div class="dim">${num(this._s(ch.session)?.state, 1)} kWh this session</div>
          <div class="bar"><span style="width:${Math.min(100, (kw / (ch.max_kw ?? 11)) * 100)}%"></span></div>
        </button>
        <div class="stats">
          ${(ch.stats ?? []).map(
            (t) => html`<button class="stat" @click=${() => this._moreInfo(t.entity)}><small>${t.name}</small><b>${this._state(t.entity)}</b></button>`
          )}
        </div>
      </section>
    `;
  }

  // Music

  _music() {
    const players = this._config.media ?? [];
    if (!players.length) return nothing;
    const id = this._player ?? players.find((p) => this._s(p)?.state === "playing") ?? players[0];
    const m = this._s(id);
    const playing = m?.state === "playing";
    const art = m?.attributes.entity_picture;
    return html`
      <section class="card music" style="order:6">
        <div class="head"><h2>Music</h2></div>
        <div class="player">
          <div class="disc ${playing ? "spin" : ""}" style=${art ? `background-image:url(${art})` : ""}>
            ${art ? nothing : html`<ha-icon icon="mdi:music-note"></ha-icon>`}
          </div>
          <div class="meta">
            <b>${m?.attributes.media_title ?? "Nothing playing"}</b>
            <small class="dim">${m?.attributes.media_artist ?? this._state(id)}</small>
            <div class="sources">
              ${players.map(
                (p) => html`<button class="chip ${p === id ? "sel" : ""}" @click=${() => (this._player = p)}>${this._s(p)?.attributes.friendly_name ?? p}</button>`
              )}
            </div>
            <div class="controls">
              <button @click=${() => this._call("media_player.media_previous_track", { entity_id: id })}><ha-icon icon="mdi:skip-previous"></ha-icon></button>
              <button class="play" @click=${() => this._call("media_player.media_play_pause", { entity_id: id })}><ha-icon .icon=${playing ? "mdi:pause" : "mdi:play"}></ha-icon></button>
              <button @click=${() => this._call("media_player.media_next_track", { entity_id: id })}><ha-icon icon="mdi:skip-next"></ha-icon></button>
            </div>
          </div>
        </div>
      </section>
    `;
  }

  render() {
    if (!this.hass || !this._config) return nothing;
    return html`
      <div class="wrap">
        ${this._header()}
        <div class="grid">
          <div class="col">${this._energy()} ${this._charger()}</div>
          <div class="col">${this._quick()} ${this._rooms()}</div>
          <div class="col">${this._weather()} ${this._music()}</div>
        </div>
      </div>
    `;
  }

  static styles = css`
    :host {
      display: block;
      container-type: inline-size;
      --bg: #0d0f14;
      --panel: rgba(255, 255, 255, 0.035);
      --line: rgba(255, 255, 255, 0.07);
      --tile: rgba(255, 255, 255, 0.05);
      --text: #f4f4f5;
      --dim: #8b8f98;
      --amber: #facc15;
      --green: #22c55e;
      --red: #f87171;
      --blue: #38bdf8;
      font-family: "SF Pro Display", -apple-system, "Inter", "Segoe UI", Roboto, sans-serif;
      color: var(--text);
    }
    * { box-sizing: border-box; }
    button { font: inherit; color: inherit; background: none; border: 0; padding: 0; cursor: pointer; text-align: left; -webkit-tap-highlight-color: transparent; }
    ha-icon { --mdc-icon-size: 22px; }
    .wrap {
      min-height: 100vh;
      padding: 20px 14px 40px;
      background:
        radial-gradient(60% 40% at 0% 0%, rgba(250, 204, 21, 0.13), transparent 70%),
        radial-gradient(50% 40% at 100% 100%, rgba(34, 197, 94, 0.1), transparent 70%),
        var(--bg);
    }
    .dim { color: var(--dim); }
    small { font-size: 13px; }

    /* Header */
    header { display: flex; flex-direction: column; gap: 14px; margin-bottom: 18px; }
    h1 { margin: 0; font-size: 30px; font-weight: 800; letter-spacing: -0.02em; line-height: 1.1; }
    .hello p { margin: 4px 0 0; color: var(--dim); font-size: 15px; }
    .pills { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
    .pill { display: flex; align-items: center; gap: 8px; height: 44px; padding: 0 16px; border-radius: 16px; background: var(--panel); border: 1px solid var(--line); font-size: 15px; white-space: nowrap; }
    .pill b { font-size: 18px; }
    .people { padding: 0 8px; }
    .people img, .avatar { width: 30px; height: 30px; border-radius: 50%; object-fit: cover; margin-left: -10px; border: 2px solid var(--bg); display: grid; place-items: center; font-weight: 700; font-size: 13px; background: #f97316; }
    .people :first-child { margin-left: 0; }
    .away { filter: grayscale(1); opacity: 0.45; }
    .sun { color: var(--amber); }
    .dot { width: 10px; height: 10px; border-radius: 50%; background: var(--green); box-shadow: 0 0 10px var(--green); }
    .dot.bad { background: var(--red); box-shadow: 0 0 10px var(--red); }
    .clock { display: none; font-size: 54px; font-weight: 800; letter-spacing: -0.03em; margin-left: 8px; }

    /* Layout: one column on a phone, three columns on a wide screen */
    .grid { display: flex; flex-direction: column; gap: 14px; }
    .col { display: contents; }
    .card { background: var(--panel); border: 1px solid var(--line); border-radius: 28px; padding: 20px; backdrop-filter: blur(20px); }
    .head { display: flex; justify-content: space-between; align-items: center; gap: 8px; margin-bottom: 16px; min-height: 24px; }
    h2 { margin: 0; font-size: 13px; font-weight: 700; letter-spacing: 0.12em; text-transform: uppercase; color: var(--dim); }

    @container (min-width: 900px) {
      .wrap { padding: 28px 28px 40px; }
      header { flex-direction: row; justify-content: space-between; align-items: center; }
      h1 { font-size: 42px; }
      .clock { display: block; }
      .grid { display: grid; grid-template-columns: 1fr 1.25fr 1fr; align-items: start; gap: 22px; }
      .col { display: flex; flex-direction: column; gap: 22px; }
    }

    /* Energy */
    .price { display: grid; place-items: center; width: 100%; margin: 4px 0 18px; }
    .ring { width: 150px; height: 150px; border-radius: 50%; display: grid; place-content: center; justify-items: center; border: 3px solid var(--blue); box-shadow: 0 0 30px rgba(56, 189, 248, 0.35), inset 0 0 30px rgba(56, 189, 248, 0.15); }
    .ring.cheap { border-color: var(--green); box-shadow: 0 0 30px rgba(34, 197, 94, 0.35), inset 0 0 30px rgba(34, 197, 94, 0.15); }
    .ring.expensive { border-color: var(--red); box-shadow: 0 0 30px rgba(248, 113, 113, 0.35), inset 0 0 30px rgba(248, 113, 113, 0.15); }
    .ring b { font-size: 36px; font-weight: 800; letter-spacing: -0.02em; }
    .ring small { color: var(--dim); letter-spacing: 0.08em; }
    .tag { font-size: 14px; font-weight: 600; color: var(--blue); }
    .tag.cheap { color: var(--green); }
    .tag.expensive { color: var(--red); }
    .chart { display: flex; align-items: flex-end; gap: 1px; height: 70px; }
    .chart span { flex: 1; border-radius: 2px 2px 0 0; background: rgba(56, 189, 248, 0.45); }
    .chart span.past { background: rgba(255, 255, 255, 0.1); }
    .chart span.cur { background: var(--amber); box-shadow: 0 0 10px var(--amber); }
    .axis { display: flex; justify-content: space-between; color: var(--dim); font-size: 11px; margin: 6px 0 14px; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(70px, 1fr)); gap: 8px; margin-top: 8px; }
    .stat { background: var(--tile); border-radius: 16px; padding: 10px 12px; display: flex; flex-direction: column; gap: 2px; }
    .stat small { color: var(--dim); font-size: 11px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; }
    .stat b { font-size: 20px; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .stat i { font-style: normal; font-size: 12px; color: var(--dim); margin-left: 2px; }

    /* Quick actions */
    .tiles { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; }
    @container (min-width: 520px) { .tiles { grid-template-columns: repeat(4, 1fr); } }
    .tile { background: var(--tile); border: 1.5px solid transparent; border-radius: 22px; padding: 14px; display: flex; flex-direction: column; gap: 2px; transition: border-color 0.2s, background 0.2s; }
    .tile .ico { width: 42px; height: 42px; border-radius: 13px; display: grid; place-items: center; background: rgba(255, 255, 255, 0.06); color: var(--c); margin-bottom: 10px; }
    .tile b { font-size: 16px; }
    .tile small { color: var(--dim); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .tile.on { border-color: color-mix(in srgb, var(--c) 70%, transparent); background: color-mix(in srgb, var(--c) 9%, transparent); }
    .tile.on .ico { background: var(--c); color: #111; box-shadow: 0 0 18px color-mix(in srgb, var(--c) 60%, transparent); }
    .tile.on small { color: var(--c); }

    /* Rooms */
    .tabs { display: flex; background: rgba(255, 255, 255, 0.04); border-radius: 16px; padding: 4px; margin-bottom: 14px; }
    .tabs button { flex: 1; text-align: center; white-space: nowrap; padding: 10px 4px; border-radius: 12px; color: var(--dim); font-weight: 600; font-size: 15px; }
    .tabs button.sel { background: rgba(255, 255, 255, 0.07); color: var(--text); }
    .count { display: inline-grid; place-items: center; width: 20px; height: 20px; margin-left: 6px; border-radius: 50%; background: rgba(250, 204, 21, 0.2); color: var(--amber); font-size: 12px; }
    .rooms { display: grid; grid-template-columns: 1fr; gap: 10px; }
    @container (min-width: 520px) { .rooms { grid-template-columns: 1fr 1fr; } }
    .room { display: flex; align-items: center; gap: 10px; padding: 12px; border-radius: 22px; background: var(--tile); border: 1.5px solid transparent; }
    .room.on { border-color: rgba(250, 204, 21, 0.55); background: linear-gradient(135deg, rgba(250, 204, 21, 0.12), rgba(250, 204, 21, 0.02)); }
    .room-main { flex: 1; display: flex; align-items: center; gap: 12px; min-width: 0; }
    .room-main > span:last-child { display: flex; flex-direction: column; min-width: 0; }
    .room b { font-size: 17px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .room small { color: var(--dim); }
    .room.on small { color: var(--amber); }
    .room .ico { flex: none; width: 44px; height: 44px; border-radius: 14px; display: grid; place-items: center; background: rgba(255, 255, 255, 0.06); color: var(--dim); }
    .room.on .ico { color: var(--amber); background: rgba(250, 204, 21, 0.12); }
    .bulb { flex: none; width: 48px; height: 48px; border-radius: 16px; display: grid; place-items: center; border: 1px solid var(--line); color: var(--dim); }
    .room.on .bulb { background: var(--amber); color: #111; border-color: transparent; box-shadow: 0 0 20px rgba(250, 204, 21, 0.45); }

    /* Weather */
    .now { display: flex; align-items: center; gap: 18px; width: 100%; margin-bottom: 16px; }
    .now > div { flex: 1; }
    .big { --mdc-icon-size: 64px; }
    .temp { font-size: 52px; font-weight: 800; letter-spacing: -0.03em; line-height: 1; }
    .temp sup { font-size: 0.4em; font-weight: 600; margin-left: 2px; }
    .chip { padding: 8px 12px; border-radius: 12px; background: var(--tile); font-size: 14px; font-weight: 600; white-space: nowrap; align-self: flex-start; }
    .chip.sel { background: rgba(167, 139, 250, 0.18); color: #c4b5fd; }
    .days { display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; }
    .day { display: flex; flex-direction: column; align-items: center; gap: 4px; padding: 10px 4px; border-radius: 16px; background: var(--tile); }
    .day b { font-size: 18px; }
    .rain { color: var(--blue); font-size: 12px; }

    /* Charger */
    .ev { display: block; width: 100%; }
    .bar { height: 10px; border-radius: 5px; background: rgba(255, 255, 255, 0.08); margin: 16px 0 8px; overflow: hidden; }
    .bar span { display: block; height: 100%; border-radius: 5px; background: linear-gradient(90deg, var(--green), #4ade80); box-shadow: 0 0 12px var(--green); }

    /* Music */
    .music { background: linear-gradient(160deg, var(--panel), rgba(34, 197, 94, 0.06)); }
    .player { display: flex; gap: 18px; align-items: center; }
    .disc { flex: none; width: 120px; height: 120px; border-radius: 50%; display: grid; place-items: center; background: radial-gradient(circle, #3b2a6b 0 22%, #15161c 23% 100%); background-size: cover; background-position: center; box-shadow: 0 0 0 6px rgba(255, 255, 255, 0.03), 0 0 0 12px rgba(255, 255, 255, 0.02); color: #c4b5fd; --mdc-icon-size: 30px; }
    @container (max-width: 520px) { .disc { width: 88px; height: 88px; } }
    .disc.spin { animation: spin 8s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
    .meta { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
    .meta b { font-size: 19px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .sources { display: flex; gap: 6px; overflow-x: auto; margin: 6px 0; scrollbar-width: none; }
    .sources .chip { font-size: 12px; padding: 6px 10px; }
    .controls { display: flex; align-items: center; gap: 10px; }
    .controls button { width: 44px; height: 44px; border-radius: 50%; display: grid; place-items: center; background: var(--tile); }
    .controls .play { width: 56px; height: 56px; background: #a78bfa; color: #111; box-shadow: 0 0 24px rgba(167, 139, 250, 0.5); }

    @media (prefers-reduced-motion: reduce) {
      .disc.spin { animation: none; }
    }
    button:focus-visible { outline: 2px solid var(--blue); outline-offset: 2px; }
  `;
}

customElements.define("home-panel", HomePanel);
