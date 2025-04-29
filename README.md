# OpenVPN connector with one-time password in SwiftUI

This application runs OpenVPN with pre-calculated one-time-passwords (TOTP).

The user configures a profile with the secret to build the one-time password. The application puts a generated password to the temporary file and lauches OpenVPN using the user certificate.

First, the application needs to build. The required software is Xcode 16.

After checking out the repository to a local directory, the "make release" command should be executed from that directory.

The "release" subdirectory will contain "VPN.app", the standard macOS application bundle, which can be copied to Applications, and started.

Second, the application requires the configuration file with secrets. The configuration file is expected to be named `$HOME/.otpvpn/Account.json`.

The example of "Account.json":

```json
[
    {
        "label": "central",
        "username": "abc",
        "password": "123456<@>",
        "secret": "DRFC7I3I6B2F4CCP"
    }
]
```

This file contains one account named "central". The secret (one-time password secret) is "DRFC7I3I6B2F4CCP" (base32), and the template to generate the actual password is "123456<@>". The password will be a concatenation of "123456" and the actual TOTP, for example, "123456410449". The "<@>" is the placeholder for TOTP.

When the application starts, there is an icon in the notification area with menu to start and stop the connection.
