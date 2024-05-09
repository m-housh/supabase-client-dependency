# Auth Controller

This article gives a summary of the ``AuthController`` module usage.

## Overview

The authentication controller is used to provide hooks and overrides into authentication
services provided.  It also includes some convenience methods and types.

It gives you the ability to override the current user and session.  It also provides some
validations for credentials if you need them for your application.

The ``SupabaseDependency`` sets up an auth controller automatically, however it can 
also be used / managed independently.

### Usage

You can set up the authentication controller by passing it an `Supabase.AuthClient`.

```swift
var auth = AuthController.live(auth: AuthClient(...))
```

The underlying auth client and methods can be accessed from the controller using `dynamicMemberLookup`
or reaching through the ``AuthController/client`` property, as the auth controller is just meant to give
hooks to override the login and signup flows on the client.

#### Signup a user.

```swift
let user = try await auth.signUp(
  with: .email("test@localhost.com", password: "test-pa$$word!")
)
```

### Login a user.

```swift
let session = try await auth.login(
  credentials: .init(
    email: "test@localhost.com", 
    password: "test-pa$$word!"
  )
)

// Or attempt to login with credentials saved in the user's keychain
// if they've logged in before.
let optionalSession: Session? = try await auth.login()
```

### Access the current user.

```swift
let optionalUser: User? = await auth.currentUser

// Get the current user or throw an error.  Which can be
// useful when / if the user information is required for a component
// in your application.
let user = try await auth.requireCurrentUser()
```

### Overrides

The authentication controller provides override capabilities as follows.

```swift
auth.getCurrentUser = { User(...) }
auth.loginHandler = { _ in Session(...) }
auth.signupHandler = { _ in User(...) }
```

You can also create a mock auth controller for use in previews and tests.  The mock
auth controller will setup an `Supabase.AuthClient` and overrides for you, the auth client
points to a bad url, so any calls to that are not managed by the auth controller will
fail.

```swift
auth = AuthController.mock(
  allowedCredentials: .any,
  user: .mock,
  session: nil
)
```

### Credentials

The credentials type can be used to login a user with conventional email and password.
It also provides the ability to validate credentials (useful prior to creating a user in 
some circumstances.)

```swift
let credentials = Credentials(
  email: "test@localhost.com",
  password: "Test-pa$$word!123"
)

let isValid = credentials.isValid

// Or call validate, which will throw an error that gives hints 
// about what failed.
try credentials.validate()
```

#### Default validations.

- **Email:** The default email validation is one or more characters followed by an
'@' symbol, then one or more charcters followed by '.' and finishing with
one or more characters.
- **Password:** The default password validations is at least 8 characters, at least one
capital letter, at least one lowercase letter, and at least one special charachter '!$%&?._-'
