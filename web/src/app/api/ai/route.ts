import { NextResponse } from 'next/server';

// Proxies a chat completion to Groq. The user's own API key travels in the
// request body (same as the Flutter app calling Groq directly) — this route
// just forwards it server-side to dodge browser CORS. Nothing is stored.

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const DEFAULT_MODEL = 'llama-3.3-70b-versatile';

interface ChatBody {
  apiKey?: string;
  model?: string;
  messages?: { role: string; content: string }[];
}

// Strip <think>…</think> blocks emitted by reasoning models (DeepSeek R1).
function clean(text: string): string {
  return text.replace(/<think>[\s\S]*?<\/think>/g, '').trim();
}

export async function POST(req: Request) {
  let body: ChatBody;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Некорректный запрос' }, { status: 400 });
  }

  const apiKey = body.apiKey?.trim();
  if (!apiKey) {
    return NextResponse.json(
      { error: 'Не указан Groq API ключ' }, { status: 401 },
    );
  }
  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return NextResponse.json({ error: 'Пустой запрос' }, { status: 400 });
  }

  try {
    const res = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: body.model || DEFAULT_MODEL,
        messages: body.messages,
        temperature: 0.5,
        max_tokens: 1024,
      }),
    });

    const data = await res.json().catch(() => null);
    if (!res.ok) {
      const msg = data?.error?.message ?? `Ошибка Groq (${res.status})`;
      return NextResponse.json({ error: msg }, { status: res.status });
    }

    const raw = data?.choices?.[0]?.message?.content ?? '';
    return NextResponse.json({ text: clean(raw) });
  } catch {
    return NextResponse.json(
      { error: 'Нет соединения с Groq' }, { status: 502 },
    );
  }
}
