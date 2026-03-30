# Hướng Dẫn Đầy Đủ về TypeScript Utility Types: 10 Công Cụ Mạnh Mẽ Bạn Cần Biết

> **Dành cho các developer muốn viết TypeScript code an toàn và linh hoạt hơn**

Bạn đã bao giờ phải copy-paste type definitions, tạo lại types tương tự nhau, hay viết đi viết lại các interface chỉ để thay đổi vài properties? TypeScript cung cấp một bộ công cụ mạnh mẽ gọi là **Utility Types** giúp bạn transform và manipulate types một cách elegant và type-safe.

Trong hướng dẫn này, chúng ta sẽ khám phá 10 utility types quan trọng nhất, từ cơ bản đến nâng cao, với các ví dụ thực tế và scenarios mà bạn sẽ gặp trong công việc hàng ngày.

## TL;DR

TypeScript Utility Types là các generic types built-in giúp transform types một cách linh hoạt:

| Utility Type     | Mục Đích                              | Use Case Phổ Biến                    |
| :--------------- | :------------------------------------ | :----------------------------------- |
| `Partial<T>`     | Biến tất cả properties thành optional | Form updates, patches, configuration |
| `Required<T>`    | Biến tất cả properties thành required | Validation, type guards              |
| `Readonly<T>`    | Biến tất cả properties thành readonly | Immutability, constants              |
| `Pick<T, K>`     | Chọn specific properties              | API responses, DTOs                  |
| `Omit<T, K>`     | Loại bỏ specific properties           | Hiding sensitive data                |
| `Record<K, T>`   | Tạo object type với keys và values    | Maps, dictionaries, lookup tables    |
| `Exclude<T, U>`  | Loại bỏ types từ union                | Filtering types                      |
| `Extract<T, U>`  | Trích xuất types từ union             | Type narrowing                       |
| `NonNullable<T>` | Loại bỏ null và undefined             | Safe access, validation              |
| `ReturnType<T>`  | Lấy return type của function          | Type inference, composition          |

**Khi nào dùng cái nào?** Xem bảng so sánh chi tiết ở Phần 4.

---

## Phần 1: Making Properties Optional and Required

### 1.1 Partial<T> - Khi Mọi Thứ Có Thể Optional

`Partial<T>` biến tất cả properties của một type thành optional. Đây là utility type được sử dụng nhiều nhất.

**Cú pháp:**

```typescript
type Partial<T> = {
  [P in keyof T]?: T[P];
};
```

**Ví dụ thực tế:**

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  age: number;
  avatar: string;
}

// Khi update user, chỉ cần một số fields
function updateUser(id: string, updates: Partial<User>) {
  // ✅ Tất cả đều hợp lệ
  // { name: "New Name" }
  // { email: "new@email.com", age: 25 }
  // { avatar: "image.png" }

  return fetch(`/api/users/${id}`, {
    method: "PATCH",
    body: JSON.stringify(updates),
  });
}

// Sử dụng
updateUser("123", { name: "Alice" }); // ✅ OK
updateUser("123", { email: "alice@example.com", age: 30 }); // ✅ OK
updateUser("123", { name: "Bob", unknownField: true }); // ❌ Error
```

**Khi nào dùng Partial<T>:**

- Form updates và PATCH requests
- Configuration objects với default values
- Optional builder patterns
- Incremental object construction

---

### 1.2 Required<T> - Opposite của Partial

`Required<T>` biến tất cả properties thành required, ngay cả khi chúng optional ở type gốc.

**Cú pháp:**

```typescript
type Required<T> = {
  [P in keyof T]-?: T[P];
};
```

**Ví dụ thực tế:**

```typescript
interface DatabaseConfig {
  host?: string;
  port?: number;
  database?: string;
  username?: string;
  password?: string;
}

// Khi connect, cần đảm bảo có tất cả thông tin
function connectDatabase(config: Required<DatabaseConfig>) {
  // Tất cả properties bây giờ đều required
  const connection = createConnection({
    host: config.host, // ✅ Guaranteed to exist
    port: config.port, // ✅ Guaranteed to exist
    database: config.database,
    user: config.username,
    password: config.password,
  });

  return connection;
}

// Type guard để convert từ partial sang required
function validateConfig(
  config: DatabaseConfig,
): config is Required<DatabaseConfig> {
  return !!(
    config.host &&
    config.port &&
    config.database &&
    config.username &&
    config.password
  );
}

// Sử dụng
const config: DatabaseConfig = {
  host: "localhost",
  port: 5432,
  database: "mydb",
};

if (validateConfig(config)) {
  connectDatabase(config); // ✅ OK - validated
} else {
  throw new Error("Invalid configuration");
}
```

**Khi nào dùng Required<T>:**

- Validation logic
- Type guards
- Converting partial configurations thành complete
- Ensuring completeness trước khi processing

---

## Phần 2: Controlling Mutability

### 2.1 Readonly<T> - Immutability Enforcement

`Readonly<T>` biến tất cả properties thành read-only, preventing accidental mutations.

**Cú pháp:**

```typescript
type Readonly<T> = {
  readonly [P in keyof T]: T[P];
};
```

**Ví dụ thực tế:**

```typescript
interface AppConfig {
  apiUrl: string;
  apiKey: string;
  timeout: number;
  retries: number;
}

// Config không được thay đổi sau khi initialize
const config: Readonly<AppConfig> = {
  apiUrl: "https://api.example.com",
  apiKey: "secret-key",
  timeout: 5000,
  retries: 3,
};

// ❌ Error: Cannot assign to 'apiUrl' because it is a read-only property
config.apiUrl = "https://hacker.com";

// ✅ Phải tạo new object
const newConfig: Readonly<AppConfig> = {
  ...config,
  timeout: 10000, // Chỉ thay đổi timeout
};
```

**Use case nâng cao - Readonly Arrays:**

```typescript
interface TodoState {
  items: Readonly<Todo[]>;
  filter: string;
}

function addTodo(state: TodoState, todo: Todo): TodoState {
  // ❌ Error: Cannot use push on readonly array
  // state.items.push(todo);

  // ✅ Immutable update
  return {
    ...state,
    items: [...state.items, todo],
  };
}
```

**Khi nào dùng Readonly<T>:**

- Application config và constants
- Redux/Zustand state objects
- Functional programming patterns
- Preventing accidental mutations
- API response objects không nên modify

---

## Phần 3: Selecting and Excluding Properties

### 3.1 Pick<T, K> - Cherry-Picking Properties

`Pick<T, K>` cho phép bạn select specific properties từ một type.

**Cú pháp:**

```typescript
type Pick<T, K extends keyof T> = {
  [P in K]: T[P];
};
```

**Ví dụ thực tế:**

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  role: "admin" | "user";
  createdAt: Date;
  updatedAt: Date;
}

// Public profile - chỉ show một số fields
type PublicProfile = Pick<User, "id" | "name" | "email">;

// API Response
interface ApiResponse {
  user: PublicProfile;
  token: string;
}

function createPublicProfile(user: User): PublicProfile {
  // ✅ Type-safe selection
  return {
    id: user.id,
    name: user.name,
    email: user.email,
  };
}

// Login credentials
type LoginCredentials = Pick<User, "email" | "password">;

function login(credentials: LoginCredentials) {
  // Chỉ cần email và password
  return authenticate(credentials.email, credentials.password);
}
```

**Khi nào dùng Pick<T, K>:**

- Creating DTOs (Data Transfer Objects)
- API responses không muốn expose tất cả fields
- Form types từ larger models
- Event payloads

---

### 3.2 Omit<T, K> - Excluding Properties

`Omit<T, K>` cho phép bạn loại bỏ specific properties từ một type.

**Cú pháp:**

```typescript
type Omit<T, K extends keyof any> = Pick<T, Exclude<keyof T, K>>;
```

**Ví dụ thực tế:**

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  role: "admin" | "user";
}

// User creation - không cần id (auto-generated)
type CreateUserDto = Omit<User, "id">;

function createUser(userData: CreateUserDto): User {
  return {
    id: generateId(),
    ...userData,
  };
}

// Safe user object - loại bỏ password
type SafeUser = Omit<User, "password">;

function getUserProfile(userId: string): SafeUser {
  const user = database.users.find(userId);

  // Remove password before returning
  const { password, ...safeUser } = user;
  return safeUser;
}

// Multiple omissions
type PublicUser = Omit<User, "password" | "role" | "id">;
```

**Pick vs Omit - Khi nào dùng cái nào?**

| Scenario                      | Dùng   | Lý do                  |
| :---------------------------- | :----- | :--------------------- |
| Muốn ít fields hơn            | `Pick` | Explicit về fields cần |
| Muốn nhiều fields, bỏ vài cái | `Omit` | Ngắn gọn hơn           |
| Hiding sensitive data         | `Omit` | Clear intent           |
| Creating DTOs                 | `Pick` | Explicit contract      |

---

## Phần 4: Creating Object Types

### 4.1 Record<K, T> - Type-Safe Dictionaries

`Record<K, T>` tạo object type với keys type `K` và values type `T`.

**Cú pháp:**

```typescript
type Record<K extends keyof any, T> = {
  [P in K]: T;
};
```

**Ví dụ thực tế:**

```typescript
// HTTP Status codes mapping
type HttpStatusCode = 200 | 201 | 400 | 401 | 403 | 404 | 500;

const statusMessages: Record<HttpStatusCode, string> = {
  200: "OK",
  201: "Created",
  400: "Bad Request",
  401: "Unauthorized",
  403: "Forbidden",
  404: "Not Found",
  500: "Internal Server Error",
};

// Translation dictionary
type Language = "en" | "vi" | "ja";
type TranslationKey = "welcome" | "goodbye" | "hello";

const translations: Record<Language, Record<TranslationKey, string>> = {
  en: {
    welcome: "Welcome",
    goodbye: "Goodbye",
    hello: "Hello",
  },
  vi: {
    welcome: "Chào mừng",
    goodbye: "Tạm biệt",
    hello: "Xin chào",
  },
  ja: {
    welcome: "ようこそ",
    goodbye: "さようなら",
    hello: "こんにちは",
  },
};

// User permissions
type Permission = "read" | "write" | "delete" | "admin";
type Role = "guest" | "user" | "moderator" | "admin";

const rolePermissions: Record<Role, Permission[]> = {
  guest: ["read"],
  user: ["read", "write"],
  moderator: ["read", "write", "delete"],
  admin: ["read", "write", "delete", "admin"],
};

function hasPermission(role: Role, permission: Permission): boolean {
  return rolePermissions[role].includes(permission);
}
```

**Khi nào dùng Record<K, T>:**

- Lookup tables và mappings
- Translation dictionaries
- Configuration objects với known keys
- State machines
- API route handlers

---

## Phần 5: Working with Unions

### 5.1 Exclude<T, U> - Removing Types from Unions

`Exclude<T, U>` loại bỏ types từ union type `T` mà assignable to `U`.

**Cú pháp:**

```typescript
type Exclude<T, U> = T extends U ? never : T;
```

**Ví dụ thực tế:**

```typescript
// Primitive types filtering
type AllTypes = string | number | boolean | null | undefined;
type PrimitiveTypes = Exclude<AllTypes, null | undefined>;
// Result: string | number | boolean

// Event types
type MouseEvent = "click" | "dblclick" | "mousedown" | "mouseup";
type KeyboardEvent = "keydown" | "keyup" | "keypress";
type AllEvents = MouseEvent | KeyboardEvent;

// Chỉ lấy mouse events
type OnlyMouseEvents = Exclude<AllEvents, KeyboardEvent>;
// Result: 'click' | 'dblclick' | 'mousedown' | 'mouseup'

// Function overload filtering
type ApiResponse =
  | { success: true; data: User }
  | { success: false; error: string }
  | { success: false; error: Error };

type SuccessResponse = Exclude<ApiResponse, { success: false }>;
// Result: { success: true; data: User }

// Excluding function types
type MixedTypes = string | number | (() => void) | (() => string);
type NonFunctionTypes = Exclude<MixedTypes, Function>;
// Result: string | number
```

**Khi nào dùng Exclude<T, U>:**

- Filtering union types
- Removing null/undefined từ types
- Type narrowing trong conditional logic
- Creating type variants

---

### 5.2 Extract<T, U> - Extracting Types from Unions

`Extract<T, U>` trích xuất types từ union `T` mà assignable to `U`. Opposite của `Exclude`.

**Cú pháp:**

```typescript
type Extract<T, U> = T extends U ? T : never;
```

**Ví dụ thực tế:**

```typescript
// Extracting specific types
type AllTypes = string | number | boolean | (() => void);
type OnlyFunctions = Extract<AllTypes, Function>;
// Result: () => void

// Status filtering
type Status = "success" | "error" | "warning" | "info" | "loading";
type AlertStatus = Extract<Status, "error" | "warning">;
// Result: 'error' | 'warning'

// API action types
type Action =
  | { type: "SET_USER"; payload: User }
  | { type: "SET_TOKEN"; payload: string }
  | { type: "LOGOUT" }
  | { type: "REFRESH_TOKEN"; payload: string };

// Extract chỉ actions có payload
type ActionsWithPayload = Extract<Action, { payload: any }>;
// Result:
// | { type: 'SET_USER'; payload: User }
// | { type: 'SET_TOKEN'; payload: string }
// | { type: 'REFRESH_TOKEN'; payload: string }

// Practical usage
function handleActionWithPayload(action: ActionsWithPayload) {
  console.log("Processing payload:", action.payload);
  // TypeScript knows action.payload exists
}
```

**Extract vs Exclude:**

| Use Case              | Tool                    | Pattern                |
| :-------------------- | :---------------------- | :--------------------- |
| Remove unwanted types | `Exclude<T, U>`         | "Everything except..." |
| Get specific types    | `Extract<T, U>`         | "Only types that..."   |
| Filter out primitives | `Exclude<T, primitive>` | Type narrowing         |
| Get only primitives   | `Extract<T, primitive>` | Type selection         |

---

## Phần 6: Null Safety

### 6.1 NonNullable<T> - Removing Null and Undefined

`NonNullable<T>` loại bỏ `null` và `undefined` từ type `T`.

**Cú pháp:**

```typescript
type NonNullable<T> = T extends null | undefined ? never : T;
```

**Ví dụ thực tế:**

```typescript
// API response có thể null
interface UserResponse {
  user: User | null;
  token: string | undefined;
  refreshToken?: string;
}

// Ensure non-null values
type SafeUserRespo = {
  [K in keyof UserResponse]: NonNullable<UserResponse[K]>;
};
// Result:
// {
//   user: User;
//   token: string;
//   refreshToken: string;
// }

// Array filtering
function filterNullable<T>(array: (T | null | undefined)[]): NonNullable<T>[] {
  return array.filter((item): item is NonNullable<T> => item != null);
}

const mixedArray = ["hello", null, "world", undefined, "typescript"];
const cleanArray = filterNullable(mixedArray);
// Type: string[]
// Value: ['hello', 'world', 'typescript']

// Optional chaining safety
interface NestedData {
  user?: {
    profile?: {
      avatar?: string;
    };
  };
}

function getAvatarSafely(
  data: NestedData,
): NonNullable<string | undefined> | null {
  const avatar = data.user?.profile?.avatar;
  return avatar ?? null;
}
```

**Khi nào dùng NonNullable<T>:**

- After validation/type guards
- Array filtering functions
- Converting optional to required sau khi check
- API response processing

---

## Phần 7: Function Type Utilities

### 7.1 ReturnType<T> - Inferring Return Types

`ReturnType<T>` lấy return type của function type `T`.

**Cú pháp:**

```typescript
type ReturnType<T extends (...args: any) => any> = T extends (
  ...args: any
) => infer R
  ? R
  : any;
```

**Ví dụ thực tế:**

```typescript
// API function
async function fetchUser(id: string) {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

// Infer return type without duplication
type User = ReturnType<typeof fetchUser>;
// Result: Promise<any> (từ response.json())

// Better với explicit typing
async function fetchUserTyped(id: string): Promise<{
  id: string;
  name: string;
  email: string;
}> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

type UserData = Awaited<ReturnType<typeof fetchUserTyped>>;
// Result: { id: string; name: string; email: string }

// Factory functions
function createStore<T>(initialState: T) {
  let state = initialState;

  return {
    getState: () => state,
    setState: (newState: T) => {
      state = newState;
    },
    subscribe: (listener: (state: T) => void) => {
      // subscription logic
    },
  };
}

type Store<T> = ReturnType<typeof createStore<T>>;
// Now we can use Store<User>, Store<AppState>, etc.

// Callback type inference
const handlers = {
  onClick: (event: MouseEvent) => {
    console.log("Clicked:", event.target);
  },
  onSubmit: (data: FormData) => {
    console.log("Submitted:", data);
    return { success: true };
  },
};

type SubmitResult = ReturnType<typeof handlers.onSubmit>;
// Result: { success: boolean }
```

**Combining với các utilities khác:**

```typescript
// Get return type và make it partial
function createUser(data: CreateUserDto) {
  return {
    id: generateId(),
    ...data,
    createdAt: new Date(),
  };
}

type CreatedUser = ReturnType<typeof createUser>;
type PartialUser = Partial<CreatedUser>;

// Array of return types
type HandlerResults = {
  [K in keyof typeof handlers]: ReturnType<(typeof handlers)[K]>;
};
```

**Khi nào dùng ReturnType<T>:**

- DRY principle - không duplicate type definitions
- Working with third-party libraries
- Generic factory functions
- Composing complex types từ function signatures

---

## Phần 8: Real-World Scenarios

### Scenario 1: Building a Type-Safe API Client

```typescript
// Base API types
interface ApiEndpoint {
  method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  path: string;
  params?: Record<string, string>;
  body?: unknown;
}

// Response wrapper
interface ApiResponse<T> {
  data: T;
  status: number;
  message?: string;
}

// Define endpoints với utility types
type Endpoints = {
  getUser: {
    params: Pick<User, "id">;
    response: ApiResponse<User>;
  };
  updateUser: {
    params: Pick<User, "id">;
    body: Partial<Omit<User, "id" | "createdAt">>;
    response: ApiResponse<User>;
  };
  createUser: {
    body: Required<Omit<User, "id" | "createdAt" | "updatedAt">>;
    response: ApiResponse<User>;
  };
  deleteUser: {
    params: Pick<User, "id">;
    response: ApiResponse<{ success: boolean }>;
  };
};

// Type-safe API client
class ApiClient {
  async request<E extends keyof Endpoints>(
    endpoint: E,
    options: Endpoints[E] extends { params: infer P }
      ? { params: P }
      : Endpoints[E] extends { body: infer B }
        ? { body: B }
        : {},
  ): Promise<Endpoints[E]["response"]> {
    // Implementation
    return {} as any;
  }
}

// Usage - fully type-safe!
const client = new ApiClient();

await client.request("getUser", {
  params: { id: "123" }, // ✅ Type-safe
});

await client.request("updateUser", {
  params: { id: "123" },
  body: { name: "Alice" }, // ✅ Partial update
});

await client.request("createUser", {
  body: {
    // ✅ Must provide all required fields
    name: "Bob",
    email: "bob@example.com",
    password: "secret",
  },
});
```

### Scenario 2: State Management với Type Utilities

```typescript
// Application state
interface AppState {
  user: User | null;
  isAuthenticated: boolean;
  theme: "light" | "dark";
  notifications: Notification[];
  settings: UserSettings;
}

// Actions
type StateAction<K extends keyof AppState> = {
  type: `SET_${Uppercase<K & string>}`;
  payload: AppState[K];
};

// Generate all possible actions
type Actions = {
  [K in keyof AppState]: StateAction<K>;
}[keyof AppState];

// Reducer với type-safe updates
function reducer(
  state: Readonly<AppState>,
  action: Actions,
): Readonly<AppState> {
  // Pattern matching on action type
  if (action.type === "SET_USER") {
    return { ...state, user: action.payload };
  }
  // ... other cases
  return state;
}

// Selectors với ReturnType
const selectors = {
  getUser: (state: AppState) => state.user,
  isLoggedIn: (state: AppState) => state.isAuthenticated,
  getTheme: (state: AppState) => state.theme,
};

type SelectorResults = {
  [K in keyof typeof selectors]: ReturnType<(typeof selectors)[K]>;
};
// Result:
// {
//   getUser: User | null;
//   isLoggedIn: boolean;
//   getTheme: 'light' | 'dark';
// }
```

### Scenario 3: Form Handling với Validation

```typescript
// Form data
interface RegistrationForm {
  username: string;
  email: string;
  password: string;
  confirmPassword: string;
  age: number;
  acceptTerms: boolean;
}

// Validation errors - tất cả fields optional
type ValidationErrors = Partial<Record<keyof RegistrationForm, string>>;

// Form state
interface FormState {
  values: Partial<RegistrationForm>;
  errors: ValidationErrors;
  touched: Partial<Record<keyof RegistrationForm, boolean>>;
  isSubmitting: boolean;
}

// Field validator function type
type FieldValidator<T> = (value: T) => string | undefined;

// Validators cho từng field
const validators: Record<keyof RegistrationForm, FieldValidator<any>> = {
  username: (value: string) =>
    value.length < 3 ? "Username must be at least 3 characters" : undefined,
  email: (value: string) =>
    !/\S+@\S+\.\S+/.test(value) ? "Invalid email format" : undefined,
  password: (value: string) =>
    value.length < 8 ? "Password must be at least 8 characters" : undefined,
  confirmPassword: (value: string) =>
    value !== formState.values.password ? "Passwords must match" : undefined,
  age: (value: number) =>
    value < 18 ? "Must be at least 18 years old" : undefined,
  acceptTerms: (value: boolean) =>
    !value ? "You must accept terms and conditions" : undefined,
};

// Submit handler - requires all fields
async function handleSubmit(
  data: Required<RegistrationForm>,
): Promise<ApiResponse<User>> {
  // All fields guaranteed to exist
  return apiClient.register(data);
}
```

---

## Phần 9: When to Use Which Utility Type

### Decision Matrix

```
┌─────────────────────────────────────────────────────────┐
│ Bạn muốn làm gì?                                        │
└─────────────────────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
    Modify Object                   Work with Unions
         │                               │
    ┌────┴─────┐                    ┌────┴─────┐
    │          │                    │          │
Make Props  Select/                Remove    Extract
Optional    Exclude                Types     Types
   │        Props                    │          │
   │          │                      │          │
Partial<T>  │                   Exclude<T,U>  Extract<T,U>
            │
    ┌───────┴────────┐
    │                │
  Select          Exclude
  Specific        Specific
    │                │
Pick<T,K>        Omit<T,K>
```

### Comparison Table - Quick Reference

| Scenario                  | Tool Chain                              | Example                               |
| :------------------------ | :-------------------------------------- | :------------------------------------ |
| **PATCH request body**    | `Partial<Omit<T, 'id'>>`                | Update user, exclude ID, all optional |
| **Creation DTO**          | `Omit<T, 'id' \| 'createdAt'>`          | New record, exclude auto-generated    |
| **Public API response**   | `Pick<T, K>` hoặc `Omit<T, 'password'>` | Hide sensitive fields                 |
| **Config with defaults**  | `Partial<T>`                            | User overrides default config         |
| **Validated form data**   | `Required<T>`                           | Ensure all fields present             |
| **Immutable state**       | `Readonly<T>`                           | Redux state, constants                |
| **Lookup table**          | `Record<K, T>`                          | Translation, mappings, enums          |
| **Non-null values**       | `NonNullable<T>`                        | After validation                      |
| **Type from function**    | `ReturnType<T>`                         | DRY, infer from factory               |
| **Remove null/undefined** | `Exclude<T, null \| undefined>`         | Union cleanup                         |

### Best Practices Guidelines

**1. Composition over Duplication**

```typescript
// ❌ Bad - Duplicating types
interface CreateUserDto {
  name: string;
  email: string;
  password: string;
}

interface UpdateUserDto {
  name?: string;
  email?: string;
}

// ✅ Good - Using utility types
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

type CreateUserDto = Omit<User, "id" | "createdAt">;
type UpdateUserDto = Partial<Omit<User, "id" | "createdAt" | "password">>;
```

**2. Explicit over Implicit**

```typescript
// ❌ Unclear intent
type UserData = Omit<User, "id">;

// ✅ Clear intent
type CreateUserDto = Omit<User, "id" | "createdAt">;
type UpdateUserPayload = Partial<Omit<User, "id">>;
```

**3. Type Guards với Utility Types**

```typescript
function isRequired<T>(
  value: Partial<T>,
  requiredKeys: (keyof T)[],
): value is Required<T> {
  return requiredKeys.every((key) => value[key] !== undefined);
}
```

---

## Phần 10: Advanced Patterns và Tips

### Pattern 1: Conditional Property Types

```typescript
// Make specific properties optional
type PartialBy<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

interface User {
  id: string;
  name: string;
  email: string;
  age: number;
}

type UserWithOptionalAge = PartialBy<User, "age">;
// Result: { id: string; name: string; email: string; age?: number }
```

### Pattern 2: Deep Readonly

```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};

interface NestedConfig {
  api: {
    baseUrl: string;
    timeout: number;
    retries: {
      max: number;
      delay: number;
    };
  };
}

const config: DeepReadonly<NestedConfig> = {
  api: {
    baseUrl: "https://api.example.com",
    timeout: 5000,
    retries: {
      max: 3,
      delay: 1000,
    },
  },
};

// ❌ All nested properties are readonly
// config.api.retries.max = 5;
```

### Pattern 3: Type-Safe Event Emitters

```typescript
type EventMap = {
  "user:login": { userId: string; timestamp: Date };
  "user:logout": { userId: string };
  "data:update": { dataId: string; changes: Record<string, any> };
};

class TypedEventEmitter {
  on<K extends keyof EventMap>(
    event: K,
    handler: (payload: EventMap[K]) => void,
  ): void {
    // Implementation
  }

  emit<K extends keyof EventMap>(event: K, payload: EventMap[K]): void {
    // Implementation
  }
}

const emitter = new TypedEventEmitter();

// ✅ Type-safe
emitter.on("user:login", (payload) => {
  console.log(payload.userId); // payload type inferred correctly
});

// ❌ Type error
emitter.emit("user:login", { wrongField: "value" });
```

---

## Key Takeaways

1. **Partial<T> và Required<T>** là cặp đôi hoàn hảo cho form handling và validation
2. **Readonly<T>** là must-have cho immutable patterns và configuration
3. **Pick<T, K> vs Omit<T, K>** - chọn based on số lượng properties cần/bỏ
4. **Record<K, T>** là go-to cho lookup tables và type-safe dictionaries
5. **Exclude/Extract** powerful cho union manipulation
6. **NonNullable<T>** safety net sau validation
7. **ReturnType<T>** giúp DRY và type inference từ functions
8. **Composition** - combine utilities để tạo complex types
9. **Type Guards** - luôn validate trước khi use Required types
10. **Naming Conventions** - đặt tên clear để express intent

## Kết Luận

TypeScript Utility Types không chỉ là syntactic sugar - chúng là essential tools giúp bạn viết type-safe code với less duplication và better maintainability. Bằng cách master 10 utilities này, bạn có thể:

- ✅ Eliminate type duplication
- ✅ Build type-safe APIs và data layers
- ✅ Enforce immutability và correctness
- ✅ Create flexible, reusable type definitions
- ✅ Improve developer experience with better autocomplete

**Next Steps:**

1. Practice với các ví dụ trong guide này
2. Refactor existing code để use utility types
3. Explore advanced patterns như conditional types
4. Check official TypeScript documentation cho more utilities
5. Share kiến thức với team của bạn!

**Resources:**

- [TypeScript Handbook - Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)
- [Type Challenges](https://github.com/type-challenges/type-challenges)

---

_Happy typing! 🚀_
