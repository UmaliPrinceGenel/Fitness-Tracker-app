const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};

type ProviderSuccess = {
  ok: true;
  reply: string;
  model: string;
};

type ProviderFailure = {
  ok: false;
  model: string;
  status: number;
  details: unknown;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  if (request.method !== "POST") {
    return jsonResponse(
      {
        error: "Method not allowed.",
      },
      405,
    );
  }

  const apiKey =
    Deno.env.get("OPENAI_API_KEY")?.trim() ||
    Deno.env.get("GEMINI_API_KEY")?.trim();
  const primaryModel =
    Deno.env.get("OPENAI_MODEL_PRIMARY")?.trim() ||
    Deno.env.get("GEMINI_MODEL_PRIMARY")?.trim() ||
    Deno.env.get("OPENAI_MODEL")?.trim() ||
    Deno.env.get("GEMINI_MODEL")?.trim();
  const fallbackModel =
    Deno.env.get("OPENAI_MODEL_FALLBACK")?.trim() ||
    Deno.env.get("GEMINI_MODEL_FALLBACK")?.trim();
  const baseUrl =
    Deno.env.get("OPENAI_BASE_URL")?.trim() ||
    Deno.env.get("GEMINI_BASE_URL")?.trim() ||
    "https://api.openai.com/v1";

  if (apiKey == null || apiKey.length === 0) {
    return jsonResponse(
      {
        error:
          "Missing provider API key. Set OPENAI_API_KEY or GEMINI_API_KEY.",
      },
      500,
    );
  }

  if (primaryModel == null || primaryModel.length === 0) {
    return jsonResponse(
      {
        error:
          "Missing provider model. Set OPENAI_MODEL_PRIMARY/OPENAI_MODEL or GEMINI equivalents.",
      },
      500,
    );
  }

  let payload: { messages?: ChatMessage[] };
  try {
    payload = await request.json();
  } catch (_) {
    return jsonResponse(
      {
        error: "Invalid JSON body.",
      },
      400,
    );
  }

  const messages = sanitizeMessages(payload.messages);
  if (messages.length === 0) {
    return jsonResponse(
      {
        error: "Request must include at least one valid chat message.",
      },
      400,
    );
  }

  const modelsToTry = [
    primaryModel,
    fallbackModel,
  ].filter((model, index, allModels): model is string =>
    model != null && model.length > 0 && allModels.indexOf(model) === index
  );

  const failures: ProviderFailure[] = [];
  for (const model of modelsToTry) {
    const result = await requestProviderReply({
      apiKey,
      baseUrl,
      model,
      messages,
    });

    if (isProviderFailure(result)) {
      failures.push(result);
      if (!shouldTryFallback(result.status)) {
        break;
      }
      continue;
    }

    return jsonResponse({
      reply: result.reply,
      model: result.model,
      fallbackUsed: result.model !== primaryModel,
    });
  }

  const lastFailure = failures[failures.length - 1];
  return jsonResponse(
    {
      error: "Upstream chat provider request failed.",
      status: lastFailure?.status ?? 502,
      details: failures.map((failure) => ({
        model: failure.model,
        status: failure.status,
        details: failure.details,
      })),
    },
    502,
  );
});

function sanitizeMessages(value: unknown): ChatMessage[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => {
      const record = entry as Record<string, unknown> | null;
      if (
        record == null ||
        typeof record !== "object" ||
        !("role" in record) ||
        !("content" in record)
      ) {
        return null;
      }

      const role = String(record.role ?? "").trim();
      const content = String(record.content ?? "").trim();
      if (
        (role !== "system" && role !== "user" && role !== "assistant") ||
        content.length === 0
      ) {
        return null;
      }

      return {
        role: role as ChatMessage["role"],
        content,
      };
    })
    .filter((entry): entry is ChatMessage => entry != null);
}

function extractReply(payload: any): string | null {
  const content = payload?.choices?.[0]?.message?.content;

  if (typeof content === "string") {
    return content;
  }

  if (Array.isArray(content)) {
    const textParts = content
      .map((part) => {
        if (part == null || typeof part !== "object") {
          return "";
        }

        if (typeof part.text === "string") {
          return part.text;
        }

        return "";
      })
      .filter((part) => part.length > 0);

    return textParts.length == 0 ? null : textParts.join("\n");
  }

  return null;
}

function isProviderFailure(
  result: ProviderSuccess | ProviderFailure,
): result is ProviderFailure {
  return result.ok === false;
}

async function requestProviderReply({
  apiKey,
  baseUrl,
  model,
  messages,
}: {
  apiKey: string;
  baseUrl: string;
  model: string;
  messages: ChatMessage[];
}): Promise<ProviderSuccess | ProviderFailure> {
  const providerResponse = await fetch(
    `${baseUrl.replace(/\/+$/, "")}/chat/completions`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        messages,
        temperature: 0.65,
        max_tokens: 320,
      }),
    },
  );

  const providerText = await providerResponse.text();
  let providerJson: any = null;
  try {
    providerJson = providerText ? JSON.parse(providerText) : null;
  } catch (_) {
    providerJson = null;
  }

  if (!providerResponse.ok) {
    return {
      ok: false,
      model,
      status: providerResponse.status,
      details: providerJson ?? providerText,
    };
  }

  const reply = extractReply(providerJson);
  if (reply == null || reply.trim().length === 0) {
    return {
      ok: false,
      model,
      status: 502,
      details: "Upstream chat provider returned an empty reply.",
    };
  }

  return {
    ok: true,
    model,
    reply: reply.trim(),
  };
}

function shouldTryFallback(status: number): boolean {
  return status !== 401 && status !== 403;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
