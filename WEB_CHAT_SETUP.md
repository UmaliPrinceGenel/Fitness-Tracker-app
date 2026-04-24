# Hosted Chat Setup

The chatbot can use a hosted provider through a Supabase Edge Function on both
web and mobile.

## Why this works

Google AI Studio / Gemini exposes an OpenAI-compatible chat endpoint, so the
same Supabase function can serve both Flutter web and Flutter mobile without
shipping your API key inside the app.

Current behavior:

1. Call the Supabase Edge Function `fitness-chat`
2. On web only, optionally fall back to the browser-local WebLLM path

## Deploy the hosted chat function

From [Fitness-Tracker-app](./):

```bash
supabase functions deploy fitness-chat
```

Set these function secrets in Supabase before testing:

```bash
supabase secrets set OPENAI_API_KEY=your_key_here
supabase secrets set OPENAI_MODEL=your_model_here
```

Optional:

```bash
supabase secrets set OPENAI_BASE_URL=https://api.openai.com/v1
```

`OPENAI_BASE_URL` lets you point the function at any OpenAI-compatible provider.

## Google AI Studio / Gemini setup

Google AI Studio works here because Gemini exposes an OpenAI-compatible chat
endpoint.

Set these Supabase function secrets:

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key
supabase secrets set GEMINI_MODEL_PRIMARY=gemini-3.1-flash-lite
supabase secrets set GEMINI_MODEL_FALLBACK=gemini-2.5-flash-lite
supabase secrets set GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta/openai
```

You can also keep using the existing `OPENAI_*` names if you prefer:

```bash
supabase secrets set OPENAI_API_KEY=your_gemini_api_key
supabase secrets set OPENAI_MODEL_PRIMARY=gemini-3.1-flash-lite
supabase secrets set OPENAI_MODEL_FALLBACK=gemini-2.5-flash-lite
supabase secrets set OPENAI_BASE_URL=https://generativelanguage.googleapis.com/v1beta/openai
```

Then deploy or redeploy the edge function:

```bash
supabase functions deploy fitness-chat
```

Important:

- Keep the Gemini API key in Supabase secrets, not in Flutter web code.
- The function appends `/chat/completions`, so the base URL must stay at
  `https://generativelanguage.googleapis.com/v1beta/openai`
- Recommended primary model: `gemini-3.1-flash-lite`
- Recommended fallback model: `gemini-2.5-flash-lite`
- The function now retries the fallback model on retryable upstream failures
  such as `429`, `500`, `502`, and `503`.

## Flutter app configuration

By default the app looks for a function named `fitness-chat`.
You can override this at build or run time:

```bash
flutter run -d chrome --dart-define=FITNESS_CHAT_FUNCTION_NAME=fitness-chat
flutter run -d android --dart-define=FITNESS_CHAT_FUNCTION_NAME=fitness-chat
```

Optional flags:

```bash
flutter run -d chrome --dart-define=FITNESS_CHAT_USE_REMOTE=true
flutter run -d android --dart-define=FITNESS_CHAT_USE_REMOTE=true
flutter run -d chrome --dart-define=FITNESS_CHAT_FUNCTION_REGION=us-east-1
flutter run -d android --dart-define=FITNESS_CHAT_FUNCTION_REGION=us-east-1
flutter run -d chrome --dart-define=FITNESS_CHAT_ENABLE_WEB_FALLBACK=true
```

## Notes

- Do not put your provider API key in Flutter code.
- Keep the key inside Supabase function secrets.
- Web fallback is optional, browser-only, and now disabled by default.
- If you want Google AI Studio for both mobile and web, set the Gemini secrets in
  Supabase and keep `FITNESS_CHAT_USE_REMOTE=true`.
