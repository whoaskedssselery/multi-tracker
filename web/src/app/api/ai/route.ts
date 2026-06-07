import { NextResponse } from 'next/server';
import { proxyGroqChat, type ChatRequest } from '@/backend/lib/groq/groq-proxy';

export async function POST(req: Request) {
  let body: ChatRequest;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Некорректный запрос' }, { status: 400 });
  }

  const { status, body: payload } = await proxyGroqChat(body);
  return NextResponse.json(payload, { status });
}
