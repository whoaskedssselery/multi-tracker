// Direct browser client for Groq's OpenAI-compatible chat API. The user's own
// key (same model as the Flutter app) is sent straight to api.groq.com — no
// backend, since this is a static SPA.

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const DEFAULT_MODEL = 'llama-3.3-70b-versatile';

export interface ChatTurn {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

export const SYSTEM_INSTRUCTION =
  'Ты персональный фитнес- и продуктивность-тренер в приложении Multi-tracker. '
  + 'ВАЖНО: используй ТОЛЬКО данные из предоставленного контекста. '
  + 'Не придумывай и не предполагай факты, периоды или цифры, которых нет в данных. '
  + 'Если данных мало — честно скажи об этом. '
  + 'Будь лаконичен, конкретен и дружелюбен. '
  + 'Отвечай на том же языке, на котором пишет пользователь. '
  + 'При ссылке на данные называй точные даты и цифры из контекста. '
  + 'Не превышай 150 слов, если пользователь не просит подробнее.';

export class GroqError extends Error {}

// Strip <think>…</think> blocks emitted by reasoning models (DeepSeek R1).
function clean(text: string): string {
  return text.replace(/<think>[\s\S]*?<\/think>/g, '').trim();
}

export async function askGroq(opts: {
  apiKey: string;
  model: string;
  prompt: string;
  history: ChatTurn[];
}): Promise<string> {
  const messages: ChatTurn[] = [
    { role: 'system', content: SYSTEM_INSTRUCTION },
    ...opts.history,
    { role: 'user', content: opts.prompt },
  ];

  let res: Response;
  try {
    res = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${opts.apiKey.trim()}`,
      },
      body: JSON.stringify({
        model: opts.model || DEFAULT_MODEL,
        messages,
        temperature: 0.5,
        max_tokens: 1024,
      }),
    });
  } catch {
    throw new GroqError('Нет соединения с Groq');
  }

  const data = await res.json().catch(() => null);
  if (!res.ok) {
    throw new GroqError(data?.error?.message ?? `Ошибка Groq (${res.status})`);
  }
  return clean(data?.choices?.[0]?.message?.content ?? '');
}
