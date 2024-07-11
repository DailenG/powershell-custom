install-module CredentialManager
(get-storedcredential -ascredentialobject).TargetName | Out-String -Stream | Select-String -Pattern "LegacyGeneric:target=Adobe" | foreach { remove-storedcredential -Target $_ }
