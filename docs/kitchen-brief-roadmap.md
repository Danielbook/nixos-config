# Kitchen brief ("Vad händer idag") — roadmap

A physical button in the kitchen. A press plays a spoken Swedish summary of the
day (30–40 s). A local LLM writes the text. All parts run locally, except
the voice (Home Assistant Cloud TTS, see Decisions).

**Language:** code, config and comments in English. Spoken text and LLM output
in Swedish.

## Known environment

| Part | Status |
|---|---|
| Home Assistant | Container in k3s, `k8s/apps/homeassistant/homeassistant.yaml` (`2026.7.1`). `/config` is on a PVC. Dashboards come from a git ConfigMap |
| Zigbee | Zigbee2MQTT + Mosquitto in the same namespace |
| Ollama | `k8s/apps/ollama`, `http://ollama.ollama.svc.cluster.local:11434`, `qwen2.5:7b-instruct-q4_K_M`, `NUM_PARALLEL=1`, one loaded model. The GPU (tatooine, GTX 1070) is shared with holocron and Jellyfin |
| Mealie | `k8s/apps/mealie` |
| TTS | Home Assistant Cloud, `tts.home_assistant_cloud`, voice `SofieNeural` (`sv-SE`) |
| Kitchen speaker | `media_player.kok` (Music Assistant) |
| Weather | SMHI is installed (`weather.smhi_home`). Met.no is not necessary |
| Workday, Nord Pool, waste | Installed (`binary_sensor.workday`, `nordpool`, `motalavattenavfall`) |
| Calendars | Apple/iCloud |

## Decisions

- **Config in git.** The package `k8s/apps/homeassistant/packages/kitchen_brief.yaml`
  has the script, the sensor and the automations. The ConfigMap `ha-packages`
  mounts it at `/config/integrations/git/`. `configuration.yaml` already
  loads `integrations/` with `!include_dir_named`.
- **Pre-generate.** An hourly automation collects the facts for today and
  tomorrow. It calls the LLM only when the facts changed. HA has no "calendar
  changed" trigger, so the hourly check replaces it. The text goes into
  attributes of `sensor.kitchen_brief` (`input_text` stops at 255 chars). A
  press only plays the stored text.
- **Ollama through `rest_command`, not `ai_task`.** The HA Ollama integration
  has no temperature option. The direct `/api/chat` call sets
  `temperature: 0.2`. It does not set `num_ctx`, so Ollama does not reload
  the model.
- **Facts as Swedish sentences.** The template writes the facts as plain
  Swedish. The same text is the fallback. Each event is a separate sentence
  with the time after the name. The weather lines have no clock times. In a
  test with clock times in the weather, the LLM mixed them with the events.
- **Templates own the facts.** Templates format all times and dates (Swedish
  weekdays and months, 24-hour clock). The LLM only phrases the text.
- **One order:** greeting + date → weather → events → school lunch →
  preschool lunch → dinner. Omit empty sections.
- **Fallback:** if Ollama fails, play a plain Swedish template text.
- **Length:** 80–100 words. No lists, no emojis.
- **Voice: Home Assistant Cloud, Sofie.** We tested the three Swedish Piper
  voices (nst, alma, lisa) on the gym speaker. All sounded bad. The Cloud
  voices Sofie, Mattias and Hillevi sounded much better, and Sofie was the
  best. This breaks the "all local" rule for the voice only. The brief text
  goes to the cloud, the calendar data does not.
- Homelab alerts never go to the kitchen. They go to ntfy.

## Phase 0 — Answer the open questions

| Question | Answer |
|---|---|
| HA deployment | Container in k3s (answered) |
| Kitchen speaker entity id | `media_player.kok` (Music Assistant) |
| Button model (Zigbee, Z2M) | Open. Not paired yet. Name it `Kitchen Brief Button` in Z2M. Set the `single`/`double` payloads for the model |
| School lunch menu URL | Postponed. The MVP has no lunch |
| Preschool lunch menu URL | Postponed |
| Mealie dinner entity id | Open. Expected `calendar.mealie_dinner` |
| Model for Swedish in 8 GB | Open. See Phase 4 |

## Phase 1 — Infrastructure

Done: the `ha-packages` ConfigMap and its mount. The voice is Home Assistant
Cloud (`tts.home_assistant_cloud`, `SofieNeural`). Piper is removed.

**Verify:** `tts.speak` with the Cloud voice plays a Swedish test sentence on
the speaker.

## Phase 2 — Data sources

| Content | Integration | Verify |
|---|---|---|
| Family calendars | CalDAV, `https://caldav.icloud.com`, app-specific password | `calendar.get_events` returns today |
| School/preschool events | Shared Apple calendar "Barnen" (manual entries, the school apps have no API) | Visible through CalDAV |
| Weather | SMHI (installed) | `weather.get_forecasts` daily + hourly |
| School + preschool lunch | HACS `Kaptensanders/skolmat` v2 (postponed) | Sensor shows today's menu |
| Dinner | Official Mealie integration | Dinner calendar shows today's recipe |

**Verify:** all sources return data for today in Developer Tools. The script
reads all calendars except the Workday calendars and the Mealie calendars
that are not dinner. A new CalDAV calendar needs no change.

## Phase 3 — MVP

Done in git (`packages/kitchen_brief.yaml`):

1. **Collect.** `script.kitchen_brief_generate` (`day: 0|1`, `force`) gets
   calendars, SMHI weather and the Mealie dinner.
2. **Prompt.** Only the facts. The model must not invent, add or guess.
3. **Generate.** `rest_command.kitchen_brief_ollama`. If it fails, the facts
   text is stored.
4. **Triggers.** Each hour and at HA start.
5. **Play.** Button `single` → today, `double` → tomorrow, `script.kitchen_brief_play`
   with `tts.speak` on `media_player.kok`. The double press is also done.

Tested before the deploy: the facts template renders with live SMHI data,
the LLM gives correct facts in 4 of 4 runs (about 4 s each), and HA
`check_config` passes.

**Verify after the deploy:** run the script with `force: true`. A press plays
the brief in less than 2 s. Scale Ollama to 0, run again, and the fallback
text plays. A day without events has no events section.

## Phase 4 — Polish

- **Model test:** compare `gemma3:4b` and `qwen3:8b` against
  `qwen2.5:7b-instruct-q4_K_M`. Use the same 5 saved data sets. Check Swedish
  quality, invented facts and latency. Keep one model resident (the GPU is
  shared). A model change also changes the HA voice pipeline, Mealie and Open
  WebUI.
- **Holidays:** Workday (SE) removes school lunch on public holidays. School
  breaks need a separate source.

## Phase 5 — Optional extras

Add each item only when it is relevant for that day:

- Road ice (Trafikverket weather station) and SMHI warnings
- Waste collection (HACS `waste_collection_schedule` or ICS)
- Name day
- Electricity price (Nord Pool), only on unusual days
- Horse blanket advice (thresholds in a template, not the LLM)
- Mealie shopping list and cooking start time (`mealie.get_recipe`)
