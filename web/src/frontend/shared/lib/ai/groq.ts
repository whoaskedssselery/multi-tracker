// Thin client over the /api/ai proxy route. Mirrors the Flutter GroqClient
// (system instruction + history + context preamble).

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

  const res = await fetch('/api/ai', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ apiKey: opts.apiKey, model: opts.model, messages }),
  });

  const data = await res.json().catch(() => null);
  if (!res.ok) throw new GroqError(data?.error ?? `Ошибка ${res.status}`);
  return (data?.text as string) ?? '';
}
