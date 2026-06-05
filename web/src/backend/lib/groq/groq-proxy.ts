// Server-side Groq proxy. The user's own API key arrives in the request body
// (same model as the Flutter app calling Groq directly); this just forwards it
// to dodge browser CORS. Nothing is stored.

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const DEFAULT_MODEL = 'llama-3.3-70b-versatile';

export interface ChatRequest {
  apiKey?: string;
  model?: string;
  messages?: { role: string; content: string }[];
}

export interface ProxyResult {
  status: number;
  body: { text: string } | { error: string };
}

// Strip <think>…</think> blocks emitted by reasoning models (DeepSeek R1).
function clean(text: string): string {
  return text.replace(/<think>[\s\S]*?<\/think>/g, '').trim();
}

export async function proxyGroqChat(body: ChatRequest): Promise<ProxyResult> {
  const apiKey = body.apiKey?.trim();
  if (!apiKey) {
    return { status: 401, body: { error: 'Не указан Groq API ключ' } };
  }
  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return { status: 400, body: { error: 'Пустой запрос' } };
  }

  try {
    const res = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type':  'application/json',
        Authorization:   `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model:       body.model || DEFAULT_MODEL,
        messages:    body.messages,
        temperature: 0.5,
        max_tokens:  1024,
      }),
    });

    const data = await res.json().catch(() => null);
    if (!res.ok) {
      const msg = data?.error?.message ?? `Ошибка Groq (${res.status})`;
      return { status: res.status, body: { error: msg } };
    }

    const raw = data?.choices?.[0]?.message?.content ?? '';
    return { status: 200, body: { text: clean(raw) } };
  } catch {
    return { status: 502, body: { error: 'Нет соединения с Groq' } };
  }
}
