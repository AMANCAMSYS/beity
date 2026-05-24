# OpenRouter API Setup for Beity

This guide explains how to set up the OpenRouter API key and configure the Supabase Edge Function for Smart Shopping Suggestions.

## 1. Obtain an API Key
1. Go to [OpenRouter.ai](https://openrouter.ai/).
2. Sign in or create an account.
3. Navigate to **Keys** and click **Create Key**.
4. Copy the key immediately (it won't be shown again).

## 2. Configure Supabase Secrets
Run the following commands in your terminal to set the required secrets in your Supabase project:

```bash
# Set the AI provider to openrouter
npx supabase secrets set AI_PROVIDER=openrouter

# Set your OpenRouter API key
npx supabase secrets set OPENROUTER_API_KEY=your_key_here

# Optional: Set the model (default is deepseek/deepseek-v4-flash:free)
npx supabase secrets set OPENROUTER_MODEL=deepseek/deepseek-v4-flash:free
```

## 3. Deploy the Edge Function
Once the secrets are set, deploy the updated Edge Function:

```bash
npx supabase functions deploy generate-shopping-suggestions
```

## 4. Verification
You can verify the setup by calling the function using cURL:

```bash
curl -i --location --request POST 'https://your-project-ref.supabase.co/functions/v1/generate-shopping-suggestions' \
  --header 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "prompt": "I want to make a fruit salad",
    "homeType": "Family",
    "listTitle": "Groceries",
    "existingItems": [],
    "language": "en"
  }'
```

## Security Rules
- **NEVER** store the `OPENROUTER_API_KEY` in the Flutter codebase.
- Access to the AI is mediated through the Supabase Edge Function.
- The Edge Function enforces privacy by only sending non-PII data to OpenRouter.
