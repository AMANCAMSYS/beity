# Edge Function Contract: generate-shopping-suggestions

**Version**: 1.0.0  
**Type**: Supabase Edge Function (Deno)  
**Auth**: Supabase JWT (passed automatically via `client.functions.invoke`)

## Endpoint

```
POST /functions/v1/generate-shopping-suggestions
Authorization: Bearer <supabase-anon-key + user-jwt>
Content-Type: application/json
```

## Request Schema

```typescript
interface GenerateShoppingSuggestionsRequest {
  /** User's natural-language prompt describing what they need. Required, max 500 chars. */
  prompt: string;
  
  /** Home type for context (e.g., "family", "students", "single", "office"). Required. */
  homeType: string;
  
  /** Title of the shopping list for context. Required. */
  listTitle: string;
  
  /** Names of items already in the shopping list. Max 100 entries. */
  existingItems: string[];
  
  /** Language code for AI response language. Must be "ar" or "en". */
  language: "ar" | "en";
}
```

## Response Schema

### Success (200 OK)

```typescript
interface GenerateShoppingSuggestionsResponse {
  suggestions: AiSuggestion[];
}

interface AiSuggestion {
  /** Item name. Always present, max 100 characters. */
  name: string;
  
  /** Suggested quantity. Optional, defaults to 1 if absent. */
  quantity?: number;
  
  /** Suggested unit of measurement (e.g., "kg", "pcs", "bottle"). Optional. */
  unit?: string;
  
  /** Suggested category (e.g., "Fruits", "Dairy", "Cleaning"). Optional. */
  category?: string;
}
```

### Error Responses

| Status | Body                                              | Cause                        |
|--------|---------------------------------------------------|------------------------------|
| 400    | `{ "error": "Prompt is required" }`               | Empty or missing prompt      |
| 400    | `{ "error": "Prompt exceeds 500 characters" }`    | Prompt too long              |
| 400    | `{ "error": "Invalid language. Use ar or en" }`   | Bad language code            |
| 400    | `{ "error": "Too many existing items (max 100)" }`| Oversized existingItems list |
| 500    | `{ "error": "Unable to generate suggestions" }`   | Gemini API failure           |
| 500    | `{ "error": "Internal server error" }`            | Unexpected server error      |

## Security

- **Authentication**: User must be authenticated (valid Supabase JWT).
- **Authorization**: No specific role check at Edge Function level — Flutter-side guards ensure only `member+` roles can access the UI.
- **API Key**: `GEMINI_API_KEY` is read from Supabase Secrets (`Deno.env.get("GEMINI_API_KEY")`), never exposed to the client.
- **PII**: The Edge Function MUST NOT log or store the user's JWT, user ID, or any PII beyond the request lifetime.

## Rate Limits

- Supabase Edge Functions have built-in concurrency limits.
- Client-side debouncing prevents rapid duplicate requests.
- No additional per-user rate limiting in Phase 1.

## Example cURL

```bash
curl -X POST 'https://<project-ref>.supabase.co/functions/v1/generate-shopping-suggestions' \
  -H 'Authorization: Bearer <anon-key>' \
  -H 'Content-Type: application/json' \
  -d '{
    "prompt": "items for a BBQ party",
    "homeType": "family",
    "listTitle": "Weekend Shopping",
    "existingItems": ["chicken", "rice"],
    "language": "en"
  }'
```

## Example Flutter Call

```dart
final response = await Supabase.instance.client.functions.invoke(
  'generate-shopping-suggestions',
  body: {
    'prompt': prompt,
    'homeType': homeType,
    'listTitle': listTitle,
    'existingItems': existingItemNames,
    'language': locale,
  },
);
```
