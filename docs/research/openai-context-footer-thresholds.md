# OpenAI context-footer thresholds

Research date: 2026-09-16.

## Facts

OpenAI documents a 1,050,000-token context window, 922,000 maximum input tokens,
and 128,000 maximum output tokens for GPT-5.6 Terra, GPT-5.6 Sol, and GPT-6
Astra. All three charge long-context pricing for prompts above 272,000 input
tokens: 2× input/cache rates and 1.5× output rates.

Pi must use its configured model context window as the hard ceiling. The active
GPT-5.6 Terra session reported 272,000 tokens, so that is its effective ceiling
in this provider/session even though the API model supports more.

There is no OpenAI-published or community-validated model-quality degradation
threshold. The footer bands are an operational policy: preserve headroom before
the 272K long-context price boundary and before Pi's currently reported 272K
ceiling.

## Policy

| Model IDs | Official context | Effective policy limit | Green | Yellow | Red |
| --- | ---: | ---: | ---: | ---: | ---: |
| `gpt-5.6-terra` | 1,050K | 272K | <190K | 190K–244K | ≥245K |
| `gpt-5.6-sol` | 1,050K | 272K | <190K | 190K–244K | ≥245K |
| `gpt-6-astra` | 1,050K | 272K | <190K | 190K–244K | ≥245K |

190K and 245K are rounded 70% and 90% of the 272K boundary. They are alerts,
not claims about reasoning quality. For a provider that exposes a lower context
window, use 70% and 90% of that lower ceiling instead.

## Sources

- [GPT-5.6 Terra model docs](https://developers.openai.com/api/docs/models/gpt-5.6-terra.md)
- [GPT-5.6 Sol model docs](https://developers.openai.com/api/docs/models/gpt-5.6-sol)
- [GPT-6 Astra model docs](https://developers.openai.com/api/docs/models/gpt-6-astra.md)
- [OpenAI API changelog](https://developers.openai.com/api/docs/changelog) — long-context support above 272K for GPT-5.6 Sol, Terra, and Luna.
- [r/codex discussion search](https://www.reddit.com/r/codex/search/?q=%22GPT-5.6%20Terra%22&restrict_sr=1&sort=relevance&t=year) — anecdotal only; no agreed quality cutoff.
