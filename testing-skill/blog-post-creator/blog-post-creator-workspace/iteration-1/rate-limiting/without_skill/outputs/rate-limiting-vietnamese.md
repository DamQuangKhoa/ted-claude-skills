# Hướng Dẫn Toàn Diện Về Rate Limiting Cho API

Rate limiting là một kỹ thuật quan trọng trong thiết kế API, giúp kiểm soát số lượng request mà một client có thể gửi trong một khoảng thời gian nhất định. Dù bạn đang xây dựng API public hay internal service, việc triển khai rate limiting đúng cách sẽ đảm bảo hệ thống của bạn ổn định, công bằng và tiết kiệm chi phí.

## Tại Sao Cần Rate Limiting?

### Ngăn Chặn Lạm Dụng

Không có rate limiting, các tin tặc hoặc client được thiết kế kém có thể làm quá tải API của bạn với số lượng request khổng lồ. Rate limiting đóng vai trò là tuyến phòng thủ đầu tiên chống lại các cuộc tấn công denial-of-service và các đợt tăng traffic bất thường.

### Bảo Vệ Tài Nguyên

Hạ tầng của bạn có năng lực giới hạn. Kết nối database, CPU, và bộ nhớ đều là tài nguyên hữu hạn. Bằng cách giới hạn request đến, bạn đảm bảo hệ thống hoạt động trong giới hạn an toàn và duy trì hiệu suất ổn định cho tất cả người dùng.

### Sử Dụng Công Bằng

Rate limiting đảm bảo không có user nào độc chiếm API của bạn. Điều này tạo ra sân chơi bình đẳng, nơi tất cả các client đều nhận được phần tài nguyên công bằng, ngăn không cho một user có lưu lượng cao làm giảm trải nghiệm của những người khác.

### Kiểm Soát Chi Phí

Nhiều API dựa vào các dịch vụ bên thứ ba hoặc tài nguyên cloud tính phí theo request. Rate limiting giúp bạn dự đoán và kiểm soát chi phí vận hành bằng cách giới hạn throughput tối đa mà hệ thống cần xử lý.

## Các Chiến Lược Rate Limiting

Lựa chọn thuật toán rate limiting phù hợp phụ thuộc vào use case của bạn. Dưới đây là bốn chiến lược phổ biến nhất:

### 1. Fixed Window (Cửa Sổ Cố Định)

Thuật toán fixed window là cách tiếp cận đơn giản nhất. Nó duy trì một bộ đếm theo dõi request trong các khoảng thời gian cố định (ví dụ: mỗi phút hoặc mỗi giờ). Khi khoảng thời gian kết thúc, bộ đếm reset về 0.

**Cách hoạt động:**

- Bắt đầu đếm tại thời điểm 0
- Tăng bộ đếm cho mỗi request
- Reset bộ đếm khi kết thúc mỗi window

**Ưu điểm:**

- Đơn giản để triển khai
- Ít tốn bộ nhớ
- Dễ hiểu

**Nhược điểm:**

- Dễ bị tấn công burst traffic tại biên của window
- User có thể gửi gấp đôi giới hạn bằng cách tính toán thời điểm tại biên window

**Phù hợp cho:** Ứng dụng đơn giản có thể chấp nhận burst thỉnh thoảng.

### 2. Sliding Window (Cửa Sổ Trượt)

Thuật toán sliding window cung cấp rate limiting chính xác hơn bằng cách tính toán rate dựa trên window trước đó cộng với window hiện tại. Điều này giải quyết vấn đề edge case của fixed window.

**Cách hoạt động:**

- Theo dõi request trong window hiện tại
- Tính toán weighted contribution từ window trước
- Từ chối nếu tổng số vượt giới hạn

**Ưu điểm:**

- Chính xác hơn fixed window
- Ngăn chặn tấn công burst tại biên window
- Vẫn tương đối đơn giản

**Nhược điểm:**

- Phức tạp hơn một chút để triển khai
- Cần lưu trữ dữ liệu từ window trước

**Phù hợp cho:** Production API nơi độ chính xác quan trọng.

### 3. Token Bucket (Thùng Token)

Thuật toán token bucket cho phép burst có kiểm soát trong khi duy trì average rate. Token được thêm vào thùng với tốc độ ổn định, và mỗi request tiêu thụ một token. Nếu thùng rỗng, request bị từ chối.

**Cách hoạt động:**

- Thùng chứa token đến sức chứa tối đa
- Token được thêm với tốc độ cố định
- Mỗi request tiêu thụ một token
- Request thất bại khi thùng rỗng

**Ưu điểm:**

- Cho phép burst traffic hợp lệ
- Tốt cho workload biến đổi
- Linh hoạt và có thể cấu hình

**Nhược điểm:**

- Phức tạp hơn để triển khai đúng
- Cần điều chỉnh cẩn thận kích thước thùng và tốc độ refill

**Phù hợp cho:** API có pattern tải biến đổi và nhu cầu burst hợp lệ.

### 4. Leaky Bucket (Thùng Dột)

Thuật toán leaky bucket xử lý request với tốc độ cố định, xếp hàng các request dư thừa trong một thùng. Request "rò rỉ" từ thùng với tốc độ ổn định. Khi thùng tràn, request mới bị từ chối.

**Cách hoạt động:**

- Request vào hàng đợi (thùng)
- Request được xử lý với tốc độ cố định
- Hàng đợi có kích thước tối đa
- Request tràn bị từ chối

**Ưu điểm:**

- Làm mượt các đợt tăng traffic
- Output rate có thể dự đoán
- Bảo vệ các service downstream

**Nhược điểm:**

- Thêm độ trễ do queuing
- Có thể tích lũy request cũ
- Phức tạp hơn các cách tiếp cận khác

**Phù hợp cho:** Hệ thống yêu cầu tải mượt và có thể dự đoán trên backend service.

## Hướng Dẫn Triển Khai

### Chọn Storage Backend

**Redis cho Hệ Thống Phân Tán:**

```javascript
const redis = require("redis");
const client = redis.createClient();

async function checkRateLimit(userId, limit, windowSeconds) {
  const key = `rate_limit:${userId}`;
  const current = await client.incr(key);

  if (current === 1) {
    await client.expire(key, windowSeconds);
  }

  return current <= limit;
}
```

**In-Memory cho Single Server:**

```javascript
const rateLimitMap = new Map();

function checkRateLimit(userId, limit, windowMs) {
  const now = Date.now();
  const userLimit = rateLimitMap.get(userId) || {
    count: 0,
    resetTime: now + windowMs,
  };

  if (now > userLimit.resetTime) {
    userLimit.count = 0;
    userLimit.resetTime = now + windowMs;
  }

  userLimit.count++;
  rateLimitMap.set(userId, userLimit);

  return userLimit.count <= limit;
}
```

### Ví Dụ Express Middleware

```javascript
const rateLimit = (limit, windowMs) => {
  return async (req, res, next) => {
    const userId = req.user?.id || req.ip;
    const key = `rate_limit:${userId}`;

    const current = await redis.incr(key);
    const ttl = await redis.ttl(key);

    if (ttl === -1) {
      await redis.expire(key, Math.floor(windowMs / 1000));
    }

    // Set rate limit headers
    res.setHeader("X-RateLimit-Limit", limit);
    res.setHeader("X-RateLimit-Remaining", Math.max(0, limit - current));
    res.setHeader("X-RateLimit-Reset", Date.now() + ttl * 1000);

    if (current > limit) {
      return res.status(429).json({
        error: "Too Many Requests",
        message: `Vượt giới hạn rate. Thử lại sau ${ttl} giây.`,
      });
    }

    next();
  };
};

// Sử dụng
app.use("/api/", rateLimit(100, 60000)); // 100 request mỗi phút
```

### Rate Limit Headers

Các header chuẩn cần include trong response:

- **X-RateLimit-Limit:** Số request tối đa cho phép trong window
- **X-RateLimit-Remaining:** Số request còn lại trong window hiện tại
- **X-RateLimit-Reset:** Unix timestamp khi limit được reset

Các header này giúp client triển khai retry logic thông minh và tránh vượt limit.

## Xử Lý Khi Vi Phạm Rate Limit

Khi user vượt quá rate limit, API của bạn cần phản hồi thích hợp:

### Trả Về Status Code 429

HTTP 429 "Too Many Requests" là status code chuẩn để chỉ ra rate limiting.

```javascript
res.status(429).json({
  error: "Too Many Requests",
  message: "Vượt giới hạn rate",
});
```

### Include Retry-After Header

Cho client biết khi nào có thể retry:

```javascript
res.setHeader("Retry-After", 60); // giây cho đến khi reset
```

### Cung Cấp Error Message Rõ Ràng

Giúp developer debug vấn đề rate limit:

```javascript
{
  "error": "rate_limit_exceeded",
  "message": "Bạn đã vượt giới hạn rate là 100 request mỗi phút.",
  "limit": 100,
  "remaining": 0,
  "reset": 1648234560,
  "reset_human": "2024-03-25T12:56:00Z"
}
```

## Best Practices

1. **Document limit rõ ràng** - Làm cho rate limit hiển thị trong tài liệu API
2. **Sử dụng tiered limit** - Limit khác nhau cho user free vs. paid
3. **Triển khai từ từ** - Bắt đầu với limit rộng rãi và thắt chặt dần khi cần
4. **Monitor và alert** - Theo dõi rate limit hit để xác định vấn đề
5. **Cung cấp upgrade path** - Cho phép user yêu cầu limit cao hơn khi cần
6. **Test kỹ lưỡng** - Đảm bảo limit hoạt động đúng trong nhiều scenario

## Kết Luận

Rate limiting là thiết yếu để xây dựng API mạnh mẽ, công bằng và có khả năng mở rộng. Bắt đầu với cách tiếp cận fixed window đơn giản cho nhu cầu cơ bản, sau đó nâng cấp lên sliding window hoặc token bucket khi yêu cầu tăng lên. Nhớ truyền đạt limit rõ ràng qua header và tài liệu, và luôn cung cấp error message hữu ích khi limit bị vượt.

Đầu tư vào rate limiting đúng cách sẽ mang lại lợi ích về tính ổn định hệ thống, phân phối tài nguyên công bằng, và user hài lòng hơn. API của bạn—và team infrastructure—sẽ cảm ơn bạn.
