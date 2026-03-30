# Rate Limiting trong API: Bảo Vệ Hệ Thống Khỏi Lạm Dụng

> **Dành cho developers xây dựng và vận hành API services**

Hãy tưởng tượng bạn đang vận hành một API service phục vụ hàng nghìn người dùng. Một ngày đẹp trời, server của bạn bắt đầu quá tải, database phản hồi chậm, và các user khác bắt đầu phàn nàn về service bị chậm. Khi bạn kiểm tra logs, bạn phát hiện ra một client đang gửi hàng nghìn requests mỗi giây - có thể là bug trong code của họ, hoặc tệ hơn, là một cuộc tấn công cố ý.

Đây chính là lúc **rate limiting** trở nên quan trọng. Nó không chỉ là một tính năng "nice-to-have" mà là một phần thiết yếu trong kiến trúc API hiện đại.

## Phần 1: Tại Sao Cần Rate Limiting?

### 1.1 Bảo Vệ Tài Nguyên Hệ Thống

API của bạn chạy trên các tài nguyên hữu hạn - CPU, memory, database connections, network bandwidth. Mỗi request đều tiêu tốn các tài nguyên này. Nếu không có giới hạn, một client nào đó (dù cố ý hay vô ý) có thể tiêu tốn toàn bộ tài nguyên, khiến service của bạn không thể phục vụ các user khác.

**Ví dụ thực tế:**

```javascript
// Một vòng lặp vô tình không có delay
for (let i = 0; i < 10000; i++) {
  fetch("https://api.example.com/users").then((response) => response.json());
}
// 10,000 requests được gửi cùng lúc!
```

### 1.2 Ngăn Chặn Lạm Dụng và Tấn Công

Rate limiting là tuyến phòng thủ đầu tiên chống lại:

- **DDoS attacks** - Tấn công từ chối dịch vụ
- **Credential stuffing** - Thử nghiệm đăng nhập với nhiều tài khoản
- **Web scraping** - Thu thập dữ liệu trái phép
- **API abuse** - Sử dụng API vượt quá mục đích được phép

### 1.3 Đảm Bảo Công Bằng (Fair Usage)

Không phải tất cả users đều bình đẳng về nhu cầu sử dụng, nhưng mọi user đều xứng đáng được phục vụ. Rate limiting đảm bảo rằng:

- Một power user không thể làm ảnh hưởng đến trải nghiệm của users khác
- Resources được phân phối công bằng giữa các users
- Free tier users không thể tiêu tốn tài nguyên như paid users

### 1.4 Kiểm Soát Chi Phí

Nếu API của bạn sử dụng dịch vụ bên thứ ba (third-party services) có tính phí theo usage, rate limiting giúp:

- Kiểm soát chi phí cơ sở hạ tầng
- Tránh "bill shock" khi có usage spike bất thường
- Align pricing tiers với actual resource costs

---

## Phần 2: Các Chiến Lược Rate Limiting

Có nhiều algorithms khác nhau để implement rate limiting, mỗi cách có ưu và nhược điểm riêng. Hãy cùng tìm hiểu chi tiết các strategy phổ biến nhất.

### 2.1 Fixed Window Counter

**Cách hoạt động:**

Fixed window chia time thành các cửa sổ cố định (ví dụ: mỗi phút, mỗi giờ). Bạn đếm số requests trong mỗi window và reset counter khi window mới bắt đầu.

```
Window 1 (0-60s)    Window 2 (60-120s)    Window 3 (120-180s)
[===========]       [===========]         [===========]
Counter: 45         Counter: 0→52         Counter: 0→38
```

**Implementation đơn giản:**

```javascript
const rateLimit = {
  windowStart: Date.now(),
  windowSize: 60000, // 1 phút
  maxRequests: 100,
  counter: 0,
};

function allowRequest() {
  const now = Date.now();

  // Reset nếu window mới bắt đầu
  if (now - rateLimit.windowStart >= rateLimit.windowSize) {
    rateLimit.windowStart = now;
    rateLimit.counter = 0;
  }

  if (rateLimit.counter < rateLimit.maxRequests) {
    rateLimit.counter++;
    return true;
  }

  return false;
}
```

**✅ Ưu điểm:**

- Cực kỳ đơn giản để implement
- Memory efficient (chỉ cần lưu counter và timestamp)
- Dễ reasoning về behavior

**❌ Nhược điểm:**

- **Burst problem at window edges** - User có thể gửi 100 requests ở cuối window 1, rồi lại 100 requests ngay đầu window 2 = 200 requests trong 1 giây!

```
Window 1 end           Window 2 start
      ↓                       ↓
[..................] | [.....................]
                  ^^^^^^^^
              200 requests in 1 second!
```

### 2.2 Sliding Window Log

**Cách hoạt động:**

Thay vì các window cố định, sliding window track timestamp của từng request. Khi có request mới, bạn loại bỏ các timestamps cũ hơn window size và đếm số requests còn lại.

```javascript
const requestLog = [];
const windowSize = 60000; // 1 phút
const maxRequests = 100;

function allowRequest() {
  const now = Date.now();

  // Loại bỏ requests cũ hơn window size
  const validRequests = requestLog.filter(
    (timestamp) => now - timestamp < windowSize,
  );

  if (validRequests.length < maxRequests) {
    requestLog.push(now);
    return true;
  }

  return false;
}
```

**Visualization:**

```
                    Current time
                         ↓
|-------|-------|-------|-------|
  54s    55s    56s    57s    58s
   ↑             ↑       ↑
 Old (removed)  Valid  Valid
```

**✅ Ưu điểm:**

- Rất chính xác - không có burst problem
- True sliding window
- Dễ debug (có thể xem toàn bộ request history)

**❌ Nhược điểm:**

- Memory intensive - phải lưu timestamp của mọi request
- Cần cleanup logic để loại bỏ old entries
- Không scale tốt với high traffic

### 2.3 Sliding Window Counter

**Cách hoạt động:**

Đây là hybrid approach kết hợp fixed window với weighted calculation. Bạn duy trì counter cho window hiện tại và window trước, rồi tính rate dựa trên weighted average.

```javascript
const windows = {
  previous: { start: Date.now() - 60000, count: 80 },
  current: { start: Date.now(), count: 20 },
};

function allowRequest() {
  const now = Date.now();
  const windowSize = 60000;
  const maxRequests = 100;

  // Nếu current window đã hết thời gian
  if (now - windows.current.start >= windowSize) {
    windows.previous = windows.current;
    windows.current = { start: now, count: 0 };
  }

  // Tính % overlap với previous window
  const elapsedInCurrent = now - windows.current.start;
  const overlapPercent = (windowSize - elapsedInCurrent) / windowSize;

  // Weighted count
  const estimatedCount =
    windows.previous.count * overlapPercent + windows.current.count;

  if (estimatedCount < maxRequests) {
    windows.current.count++;
    return true;
  }

  return false;
}
```

**✅ Ưu điểm:**

- Chính xác hơn fixed window
- Memory efficient hơn sliding log
- Giảm thiểu burst problem

**❌ Nhược điểm:**

- Phức tạp hơn để implement
- Vẫn có approximation (không 100% chính xác)

### 2.4 Token Bucket

**Cách hoạt động:**

Hãy tưởng tượng một bucket (xô) chứa tokens. Tokens được thêm vào bucket với một rate cố định. Mỗi request tiêu tốn một token. Nếu bucket rỗng, request bị reject.

```
Bucket capacity: 100 tokens
Refill rate: 10 tokens/second

Time 0s:  [====================] 100 tokens
↓ 20 requests
Time 1s:  [================    ] 90 tokens (80 used, +10 refilled)
↓ 5 requests
Time 2s:  [=================   ] 95 tokens (85 used, +10 refilled)
```

**Implementation:**

```javascript
class TokenBucket {
  constructor(capacity, refillRate) {
    this.capacity = capacity;
    this.tokens = capacity;
    this.refillRate = refillRate; // tokens per second
    this.lastRefill = Date.now();
  }

  refill() {
    const now = Date.now();
    const timePassed = (now - this.lastRefill) / 1000; // seconds
    const tokensToAdd = timePassed * this.refillRate;

    this.tokens = Math.min(this.capacity, this.tokens + tokensToAdd);
    this.lastRefill = now;
  }

  allowRequest(cost = 1) {
    this.refill();

    if (this.tokens >= cost) {
      this.tokens -= cost;
      return true;
    }

    return false;
  }
}

// Usage
const bucket = new TokenBucket(100, 10);
if (bucket.allowRequest()) {
  // Process request
}
```

**✅ Ưu điểm:**

- **Cho phép bursts** - Nếu user không dùng hết tokens, họ có thể "tích lũy" để burst sau
- Linh hoạt - Có thể assign different costs cho different operations
- Smooth long-term rate

**❌ Nhược điểm:**

- Có thể cho phép bursts lớn nếu bucket capacity cao
- Cần tune cẩn thận capacity và refill rate

**Use case tốt:** API với variable load patterns, nơi users cần burst occasionally

### 2.5 Leaky Bucket

**Cách hoạt động:**

Tương tự token bucket, nhưng ngược lại: requests được thêm vào queue (bucket) và được xử lý với một rate cố định - giống như nước "rò rỉ" từ một bucket bị thủng.

```
Requests in → [=====Queue=====] → Process out (fixed rate)
              [  R1 R2 R3 R4  ]
                 ↓  ↓  ↓  ↓
              Process 1 request/second
```

**Implementation:**

```javascript
class LeakyBucket {
  constructor(capacity, leakRate) {
    this.capacity = capacity;
    this.queue = [];
    this.leakRate = leakRate; // requests per second
    this.lastLeak = Date.now();
  }

  leak() {
    const now = Date.now();
    const timePassed = (now - this.lastLeak) / 1000;
    const leakCount = Math.floor(timePassed * this.leakRate);

    // Loại bỏ requests đã được "leaked"
    this.queue.splice(0, leakCount);
    this.lastLeak = now;
  }

  allowRequest(request) {
    this.leak();

    if (this.queue.length < this.capacity) {
      this.queue.push(request);
      return true;
    }

    return false; // Bucket đầy, reject request
  }
}
```

**✅ Ưu điểm:**

- **Smooth, constant output rate** - Bảo vệ downstream services
- Có thể queue requests thay vì reject ngay
- Predictable load on backend

**❌ Nhược điểm:**

- Requests có thể bị delay (vì được queue)
- Cần quản lý queue (memory, timeouts)
- Có thể gây latency cao cho users

**Use case tốt:** Khi bạn cần protect downstream service với strict rate requirements

---

## Phần 3: Implementation trong Production

### 3.1 Distributed Systems với Redis

Khi application của bạn chạy trên nhiều servers, bạn cần shared state để track rate limits across all instances. Redis là solution phổ biến nhất.

**Token Bucket với Redis:**

```javascript
const Redis = require("ioredis");
const redis = new Redis();

async function allowRequest(userId, capacity, refillRate) {
  const key = `rate_limit:${userId}`;
  const now = Date.now();

  // Lua script để đảm bảo atomicity
  const script = `
    local key = KEYS[1]
    local capacity = tonumber(ARGV[1])
    local refillRate = tonumber(ARGV[2])
    local now = tonumber(ARGV[3])
    
    local bucket = redis.call('HMGET', key, 'tokens', 'lastRefill')
    local tokens = tonumber(bucket[1]) or capacity
    local lastRefill = tonumber(bucket[2]) or now
    
    -- Refill tokens
    local timePassed = (now - lastRefill) / 1000
    local tokensToAdd = timePassed * refillRate
    tokens = math.min(capacity, tokens + tokensToAdd)
    
    -- Check if request allowed
    if tokens >= 1 then
      tokens = tokens - 1
      redis.call('HMSET', key, 'tokens', tokens, 'lastRefill', now)
      redis.call('EXPIRE', key, 3600)
      return 1
    else
      return 0
    end
  `;

  const allowed = await redis.eval(script, 1, key, capacity, refillRate, now);

  return allowed === 1;
}
```

**Tại sao dùng Lua scripts?**

- Đảm bảo atomicity - Toàn bộ operation chạy như một transaction
- Giảm network round-trips
- Tránh race conditions trong concurrent environments

### 3.2 Single Server với In-Memory Storage

Nếu bạn chỉ có một server instance, in-memory implementation đơn giản hơn nhiều:

```javascript
const rateLimits = new Map();

function getRateLimit(userId) {
  if (!rateLimits.has(userId)) {
    rateLimits.set(userId, {
      tokens: 100,
      lastRefill: Date.now(),
    });
  }
  return rateLimits.get(userId);
}

// Cleanup old entries periodically
setInterval(() => {
  const now = Date.now();
  const timeout = 3600000; // 1 hour

  for (const [userId, data] of rateLimits.entries()) {
    if (now - data.lastRefill > timeout) {
      rateLimits.delete(userId);
    }
  }
}, 60000); // Check every minute
```

### 3.3 Express Middleware Example

Thực tế, bạn thường implement rate limiting như một middleware:

```javascript
const rateLimit = require("express-rate-limit");

// Basic rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit: 100 requests per windowMs
  message: "Too many requests from this IP, please try again later.",
  standardHeaders: true, // Return rate limit info in headers
  legacyHeaders: false,
});

// Apply to all routes
app.use(limiter);

// Different limits for different routes
const strictLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: "Too many authentication attempts",
});

app.post("/api/login", strictLimiter, loginHandler);
```

### 3.4 Rate Limit Headers - Standard Practice

Khi implement rate limiting, **luôn luôn** trả về các HTTP headers để clients biết status:

```javascript
function setRateLimitHeaders(res, limit, remaining, reset) {
  // Số requests tối đa trong window
  res.setHeader("X-RateLimit-Limit", limit);

  // Số requests còn lại
  res.setHeader("X-RateLimit-Remaining", remaining);

  // Timestamp khi rate limit reset (Unix epoch seconds)
  res.setHeader("X-RateLimit-Reset", reset);
}

// Example response headers:
// X-RateLimit-Limit: 100
// X-RateLimit-Remaining: 42
// X-RateLimit-Reset: 1678886400
```

**Tại sao quan trọng?**

- Clients có thể implement intelligent backoff logic
- Developers có thể debug rate limiting issues
- Monitoring tools có thể track rate limit usage

---

## Phần 4: Xử Lý Khi User Vượt Limit

### 4.1 HTTP 429 Status Code

Khi user vượt quá rate limit, **luôn return HTTP 429 Too Many Requests**:

```javascript
function handleRateLimitExceeded(req, res, resetTime) {
  const retryAfter = Math.ceil((resetTime - Date.now()) / 1000);

  res
    .status(429)
    .set({
      "Retry-After": retryAfter, // Seconds until retry
      "X-RateLimit-Reset": Math.floor(resetTime / 1000),
    })
    .json({
      error: "Too Many Requests",
      message: "You have exceeded the rate limit. Please try again later.",
      retryAfter: retryAfter,
    });
}
```

### 4.2 Retry-After Header

**Retry-After header** cho client biết khi nào họ có thể retry:

```
Retry-After: 120
```

Hoặc sử dụng HTTP-date:

```
Retry-After: Wed, 21 Oct 2026 07:28:00 GMT
```

**Best practice:** Sử dụng seconds để đơn giản hơn

### 4.3 Clear Error Messages

Error response nên clear và actionable:

```json
{
  "error": "rate_limit_exceeded",
  "message": "You have made too many requests. Please wait before trying again.",
  "details": {
    "limit": 100,
    "window": "1 hour",
    "retryAfter": 120,
    "resetAt": "2026-03-17T14:30:00Z"
  },
  "documentation": "https://api.example.com/docs/rate-limits"
}
```

### 4.4 User Experience Considerations

**Frontend Implementation:**

```javascript
async function makeApiCall(url, options = {}) {
  try {
    const response = await fetch(url, options);

    if (response.status === 429) {
      const retryAfter = response.headers.get("Retry-After");
      const resetTime = response.headers.get("X-RateLimit-Reset");

      // Show user-friendly message
      showNotification(
        `Too many requests. Please wait ${retryAfter} seconds.`,
        "warning",
      );

      // Optional: Auto-retry after delay
      if (options.autoRetry) {
        await sleep(retryAfter * 1000);
        return makeApiCall(url, options);
      }

      throw new Error("Rate limit exceeded");
    }

    return response.json();
  } catch (error) {
    console.error("API call failed:", error);
    throw error;
  }
}
```

**Exponential Backoff:**

Đối với automated clients, implement exponential backoff:

```javascript
async function fetchWithRetry(url, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url);

      if (response.ok) {
        return response.json();
      }

      if (response.status === 429) {
        const retryAfter = parseInt(
          response.headers.get("Retry-After") || "60",
        );

        // Exponential backoff with jitter
        const delay = retryAfter * 1000 * Math.pow(2, i) + Math.random() * 1000;

        console.log(`Rate limited. Retrying in ${delay}ms...`);
        await sleep(delay);
        continue;
      }

      throw new Error(`HTTP ${response.status}`);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
    }
  }
}
```

---

## Key Takeaways

1. **Rate limiting là essential** - Không phải optional feature, mà là core requirement cho production APIs

2. **Chọn strategy phù hợp:**
   - Fixed window: Đơn giản nhất, OK cho basic use cases
   - Sliding window: Chính xác hơn, tốt cho most applications
   - Token bucket: Tốt nhất cho variable load, cho phép bursts hợp lý
   - Leaky bucket: Tốt cho protecting downstream services với strict rate requirements

3. **Use Redis cho distributed systems** - Đảm bảo consistency across multiple instances

4. **Luôn return proper headers:**
   - `X-RateLimit-Limit`
   - `X-RateLimit-Remaining`
   - `X-RateLimit-Reset`
   - `Retry-After` (khi status 429)

5. **Error handling quan trọng:**
   - Status 429 với clear message
   - Provide retry timing information
   - Documentation links

6. **Think about UX** - Rate limiting không chỉ là technical feature, mà ảnh hưởng đến user experience. Balance giữa security/resource protection với usability.

## Kết Luận

Rate limiting là một trong những patterns quan trọng nhất trong API design. Nó bảo vệ resources, đảm bảo fair usage, và ngăn chặn abuse - tất cả đều critical cho một production system ổn định và scalable.

Start with simple approach (fixed window hoặc sliding window), monitor usage patterns, và evolve strategy của bạn based on actual needs. Và nhớ rằng: rate limiting không chỉ về limiting - mà về enabling sustainable, fair, và reliable service cho tất cả users.

**Next steps:**

- Implement rate limiting trong API hiện tại của bạn
- Monitor rate limit metrics (rejection rate, popular limits hit, etc.)
- Document rate limits rõ ràng cho API consumers
- Consider different tiers (free, paid) với different limits
- Set up alerts khi có unusual rate limit patterns

**Resources:**

- [RFC 6585 - HTTP Status Code 429](https://datatracker.ietf.org/doc/html/rfc6585)
- [Redis Rate Limiting Patterns](https://redis.io/docs/manual/patterns/rate-limiter/)
- [Express Rate Limit Library](https://www.npmjs.com/package/express-rate-limit)
