# Contract: Feedback Submission Edge Function

**Feature**: 012-mvp-hardening-beta
**Type**: Supabase Edge Function

## Endpoint

**Function name**: `submit-feedback`
**Method**: POST
**Auth**: Required (JWT from authenticated user)
**Rate limit**: 10 requests per user per hour

## Request

### Headers

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Body

```json
{
  "feedback_type": "bug | survey",
  "description": "string (required, 1-2000 characters)",
  "star_rating": "integer 1-5 (required when feedback_type is 'survey')",
  "device_info": {
    "device_model": "string",
    "os_version": "string",
    "app_version": "string",
    "build_number": "string",
    "platform": "ios | android"
  },
  "screen_route": "string (optional)",
  "app_logs": ["string"] 
}
```

### Validation Rules

- `feedback_type`: Must be one of `"bug"` or `"survey"`
- `description`: Required, 1-2000 characters, trimmed
- `star_rating`: Required when `feedback_type` is `"survey"`, must be 1-5
- `star_rating`: Must be null/absent when `feedback_type` is `"bug"`
- `device_info`: Required object with at least `device_model`, `os_version`, `app_version`
- `app_logs`: Optional array of strings, max 50 entries

## Response

### Success (201 Created)

```json
{
  "id": "uuid of created feedback record",
  "status": "received"
}
```

### Error Responses

| Status | Body                                            | Condition                              |
| ------ | ----------------------------------------------- | -------------------------------------- |
| 400    | `{"error": "Invalid feedback_type"}`            | feedback_type not 'bug' or 'survey'    |
| 400    | `{"error": "description is required"}`          | Empty or missing description           |
| 400    | `{"error": "star_rating required for surveys"}` | survey type without rating             |
| 400    | `{"error": "star_rating must be 1-5"}`          | Rating out of range                    |
| 401    | `{"error": "Unauthorized"}`                     | Missing or invalid JWT                 |
| 429    | `{"error": "Rate limit exceeded"}`              | More than 10 submissions per hour      |
| 500    | `{"error": "Internal server error"}`            | Server failure                         |

## Behavior

1. Validate JWT and extract `user_id`
2. Validate request body against rules above
3. Check rate limit (10/hour per user, tracked in Redis or Supabase)
4. INSERT into `beta_feedback` table with `user_id` from JWT
5. Return 201 with the created record ID
6. Log submission to Supabase Edge Function logs for monitoring
