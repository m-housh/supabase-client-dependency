/// Represents parameters for signing users up.
///
public enum SignUpRequest: Equatable {

  /// Signup with an email and a password.
  case email(
    String,
    password: String,
    options: SharedOptions = .init()
  )

  /// Signup with a credentials instance.
  public static func credentials(
    _ credentials: Credentials,
    options: SharedOptions = .init()
  ) -> Self {
    .email(
      credentials.email,
      password: credentials.password,
      options: options
    )
  }

  /// Signup with a phone number and a password.
  case phone(
    String,
    password: String,
    options: SharedOptions = .init()
  )
}
