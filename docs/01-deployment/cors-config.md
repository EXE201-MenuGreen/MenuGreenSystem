# CORS Configuration Guide

**Last updated:** 2026-07-09

## Overview

MenuGreen API uses CORS (Cross-Origin Resource Sharing) to allow frontend applications to access API endpoints.

## Default Allowed Origins

The following origins are allowed by default in production:

| Environment | Origin | Description |
|-------------|--------|-------------|
| Production | `https://www.menugreen.food` | Main website |
| Production | `https://menugreen.food` | Website (non-www) |
| Production | `https://menu-green-system-ldw5frytu-johnny-dangs-projects.vercel.app` | Vercel preview |
| Development | `http://localhost:3000` | Local Next.js |
| Development | `http://localhost:3001` | Local alternative port |

## How to Add New Origins

### Option 1: Environment Variable (Recommended for Production)

Set the `ALLOWED_ORIGINS` environment variable:

```bash
# Single origin
ALLOWED_ORIGINS=https://newdomain.com

# Multiple origins (comma-separated)
ALLOWED_ORIGINS=https://www.menugreen.food,https://newdomain.com,https://staging.menugreen.food
```

### Option 2: Configuration File

In `appsettings.Production.json`:

```json
{
  "AllowedOrigins": "https://www.menugreen.food,https://newdomain.com"
}
```

### Option 3: Code (Not Recommended)

Edit `Program.cs` and add to the `defaultOrigins` array:

```csharp
var defaultOrigins = new[]
{
    "https://www.menugreen.food",
    "https://menugreen.food",
    "https://your-new-origin.com"  // Add here
};
```

## Development vs Production

### Development Environment
- CORS is set to `AllowAnyOrigin`
- All origins, headers, and methods are allowed
- Credentials are allowed

### Production Environment
- Only specific origins are allowed
- All methods and headers are allowed
- Credentials are allowed

## Troubleshooting

### CORS Error: "No 'Access-Control-Allow-Origin' header"

1. Check if the origin is in the allowed list
2. Verify environment variable is set correctly on the server
3. Restart the application after changing CORS config

### Preflight (OPTIONS) Request Failing

The API handles preflight requests automatically. If preflight fails:

1. Check Nginx is not blocking OPTIONS requests
2. Verify the origin matches exactly (including https://)

### Vercel Domain Issues

When deploying to Vercel:
1. Add the Vercel preview domain to `ALLOWED_ORIGINS`
2. After custom domain is configured, add it to the list

## Testing CORS

### Test with curl

```bash
# Test preflight request
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://www.menugreen.food" \
  -H "Access-Control-Request-Method: POST"

# Expected response should include:
# Access-Control-Allow-Origin: https://www.menugreen.food
```

### Test in Browser

1. Open DevTools (F12)
2. Go to Network tab
3. Make the API request
4. Check Response Headers for `Access-Control-Allow-Origin`

## Security Notes

- Never use `AllowAnyOrigin` in production
- Always use `https://` for production origins
- Include both `www` and non-www versions if needed
- Regularly review and remove unused origins
