import {
  CreateWebWorkerMLCEngine,
  prebuiltAppConfig,
} from "https://esm.run/@mlc-ai/web-llm";

const workerUrl = new URL("./webllm_worker.js", import.meta.url);
const appConfig = {
  ...prebuiltAppConfig,
  cacheBackend: "indexeddb",
};
const browserSupportMessage =
  "This browser cannot run the local web chatbot. WebLLM requires WebGPU, so use a recent Chrome, Edge, or another browser with WebGPU enabled.";

let engine = null;
let enginePromise = null;
let worker = null;

function isSupported() {
  return typeof navigator !== "undefined" && "gpu" in navigator;
}

function getUnsupportedReason() {
  return Promise.resolve(browserSupportMessage);
}

function pickModelId() {
  const modelList = prebuiltAppConfig.model_list ?? [];
  const normalizedEntries = modelList.map((entry) => ({
    raw: entry,
    id: entry.model_id ?? entry.model ?? "",
    normalized: String(entry.model_id ?? entry.model ?? "").toLowerCase(),
  }));

  const preferredMatchers = [
    (entry) =>
      entry.normalized.includes("qwen2.5") &&
      entry.normalized.includes("0.5b") &&
      entry.normalized.includes("instruct"),
    (entry) =>
      entry.normalized.includes("qwen2") &&
      entry.normalized.includes("0.5b") &&
      entry.normalized.includes("instruct"),
    (entry) =>
      entry.normalized.includes("qwen2.5") &&
      entry.normalized.includes("0.5b"),
    (entry) =>
      entry.normalized.includes("qwen2") && entry.normalized.includes("0.5b"),
  ];

  for (const matches of preferredMatchers) {
    const match = normalizedEntries.find(matches);
    if (match && match.id) {
      return match.id;
    }
  }

  const fallback = normalizedEntries.find((entry) =>
    entry.normalized.includes("instruct"),
  );
  if (fallback && fallback.id) {
    return fallback.id;
  }

  throw new Error("No compatible WebLLM model was found.");
}

async function ensureInitialized() {
  if (!isSupported()) {
    throw new Error(browserSupportMessage);
  }

  if (engine) {
    return engine.__fitnessModelId;
  }

  if (!enginePromise) {
    const modelId = pickModelId();
    worker = new Worker(workerUrl, { type: "module" });

    enginePromise = CreateWebWorkerMLCEngine(worker, modelId, {
      appConfig,
    }).then(
      (createdEngine) => {
        engine = createdEngine;
        engine.__fitnessModelId = modelId;
        return modelId;
      },
    ).catch((error) => {
      enginePromise = null;
      if (worker) {
        worker.terminate();
        worker = null;
      }
      throw error;
    });
  }

  return enginePromise;
}

async function generateReply(messagesJson) {
  await ensureInitialized();
  const messages = JSON.parse(messagesJson);

  const reply = await engine.chat.completions.create({
    messages,
    temperature: 0.65,
    top_p: 0.9,
    max_tokens: 320,
  });

  return reply.choices?.[0]?.message?.content ?? "";
}

window.fitnessWebLlm = {
  isSupported: async () => isSupported(),
  getUnsupportedReason,
  ensureInitialized,
  generateReply,
};
