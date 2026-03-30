# Mastering TypeScript Utility Types: A Complete Guide

TypeScript's utility types are powerful tools that help you transform and manipulate types with ease. Whether you're building a small project or a large-scale application, understanding these utilities can significantly improve your code quality and developer experience. Let's dive into 10 essential utility types that every TypeScript developer should know.

## 1. Partial&lt;T&gt; - Making Properties Optional

### What It Does

`Partial<T>` transforms all properties of type `T` into optional properties. This is incredibly useful when you want to update only specific fields of an object.

### Example

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  age: number;
}

// All properties become optional
type PartialUser = Partial<User>;

function updateUser(id: number, updates: PartialUser) {
  // Can update any subset of properties
  console.log(`Updating user ${id}`, updates);
}

// Valid calls
updateUser(1, { name: "Alice" });
updateUser(2, { email: "bob@example.com", age: 30 });
```

### When to Use

- **Update operations**: When you need to update only certain fields of an entity
- **Form handling**: Partial form submissions where not all fields are required
- **Configuration objects**: When some config options are optional

### Real-World Scenario

In a user profile update feature, you might want to allow users to update their name without forcing them to provide all profile information:

```typescript
class UserService {
  async updateProfile(userId: string, updates: Partial<User>) {
    // Only update the fields provided
    return await database.update({ id: userId }, updates);
  }
}

// User can update just their name
await userService.updateProfile("123", { name: "New Name" });
```

## 2. Required&lt;T&gt; - Making All Properties Required

### What It Does

`Required<T>` is the opposite of `Partial<T>`. It transforms all optional properties into required ones.

### Example

```typescript
interface Config {
  host?: string;
  port?: number;
  timeout?: number;
}

// All properties become required
type RequiredConfig = Required<Config>;

function initializeServer(config: RequiredConfig) {
  // All properties must be provided
  console.log(`Starting server on ${config.host}:${config.port}`);
}

// Error: Missing properties
// initializeServer({ host: "localhost" });

// Correct
initializeServer({
  host: "localhost",
  port: 3000,
  timeout: 5000,
});
```

### When to Use

- **Validation**: Ensuring all optional fields are provided before processing
- **Initialization**: When setting up objects that need all fields defined
- **Type narrowing**: Converting optional types to required for specific operations

### Real-World Scenario

When initializing a database connection, you might accept optional config during setup but require all values before connecting:

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

    // Now guaranteed to have all properties
    console.log(`Connecting to ${fullConfig.host}:${fullConfig.port}`);
  }
}
```

## 3. Readonly&lt;T&gt; - Immutable Properties

### What It Does

`Readonly<T>` makes all properties of type `T` read-only, preventing any modifications after creation.

### Example

```typescript
interface Point {
  x: number;
  y: number;
}

const mutablePoint: Point = { x: 10, y: 20 };
mutablePoint.x = 30; // OK

const immutablePoint: Readonly<Point> = { x: 10, y: 20 };
// immutablePoint.x = 30; // Error: Cannot assign to 'x'
```

### When to Use

- **Immutable data structures**: When you want to prevent accidental mutations
- **Configuration objects**: Ensuring config isn't modified after initialization
- **Functional programming**: Creating pure functions with immutable inputs

### Real-World Scenario

In a React-like component system, you might want to ensure props aren't modified:

```typescript
interface ButtonProps {
  label: string;
  onClick: () => void;
  disabled: boolean;
}

function Button(props: Readonly<ButtonProps>) {
  // props.label = "New Label"; // Error!

  return {
    render: () =>
      `<button disabled="${props.disabled}">${props.label}</button>`,
  };
}

// Props are protected from modification
const btn = Button({
  label: "Click me",
  onClick: () => console.log("Clicked"),
  disabled: false,
});
```

## 4. Pick&lt;T, K&gt; - Selecting Specific Properties

### What It Does

`Pick<T, K>` creates a new type by selecting only specified properties `K` from type `T`.

### Example

```typescript
interface Article {
  id: number;
  title: string;
  content: string;
  author: string;
  publishedAt: Date;
  tags: string[];
}

// Only these fields
type ArticlePreview = Pick<Article, "id" | "title" | "author">;

function showPreview(preview: ArticlePreview) {
  console.log(`${preview.title} by ${preview.author}`);
}

const article: Article = {
  id: 1,
  title: "TypeScript Guide",
  content: "Long content...",
  author: "Alice",
  publishedAt: new Date(),
  tags: ["typescript", "tutorial"],
};

// Only passing needed fields
showPreview({
  id: article.id,
  title: article.title,
  author: article.author,
});
```

### When to Use

- **API responses**: Return only necessary fields to clients
- **Data transfer objects**: Create lightweight versions of complex types
- **Component props**: Extract specific properties for child components

### Real-World Scenario

Building a list view that only needs summary information:

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
    // Fetch only necessary fields from database
    const products = await db.query(`
      SELECT id, name, price, images 
      FROM products
    `);
    return products;
  }
}
```

## 5. Omit&lt;T, K&gt; - Excluding Specific Properties

### What It Does

`Omit<T, K>` creates a new type by removing specified properties `K` from type `T`. It's the opposite of `Pick`.

### Example

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

// Remove sensitive fields
type PublicUser = Omit<User, "password">;

function displayUser(user: PublicUser) {
  console.log(user.email); // OK
  // console.log(user.password); // Error: Property doesn't exist
}
```

### When to Use

- **Security**: Remove sensitive fields before sending data
- **Form handling**: Exclude computed or system fields from user input
- **API responses**: Filter out internal fields

### Real-World Scenario

Creating a safe user object for API responses:

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

    // TypeScript ensures sensitive fields are not included
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

## 6. Record&lt;K, T&gt; - Creating Object Types

### What It Does

`Record<K, T>` creates an object type with keys of type `K` and values of type `T`. It's perfect for creating dictionary-like structures.

### Example

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

### When to Use

- **Dictionaries/Maps**: When you need key-value pair structures
- **Configuration mappings**: Mapping keys to configuration objects
- **Lookup tables**: Creating indexed data structures

### Real-World Scenario

Managing application permissions with role-based access:

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

## 7. Exclude&lt;T, U&gt; - Removing Types from Unions

### What It Does

`Exclude<T, U>` removes types from union `T` that are assignable to `U`.

### Example

```typescript
type AllowedColors = "red" | "blue" | "green" | "yellow" | "purple";
type PrimaryColors = "red" | "blue" | "yellow";

// Remove primary colors
type SecondaryColors = Exclude<AllowedColors, PrimaryColors>;
// Result: 'green' | 'purple'

function mixSecondaryColor(color: SecondaryColors) {
  console.log(`Mixing ${color}`);
}

mixSecondaryColor("green"); // OK
mixSecondaryColor("purple"); // OK
// mixSecondaryColor('red'); // Error
```

### When to Use

- **Type filtering**: Remove specific types from unions
- **Event handling**: Exclude certain event types
- **Validation**: Create restricted type sets

### Real-World Scenario

Creating a type-safe event system with specific event exclusions:

```typescript
type AppEvent =
  | "user:login"
  | "user:logout"
  | "user:update"
  | "admin:login"
  | "admin:action"
  | "system:error"
  | "system:warning";

// Create user-only events (exclude admin and system)
type UserEvent = Exclude<AppEvent, `admin:${string}` | `system:${string}`>;

class UserEventLogger {
  log(event: UserEvent, data: any) {
    // Can only log user events
    console.log(`User event: ${event}`, data);
  }
}

const logger = new UserEventLogger();
logger.log("user:login", { userId: "123" }); // OK
// logger.log('admin:login', {}); // Error
```

## 8. Extract&lt;T, U&gt; - Extracting Types from Unions

### What It Does

`Extract<T, U>` extracts from union `T` only those types that are assignable to `U`. It's the opposite of `Exclude`.

### Example

```typescript
type Response = string | number | boolean | null;

// Extract only primitive types
type PrimitiveResponse = Extract<Response, string | number | boolean>;
// Result: string | number | boolean

type NullableResponse = Extract<Response, null>;
// Result: null
```

### When to Use

- **Type narrowing**: Extract specific types from unions
- **Conditional logic**: Work with subset of union types
- **Filtering**: Select matching types from complex unions

### Real-World Scenario

Handling different response types from an API:

```typescript
type ApiResponse<T> =
  | { status: "success"; data: T }
  | { status: "error"; error: string }
  | { status: "loading" }
  | { status: "idle" };

type SuccessResponse<T> = Extract<ApiResponse<T>, { status: "success" }>;
type ErrorResponse = Extract<ApiResponse<any>, { status: "error" }>;

function handleSuccess<T>(response: SuccessResponse<T>) {
  // TypeScript knows this has 'data' property
  console.log("Success:", response.data);
}

function handleError(response: ErrorResponse) {
  // TypeScript knows this has 'error' property
  console.error("Error:", response.error);
}

const apiResult: ApiResponse<User> = {
  status: "success",
  data: { id: 1, name: "Alice" },
};

if (apiResult.status === "success") {
  handleSuccess(apiResult);
}
```

## 9. NonNullable&lt;T&gt; - Excluding Null and Undefined

### What It Does

`NonNullable<T>` removes `null` and `undefined` from type `T`, ensuring the type is always defined.

### Example

```typescript
type MaybeString = string | null | undefined;

type DefiniteString = NonNullable<MaybeString>;
// Result: string

function processValue(value: NonNullable<MaybeString>) {
  // value is guaranteed to be a string
  console.log(value.toUpperCase());
}

const val1: MaybeString = "hello";
const val2: MaybeString = null;

if (val1 !== null && val1 !== undefined) {
  processValue(val1); // OK
}

// processValue(val2); // Error
```

### When to Use

- **Null safety**: Ensure values are defined before use
- **API responses**: Handle optional data that must be validated
- **Data validation**: Convert nullable types to non-nullable

### Real-World Scenario

Safely handling database query results:

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
      throw new Error("User not found");
    }

    // TypeScript now knows result.data is User, not User | null
    return result.data;
  }

  async getUsers(ids: string[]): Promise<NonNullable<User>[]> {
    const results = await Promise.all(ids.map((id) => db.query("...")));

    // Filter out null values and return only valid users
    return results
      .map((r) => r.data)
      .filter((user): user is NonNullable<User> => user !== null);
  }
}
```

## 10. ReturnType&lt;T&gt; - Getting Function Return Types

### What It Does

`ReturnType<T>` extracts the return type of a function type `T`. This is incredibly useful for inferring types from existing functions.

### Example

```typescript
function createUser(name: string, age: number) {
  return {
    id: Math.random(),
    name,
    age,
    createdAt: new Date(),
  };
}

// Infer the return type
type User = ReturnType<typeof createUser>;
// Result: { id: number; name: string; age: number; createdAt: Date }

function processUser(user: User) {
  console.log(`User ${user.name} is ${user.age} years old`);
}

const newUser = createUser("Alice", 30);
processUser(newUser); // Type-safe!
```

### When to Use

- **Type inference**: Avoid duplicating type definitions
- **Factory functions**: Extract types from function outputs
- **API clients**: Infer response types from methods

### Real-World Scenario

Building type-safe API clients without duplicating types:

```typescript
class ApiClient {
  async fetchUserProfile(userId: string) {
    const response = await fetch(`/api/users/${userId}`);
    return {
      id: userId,
      name: "User Name",
      email: "user@example.com",
      preferences: {
        theme: "dark",
        language: "en",
      },
      stats: {
        posts: 42,
        followers: 150,
      },
    };
  }

  async fetchPosts(userId: string) {
    return [
      { id: "1", title: "Post 1", content: "Content..." },
      { id: "2", title: "Post 2", content: "Content..." },
    ];
  }
}

const api = new ApiClient();

// Infer types from methods
type UserProfile =
  ReturnType<typeof api.fetchUserProfile> extends Promise<infer T> ? T : never;
type Post =
  ReturnType<typeof api.fetchPosts> extends Promise<Array<infer T>> ? T : never;

// Now we can use these types throughout our app
function displayProfile(profile: UserProfile) {
  console.log(`${profile.name} (${profile.email})`);
  console.log(`Theme: ${profile.preferences.theme}`);
}

function displayPosts(posts: Post[]) {
  posts.forEach((post) => console.log(post.title));
}

// Usage
const profile = await api.fetchUserProfile("123");
const posts = await api.fetchPosts("123");

displayProfile(profile); // Type-safe
displayPosts(posts); // Type-safe
```

## Combining Utility Types

The real power comes from combining these utility types:

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  role: "admin" | "user";
  createdAt: Date;
}

// Create a safe, partial update type
type UserUpdate = Partial<Omit<User, "id" | "createdAt">>;

// Read-only public user
type PublicUser = Readonly<Omit<User, "password">>;

// Required registration fields
type UserRegistration = Required<Pick<User, "name" | "email" | "password">>;

function updateUser(id: string, updates: UserUpdate) {
  // Can update any field except id and createdAt
}

function getPublicProfile(userId: string): PublicUser {
  // Returns immutable user without password
  return {} as PublicUser;
}

function registerUser(data: UserRegistration) {
  // All required fields must be provided
}
```

## Conclusion

TypeScript's utility types are essential tools for writing type-safe, maintainable code. They help you:

- **Transform types** without duplicating definitions
- **Enforce constraints** at compile time
- **Improve code safety** by catching errors early
- **Enhance developer experience** with better autocomplete

Start incorporating these utility types into your projects, and you'll find your TypeScript code becoming more robust and easier to maintain. Remember, the key is to use them where they make sense – not every type needs to be wrapped in utilities, but when you need them, they're invaluable.

Happy typing! 🎉
