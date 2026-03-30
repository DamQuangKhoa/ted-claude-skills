# Làm Chủ TypeScript Utility Types: Hướng Dẫn Toàn Diện

Các utility types của TypeScript là công cụ mạnh mẽ giúp bạn biến đổi và thao tác với types một cách dễ dàng. Dù bạn đang xây dựng một dự án nhỏ hay một ứng dụng quy mô lớn, việc hiểu rõ các utilities này có thể cải thiện đáng kể chất lượng code và trải nghiệm lập trình. Hãy cùng tìm hiểu 10 utility types quan trọng mà mọi developer TypeScript nên biết.

## 1. Partial&lt;T&gt; - Biến Properties Thành Optional

### Nó Làm Gì

`Partial<T>` biến đổi tất cả các properties của type `T` thành optional. Điều này cực kỳ hữu ích khi bạn chỉ muốn cập nhật một số trường cụ thể của một object.

### Ví Dụ

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  age: number;
}

// Tất cả properties đều trở thành optional
type PartialUser = Partial<User>;

function updateUser(id: number, updates: PartialUser) {
  // Có thể cập nhật bất kỳ tập con properties nào
  console.log(`Đang cập nhật user ${id}`, updates);
}

// Các lời gọi hợp lệ
updateUser(1, { name: "Alice" });
updateUser(2, { email: "bob@example.com", age: 30 });
```

### Khi Nào Sử Dụng

- **Thao tác cập nhật**: Khi bạn chỉ cần cập nhật một số trường của entity
- **Xử lý form**: Gửi form một phần mà không yêu cầu tất cả các trường
- **Configuration objects**: Khi một số tùy chọn config là optional

### Tình Huống Thực Tế

Trong tính năng cập nhật profile người dùng, bạn có thể muốn cho phép users cập nhật tên của họ mà không bắt buộc cung cấp toàn bộ thông tin profile:

```typescript
class UserService {
  async updateProfile(userId: string, updates: Partial<User>) {
    // Chỉ cập nhật các trường được cung cấp
    return await database.update({ id: userId }, updates);
  }
}

// User có thể chỉ cập nhật tên
await userService.updateProfile("123", { name: "Tên Mới" });
```

## 2. Required&lt;T&gt; - Biến Tất Cả Properties Thành Required

### Nó Làm Gì

`Required<T>` là đối lập của `Partial<T>`. Nó biến đổi tất cả các optional properties thành required.

### Ví Dụ

```typescript
interface Config {
  host?: string;
  port?: number;
  timeout?: number;
}

// Tất cả properties trở thành required
type RequiredConfig = Required<Config>;

function initializeServer(config: RequiredConfig) {
  // Tất cả properties phải được cung cấp
  console.log(`Khởi động server tại ${config.host}:${config.port}`);
}

// Lỗi: Thiếu properties
// initializeServer({ host: "localhost" });

// Đúng
initializeServer({
  host: "localhost",
  port: 3000,
  timeout: 5000,
});
```

### Khi Nào Sử Dụng

- **Validation**: Đảm bảo tất cả các trường optional được cung cấp trước khi xử lý
- **Initialization**: Khi thiết lập objects cần tất cả các trường được định nghĩa
- **Type narrowing**: Chuyển đổi optional types thành required cho các thao tác cụ thể

### Tình Huống Thực Tế

Khi khởi tạo kết nối database, bạn có thể chấp nhận config optional trong quá trình setup nhưng yêu cầu tất cả giá trị trước khi kết nối:

```typescript
interface DatabaseConfig {
  host?: string;
  port?: number;
  username?: string;
  password?: string;
}

class Database {
  private config: Partial<DatabaseConfig> = {};

  configure(config: Partial<DatabaseConfig>) {
    this.config = { ...this.config, ...config };
  }

  connect(finalConfig?: Partial<DatabaseConfig>) {
    const fullConfig: Required<DatabaseConfig> = {
      host: this.config.host ?? finalConfig?.host ?? "localhost",
      port: this.config.port ?? finalConfig?.port ?? 5432,
      username: this.config.username ?? finalConfig?.username ?? "",
      password: this.config.password ?? finalConfig?.password ?? "",
    };

    // Bây giờ đảm bảo có tất cả properties
    console.log(`Kết nối đến ${fullConfig.host}:${fullConfig.port}`);
  }
}
```

## 3. Readonly&lt;T&gt; - Properties Bất Biến

### Nó Làm Gì

`Readonly<T>` làm cho tất cả các properties của type `T` chỉ đọc (read-only), ngăn chặn mọi sửa đổi sau khi tạo.

### Ví Dụ

```typescript
interface Point {
  x: number;
  y: number;
}

const mutablePoint: Point = { x: 10, y: 20 };
mutablePoint.x = 30; // OK

const immutablePoint: Readonly<Point> = { x: 10, y: 20 };
// immutablePoint.x = 30; // Lỗi: Không thể gán cho 'x'
```

### Khi Nào Sử Dụng

- **Cấu trúc dữ liệu bất biến**: Khi bạn muốn ngăn chặn các thay đổi không mong muốn
- **Configuration objects**: Đảm bảo config không bị sửa đổi sau khi khởi tạo
- **Lập trình hàm**: Tạo các hàm thuần túy với inputs bất biến

### Tình Huống Thực Tế

Trong một hệ thống component giống React, bạn có thể muốn đảm bảo props không bị sửa đổi:

```typescript
interface ButtonProps {
  label: string;
  onClick: () => void;
  disabled: boolean;
}

function Button(props: Readonly<ButtonProps>) {
  // props.label = "Label Mới"; // Lỗi!

  return {
    render: () =>
      `<button disabled="${props.disabled}">${props.label}</button>`,
  };
}

// Props được bảo vệ khỏi sửa đổi
const btn = Button({
  label: "Nhấn vào tôi",
  onClick: () => console.log("Đã nhấn"),
  disabled: false,
});
```

## 4. Pick&lt;T, K&gt; - Chọn Properties Cụ Thể

### Nó Làm Gì

`Pick<T, K>` tạo một type mới bằng cách chỉ chọn các properties `K` được chỉ định từ type `T`.

### Ví Dụ

```typescript
interface Article {
  id: number;
  title: string;
  content: string;
  author: string;
  publishedAt: Date;
  tags: string[];
}

// Chỉ các trường này
type ArticlePreview = Pick<Article, "id" | "title" | "author">;

function showPreview(preview: ArticlePreview) {
  console.log(`${preview.title} bởi ${preview.author}`);
}

const article: Article = {
  id: 1,
  title: "Hướng Dẫn TypeScript",
  content: "Nội dung dài...",
  author: "Alice",
  publishedAt: new Date(),
  tags: ["typescript", "tutorial"],
};

// Chỉ truyền các trường cần thiết
showPreview({
  id: article.id,
  title: article.title,
  author: article.author,
});
```

### Khi Nào Sử Dụng

- **API responses**: Trả về chỉ các trường cần thiết cho clients
- **Data transfer objects**: Tạo phiên bản nhẹ của các types phức tạp
- **Component props**: Trích xuất các properties cụ thể cho child components

### Tình Huống Thực Tế

Xây dựng chế độ xem danh sách chỉ cần thông tin tóm tắt:

```typescript
interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  inventory: number;
  supplier: string;
  images: string[];
  specifications: Record<string, any>;
}

type ProductListItem = Pick<Product, "id" | "name" | "price" | "images">;

class ProductService {
  async getProductList(): Promise<ProductListItem[]> {
    // Chỉ lấy các trường cần thiết từ database
    const products = await db.query(`
      SELECT id, name, price, images 
      FROM products
    `);
    return products;
  }
}
```

## 5. Omit&lt;T, K&gt; - Loại Bỏ Properties Cụ Thể

### Nó Làm Gì

`Omit<T, K>` tạo một type mới bằng cách loại bỏ các properties `K` được chỉ định từ type `T`. Nó là đối lập của `Pick`.

### Ví Dụ

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

// Loại bỏ các trường nhạy cảm
type PublicUser = Omit<User, "password">;

function displayUser(user: PublicUser) {
  console.log(user.email); // OK
  // console.log(user.password); // Lỗi: Property không tồn tại
}
```

### Khi Nào Sử Dụng

- **Bảo mật**: Loại bỏ các trường nhạy cảm trước khi gửi dữ liệu
- **Xử lý form**: Loại trừ các trường được tính toán hoặc trường hệ thống khỏi input của user
- **API responses**: Lọc ra các trường nội bộ

### Tình Huống Thực Tế

Tạo object user an toàn cho API responses:

```typescript
interface UserEntity {
  id: string;
  username: string;
  email: string;
  password: string;
  salt: string;
  refreshToken: string;
  role: string;
  createdAt: Date;
}

type UserResponse = Omit<UserEntity, "password" | "salt" | "refreshToken">;

class AuthController {
  async getProfile(userId: string): Promise<UserResponse> {
    const user = await db.users.findById(userId);

    // TypeScript đảm bảo các trường nhạy cảm không được bao gồm
    const safeUser: UserResponse = {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
    };

    return safeUser;
  }
}
```

## 6. Record&lt;K, T&gt; - Tạo Object Types

### Nó Làm Gì

`Record<K, T>` tạo một object type với keys của type `K` và values của type `T`. Nó hoàn hảo cho việc tạo các cấu trúc giống dictionary.

### Ví Dụ

```typescript
// String keys, number values
type PageViews = Record<string, number>;

const analytics: PageViews = {
  "/home": 1500,
  "/about": 300,
  "/contact": 150,
};

// Union keys, specific type values
type Theme = "light" | "dark" | "auto";
type ThemeConfig = Record<Theme, { background: string; text: string }>;

const themes: ThemeConfig = {
  light: { background: "#ffffff", text: "#000000" },
  dark: { background: "#000000", text: "#ffffff" },
  auto: { background: "system", text: "system" },
};
```

### Khi Nào Sử Dụng

- **Dictionaries/Maps**: Khi bạn cần các cấu trúc key-value pair
- **Configuration mappings**: Ánh xạ keys đến configuration objects
- **Lookup tables**: Tạo các cấu trúc dữ liệu được đánh index

### Tình Huống Thực Tế

Quản lý quyền của ứng dụng với role-based access:

```typescript
type Permission = "read" | "write" | "delete" | "admin";
type Role = "user" | "moderator" | "admin";

type RolePermissions = Record<Role, Permission[]>;

const permissions: RolePermissions = {
  user: ["read"],
  moderator: ["read", "write"],
  admin: ["read", "write", "delete", "admin"],
};

function canPerform(role: Role, action: Permission): boolean {
  return permissions[role].includes(action);
}

console.log(canPerform("user", "write")); // false
console.log(canPerform("moderator", "write")); // true
```

## 7. Exclude&lt;T, U&gt; - Loại Bỏ Types Khỏi Unions

### Nó Làm Gì

`Exclude<T, U>` loại bỏ các types từ union `T` mà có thể gán cho `U`.

### Ví Dụ

```typescript
type AllowedColors = "red" | "blue" | "green" | "yellow" | "purple";
type PrimaryColors = "red" | "blue" | "yellow";

// Loại bỏ màu nguyên thủy
type SecondaryColors = Exclude<AllowedColors, PrimaryColors>;
// Kết quả: 'green' | 'purple'

function mixSecondaryColor(color: SecondaryColors) {
  console.log(`Đang pha màu ${color}`);
}

mixSecondaryColor("green"); // OK
mixSecondaryColor("purple"); // OK
// mixSecondaryColor('red'); // Lỗi
```

### Khi Nào Sử Dụng

- **Lọc type**: Loại bỏ các types cụ thể khỏi unions
- **Xử lý sự kiện**: Loại trừ một số loại sự kiện nhất định
- **Validation**: Tạo các tập hợp type bị hạn chế

### Tình Huống Thực Tế

Tạo một hệ thống sự kiện type-safe với các loại trừ sự kiện cụ thể:

```typescript
type AppEvent =
  | "user:login"
  | "user:logout"
  | "user:update"
  | "admin:login"
  | "admin:action"
  | "system:error"
  | "system:warning";

// Tạo các sự kiện chỉ cho user (loại trừ admin và system)
type UserEvent = Exclude<AppEvent, `admin:${string}` | `system:${string}`>;

class UserEventLogger {
  log(event: UserEvent, data: any) {
    // Chỉ có thể log các sự kiện của user
    console.log(`Sự kiện user: ${event}`, data);
  }
}

const logger = new UserEventLogger();
logger.log("user:login", { userId: "123" }); // OK
// logger.log('admin:login', {}); // Lỗi
```

## 8. Extract&lt;T, U&gt; - Trích Xuất Types Từ Unions

### Nó Làm Gì

`Extract<T, U>` trích xuất từ union `T` chỉ những types có thể gán cho `U`. Nó là đối lập của `Exclude`.

### Ví Dụ

```typescript
type Response = string | number | boolean | null;

// Trích xuất chỉ các primitive types
type PrimitiveResponse = Extract<Response, string | number | boolean>;
// Kết quả: string | number | boolean

type NullableResponse = Extract<Response, null>;
// Kết quả: null
```

### Khi Nào Sử Dụng

- **Type narrowing**: Trích xuất các types cụ thể từ unions
- **Logic có điều kiện**: Làm việc với tập con của union types
- **Lọc**: Chọn các types khớp từ unions phức tạp

### Tình Huống Thực Tế

Xử lý các loại response khác nhau từ một API:

```typescript
type ApiResponse<T> =
  | { status: "success"; data: T }
  | { status: "error"; error: string }
  | { status: "loading" }
  | { status: "idle" };

type SuccessResponse<T> = Extract<ApiResponse<T>, { status: "success" }>;
type ErrorResponse = Extract<ApiResponse<any>, { status: "error" }>;

function handleSuccess<T>(response: SuccessResponse<T>) {
  // TypeScript biết điều này có property 'data'
  console.log("Thành công:", response.data);
}

function handleError(response: ErrorResponse) {
  // TypeScript biết điều này có property 'error'
  console.error("Lỗi:", response.error);
}

const apiResult: ApiResponse<User> = {
  status: "success",
  data: { id: 1, name: "Alice" },
};

if (apiResult.status === "success") {
  handleSuccess(apiResult);
}
```

## 9. NonNullable&lt;T&gt; - Loại Trừ Null Và Undefined

### Nó Làm Gì

`NonNullable<T>` loại bỏ `null` và `undefined` khỏi type `T`, đảm bảo type luôn được định nghĩa.

### Ví Dụ

```typescript
type MaybeString = string | null | undefined;

type DefiniteString = NonNullable<MaybeString>;
// Kết quả: string

function processValue(value: NonNullable<MaybeString>) {
  // value được đảm bảo là một string
  console.log(value.toUpperCase());
}

const val1: MaybeString = "hello";
const val2: MaybeString = null;

if (val1 !== null && val1 !== undefined) {
  processValue(val1); // OK
}

// processValue(val2); // Lỗi
```

### Khi Nào Sử Dụng

- **Null safety**: Đảm bảo các giá trị được định nghĩa trước khi sử dụng
- **API responses**: Xử lý dữ liệu optional phải được validate
- **Data validation**: Chuyển đổi nullable types thành non-nullable

### Tình Huống Thực Tế

Xử lý an toàn kết quả truy vấn database:

```typescript
interface QueryResult<T> {
  data: T | null;
  error: string | null;
}

class DataService {
  async getUser(id: string): Promise<NonNullable<User>> {
    const result: QueryResult<User> = await db.query(
      "SELECT * FROM users WHERE id = ?",
      [id],
    );

    if (result.data === null) {
      throw new Error("Không tìm thấy user");
    }

    // TypeScript bây giờ biết result.data là User, không phải User | null
    return result.data;
  }

  async getUsers(ids: string[]): Promise<NonNullable<User>[]> {
    const results = await Promise.all(ids.map((id) => db.query("...")));

    // Lọc các giá trị null và chỉ trả về users hợp lệ
    return results
      .map((r) => r.data)
      .filter((user): user is NonNullable<User> => user !== null);
  }
}
```

## 10. ReturnType&lt;T&gt; - Lấy Return Types Của Function

### Nó Làm Gì

`ReturnType<T>` trích xuất return type của một function type `T`. Điều này cực kỳ hữu ích để suy luận types từ các functions hiện có.

### Ví Dụ

```typescript
function createUser(name: string, age: number) {
  return {
    id: Math.random(),
    name,
    age,
    createdAt: new Date(),
  };
}

// Suy luận return type
type User = ReturnType<typeof createUser>;
// Kết quả: { id: number; name: string; age: number; createdAt: Date }

function processUser(user: User) {
  console.log(`User ${user.name} ${user.age} tuổi`);
}

const newUser = createUser("Alice", 30);
processUser(newUser); // Type-safe!
```

### Khi Nào Sử Dụng

- **Type inference**: Tránh nhân đôi định nghĩa type
- **Factory functions**: Trích xuất types từ outputs của function
- **API clients**: Suy luận response types từ methods

### Tình Huống Thực Tế

Xây dựng API clients type-safe mà không nhân đôi types:

```typescript
class ApiClient {
  async fetchUserProfile(userId: string) {
    const response = await fetch(`/api/users/${userId}`);
    return {
      id: userId,
      name: "Tên User",
      email: "user@example.com",
      preferences: {
        theme: "dark",
        language: "vi",
      },
      stats: {
        posts: 42,
        followers: 150,
      },
    };
  }

  async fetchPosts(userId: string) {
    return [
      { id: "1", title: "Bài viết 1", content: "Nội dung..." },
      { id: "2", title: "Bài viết 2", content: "Nội dung..." },
    ];
  }
}

const api = new ApiClient();

// Suy luận types từ methods
type UserProfile =
  ReturnType<typeof api.fetchUserProfile> extends Promise<infer T> ? T : never;
type Post =
  ReturnType<typeof api.fetchPosts> extends Promise<Array<infer T>> ? T : never;

// Bây giờ chúng ta có thể sử dụng các types này trong toàn bộ app
function displayProfile(profile: UserProfile) {
  console.log(`${profile.name} (${profile.email})`);
  console.log(`Theme: ${profile.preferences.theme}`);
}

function displayPosts(posts: Post[]) {
  posts.forEach((post) => console.log(post.title));
}

// Sử dụng
const profile = await api.fetchUserProfile("123");
const posts = await api.fetchPosts("123");

displayProfile(profile); // Type-safe
displayPosts(posts); // Type-safe
```

## Kết Hợp Utility Types

Sức mạnh thực sự đến từ việc kết hợp các utility types:

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  role: "admin" | "user";
  createdAt: Date;
}

// Tạo type cập nhật an toàn, partial
type UserUpdate = Partial<Omit<User, "id" | "createdAt">>;

// Public user chỉ đọc
type PublicUser = Readonly<Omit<User, "password">>;

// Các trường đăng ký bắt buộc
type UserRegistration = Required<Pick<User, "name" | "email" | "password">>;

function updateUser(id: string, updates: UserUpdate) {
  // Có thể cập nhật bất kỳ trường nào ngoại trừ id và createdAt
}

function getPublicProfile(userId: string): PublicUser {
  // Trả về user bất biến không có password
  return {} as PublicUser;
}

function registerUser(data: UserRegistration) {
  // Tất cả các trường bắt buộc phải được cung cấp
}
```

## Kết Luận

Các utility types của TypeScript là công cụ thiết yếu để viết code type-safe và dễ bảo trì. Chúng giúp bạn:

- **Biến đổi types** mà không cần nhân đôi định nghĩa
- **Thực thi ràng buộc** tại compile time
- **Cải thiện tính an toàn của code** bằng cách phát hiện lỗi sớm
- **Nâng cao trải nghiệm developer** với autocomplete tốt hơn

Bắt đầu kết hợp các utility types này vào các dự án của bạn, và bạn sẽ thấy code TypeScript của mình trở nên mạnh mẽ hơn và dễ bảo trì hơn. Hãy nhớ, chìa khóa là sử dụng chúng khi hợp lý – không phải mọi type đều cần được bọc trong utilities, nhưng khi bạn cần chúng, chúng vô cùng quý giá.

Chúc bạn code vui vẻ! 🎉
