# Complete Guide to TypeScript Utility Types: 10 Powerful Tools You Need to Know

> **For developers who want to write safer and more flexible TypeScript code**

Have you ever found yourself copy-pasting type definitions, recreating similar types, or rewriting interfaces just to change a few properties? TypeScript provides a powerful set of tools called **Utility Types** that help you transform and manipulate types in an elegant and type-safe manner.

In this comprehensive guide, we'll explore the 10 most important utility types, from basic to advanced, with practical examples and real-world scenarios you'll encounter in your daily development work.

## TL;DR

TypeScript Utility Types are built-in generic types that help transform types flexibly:

| Utility Type     | Purpose                                  | Common Use Cases                     |
| :--------------- | :--------------------------------------- | :----------------------------------- |
| `Partial<T>`     | Makes all properties optional            | Form updates, patches, configuration |
| `Required<T>`    | Makes all properties required            | Validation, type guards              |
| `Readonly<T>`    | Makes all properties readonly            | Immutability, constants              |
| `Pick<T, K>`     | Selects specific properties              | API responses, DTOs                  |
| `Omit<T, K>`     | Excludes specific properties             | Hiding sensitive data                |
| `Record<K, T>`   | Creates object type with keys and values | Maps, dictionaries, lookup tables    |
| `Exclude<T, U>`  | Removes types from union                 | Filtering types                      |
| `Extract<T, U>`  | Extracts types from union                | Type narrowing                       |
| `NonNullable<T>` | Removes null and undefined               | Safe access, validation              |
| `ReturnType<T>`  | Gets return type of function             | Type inference, composition          |

**When to use which?** See detailed comparison table in Part 4.

---

## Part 1: Making Properties Optional and Required

### 1.1 Partial<T> - When Everything Can Be Optional

`Partial<T>` makes all properties of a type optional. This is the most commonly used utility type.

**Syntax:**

```typescript
type Partial<T> = {
  [P in keyof T]?: T[P];
};
```

**Real-world example:**

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  age: number;
  avatar: string;
}

// When updating user, only need some fields
function updateUser(id: string, updates: Partial<User>) {
  // ✅ All valid
  // { name: "New Name" }
  // { email: "new@email.com", age: 25 }
  // { avatar: "image.png" }

  return fetch(`/api/users/${id}`, {
    method: "PATCH",
    body: JSON.stringify(updates),
  });
}

// Usage
updateUser("123", { name: "Alice" }); // ✅ OK
updateUser("123", { email: "alice@example.com", age: 30 }); // ✅ OK
updateUser("123", { name: "Bob", unknownField: true }); // ❌ Error
```

**When to use Partial<T>:**

- Form updates and PATCH requests
- Configuration objects with default values
- Optional builder patterns
- Incremental object construction

---

### 1.2 Required<T> - Opposite of Partial

`Required<T>` makes all properties required, even if they were optional in the original type.

**Syntax:**

```typescript
type Required<T> = {
  [P in keyof T]-?: T[P];
};
```

**Real-world example:**

```typescript
interface DatabaseConfig {
  host?: string;
  port?: number;
  database?: string;
  username?: string;
  password?: string;
}

// When connecting, need to ensure all information is present
function connectDatabase(config: Required<DatabaseConfig>) {
  // All properties are now required
  const connection = createConnection({
    host: config.host, // ✅ Guaranteed to exist
    port: config.port, // ✅ Guaranteed to exist
    database: config.database,
    user: config.username,
    password: config.password,
  });

  return connection;
}

// Type guard to convert from partial to required
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

// Usage
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

**When to use Required<T>:**

- Validation logic
- Type guards
- Converting partial configurations to complete
- Ensuring completeness before processing

---

## Part 2: Controlling Mutability

### 2.1 Readonly<T> - Immutability Enforcement

`Readonly<T>` makes all properties read-only, preventing accidental mutations.

**Syntax:**

```typescript
type Readonly<T> = {
  readonly [P in keyof T]: T[P];
};
```

**Real-world example:**

```typescript
interface AppConfig {
  apiUrl: string;
  apiKey: string;
  timeout: number;
  retries: number;
}

// Config should not change after initialization
const config: Readonly<AppConfig> = {
  apiUrl: "https://api.example.com",
  apiKey: "secret-key",
  timeout: 5000,
  retries: 3,
};

// ❌ Error: Cannot assign to 'apiUrl' because it is a read-only property
config.apiUrl = "https://hacker.com";

// ✅ Must create new object
const newConfig: Readonly<AppConfig> = {
  ...config,
  timeout: 10000, // Only change timeout
};
```

**Advanced use case - Readonly Arrays:**

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

**When to use Readonly<T>:**

- Application config and constants
- Redux/Zustand state objects
- Functional programming patterns
- Preventing accidental mutations
- API response objects that shouldn't be modified

---

## Part 3: Selecting and Excluding Properties

### 3.1 Pick<T, K> - Cherry-Picking Properties

`Pick<T, K>` allows you to select specific properties from a type.

**Syntax:**

```typescript
type Pick<T, K extends keyof T> = {
  [P in K]: T[P];
};
```

**Real-world example:**

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

// Public profile - only show some fields
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
  // Only need email and password
  return authenticate(credentials.email, credentials.password);
}
```

**When to use Pick<T, K>:**

- Creating DTOs (Data Transfer Objects)
- API responses that don't expose all fields
- Form types from larger models
- Event payloads

---

### 3.2 Omit<T, K> - Excluding Properties

`Omit<T, K>` allows you to exclude specific properties from a type.

**Syntax:**

```typescript
type Omit<T, K extends keyof any> = Pick<T, Exclude<keyof T, K>>;
```

**Real-world example:**

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  role: "admin" | "user";
}

// User creation - don't need id (auto-generated)
type CreateUserDto = Omit<User, "id">;

function createUser(userData: CreateUserDto): User {
  return {
    id: generateId(),
    ...userData,
  };
}

// Safe user object - remove password
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

**Pick vs Omit - When to use which?**

| Scenario                     | Use    | Reason                       |
| :--------------------------- | :----- | :--------------------------- |
| Want fewer fields            | `Pick` | Explicit about needed fields |
| Want most fields, remove few | `Omit` | More concise                 |
| Hiding sensitive data        | `Omit` | Clear intent                 |
| Creating DTOs                | `Pick` | Explicit contract            |

---

## Part 4: Creating Object Types

### 4.1 Record<K, T> - Type-Safe Dictionaries

`Record<K, T>` creates an object type with keys of type `K` and values of type `T`.

**Syntax:**

```typescript
type Record<K extends keyof any, T> = {
  [P in K]: T;
};
```

**Real-world example:**

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
type Language = "en" | "es" | "fr" | "de" | "ja";
type TranslationKey = "welcome" | "goodbye" | "hello";

const translations: Record<Language, Record<TranslationKey, string>> = {
  en: {
    welcome: "Welcome",
    goodbye: "Goodbye",
    hello: "Hello",
  },
  es: {
    welcome: "Bienvenido",
    goodbye: "Adiós",
    hello: "Hola",
  },
  fr: {
    welcome: "Bienvenue",
    goodbye: "Au revoir",
    hello: "Bonjour",
  },
  de: {
    welcome: "Willkommen",
    goodbye: "Auf Wiedersehen",
    hello: "Hallo",
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

**When to use Record<K, T>:**

- Lookup tables and mappings
- Translation dictionaries
- Configuration objects with known keys
- State machines
- API route handlers

---

## Part 5: Working with Unions

### 5.1 Exclude<T, U> - Removing Types from Unions

`Exclude<T, U>` removes types from union type `T` that are assignable to `U`.

**Syntax:**

```typescript
type Exclude<T, U> = T extends U ? never : T;
```

**Real-world example:**

```typescript
// Primitive types filtering
type AllTypes = string | number | boolean | null | undefined;
type PrimitiveTypes = Exclude<AllTypes, null | undefined>;
// Result: string | number | boolean

// Event types
type MouseEvent = "click" | "dblclick" | "mousedown" | "mouseup";
type KeyboardEvent = "keydown" | "keyup" | "keypress";
type AllEvents = MouseEvent | KeyboardEvent;

// Only get mouse events
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

**When to use Exclude<T, U>:**

- Filtering union types
- Removing null/undefined from types
- Type narrowing in conditional logic
- Creating type variants

---

### 5.2 Extract<T, U> - Extracting Types from Unions

`Extract<T, U>` extracts types from union `T` that are assignable to `U`. It's the opposite of `Exclude`.

**Syntax:**

```typescript
type Extract<T, U> = T extends U ? T : never;
```

**Real-world example:**

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

// Extract only actions with payload
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

## Part 6: Null Safety

### 6.1 NonNullable<T> - Removing Null and Undefined

`NonNullable<T>` removes `null` and `undefined` from type `T`.

**Syntax:**

```typescript
type NonNullable<T> = T extends null | undefined ? never : T;
```

**Real-world example:**

```typescript
// API response may be null
interface UserResponse {
  user: User | null;
  token: string | undefined;
  refreshToken?: string;
}

// Ensure non-null values
type SafeUserResponse = {
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

**When to use NonNullable<T>:**

- After validation/type guards
- Array filtering functions
- Converting optional to required after check
- API response processing

---

## Part 7: Function Type Utilities

### 7.1 ReturnType<T> - Inferring Return Types

`ReturnType<T>` gets the return type of function type `T`.

**Syntax:**

```typescript
type ReturnType<T extends (...args: any) => any> = T extends (
  ...args: any
) => infer R
  ? R
  : any;
```

**Real-world example:**

```typescript
// API function
async function fetchUser(id: string) {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

// Infer return type without duplication
type User = ReturnType<typeof fetchUser>;
// Result: Promise<any> (from response.json())

// Better with explicit typing
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

**Combining with other utilities:**

```typescript
// Get return type and make it partial
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

**When to use ReturnType<T>:**

- DRY principle - don't duplicate type definitions
- Working with third-party libraries
- Generic factory functions
- Composing complex types from function signatures

---

## Part 8: Real-World Scenarios

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

// Define endpoints with utility types
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

### Scenario 2: State Management with Type Utilities

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

// Reducer with type-safe updates
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

// Selectors with ReturnType
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

### Scenario 3: Form Handling with Validation

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

// Validation errors - all fields optional
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

// Validators for each field
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

## Part 9: When to Use Which Utility Type

### Decision Matrix

```
┌─────────────────────────────────────────────────────────┐
│ What do you want to do?                                 │
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

| Scenario                  | Tool Chain                            | Example                               |
| :------------------------ | :------------------------------------ | :------------------------------------ |
| **PATCH request body**    | `Partial<Omit<T, 'id'>>`              | Update user, exclude ID, all optional |
| **Creation DTO**          | `Omit<T, 'id' \| 'createdAt'>`        | New record, exclude auto-generated    |
| **Public API response**   | `Pick<T, K>` or `Omit<T, 'password'>` | Hide sensitive fields                 |
| **Config with defaults**  | `Partial<T>`                          | User overrides default config         |
| **Validated form data**   | `Required<T>`                         | Ensure all fields present             |
| **Immutable state**       | `Readonly<T>`                         | Redux state, constants                |
| **Lookup table**          | `Record<K, T>`                        | Translation, mappings, enums          |
| **Non-null values**       | `NonNullable<T>`                      | After validation                      |
| **Type from function**    | `ReturnType<T>`                       | DRY, infer from factory               |
| **Remove null/undefined** | `Exclude<T, null \| undefined>`       | Union cleanup                         |

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

**3. Type Guards with Utility Types**

```typescript
function isRequired<T>(
  value: Partial<T>,
  requiredKeys: (keyof T)[],
): value is Required<T> {
  return requiredKeys.every((key) => value[key] !== undefined);
}
```

---

## Part 10: Advanced Patterns and Tips

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

1. **Partial<T> and Required<T>** are the perfect pair for form handling and validation
2. **Readonly<T>** is a must-have for immutable patterns and configuration
3. **Pick<T, K> vs Omit<T, K>** - choose based on the number of properties to include/exclude
4. **Record<K, T>** is the go-to for lookup tables and type-safe dictionaries
5. **Exclude/Extract** are powerful for union manipulation
6. **NonNullable<T>** is a safety net after validation
7. **ReturnType<T>** helps with DRY and type inference from functions
8. **Composition** - combine utilities to create complex types
9. **Type Guards** - always validate before using Required types
10. **Naming Conventions** - use clear names to express intent

## Conclusion

TypeScript Utility Types are not just syntactic sugar - they're essential tools that help you write type-safe code with less duplication and better maintainability. By mastering these 10 utilities, you can:

- ✅ Eliminate type duplication
- ✅ Build type-safe APIs and data layers
- ✅ Enforce immutability and correctness
- ✅ Create flexible, reusable type definitions
- ✅ Improve developer experience with better autocomplete

**Next Steps:**

1. Practice with the examples in this guide
2. Refactor existing code to use utility types
3. Explore advanced patterns like conditional types
4. Check the official TypeScript documentation for more utilities
5. Share this knowledge with your team!

**Resources:**

- [TypeScript Handbook - Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)
- [Type Challenges](https://github.com/type-challenges/type-challenges)
- [TypeScript Playground](https://www.typescriptlang.org/play)

---

_Happy typing! 🚀_
