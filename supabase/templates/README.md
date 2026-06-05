# Supabase Auth Email Templates

These templates are for Supabase Auth notification emails.

## Dashboard Templates

Copy each HTML file into its matching Supabase Dashboard template:

| Supabase template | HTML file | Subject |
| --- | --- | --- |
| Confirm signup | `supabase/templates/confirm_signup.html` | `{{ if eq .Data.language "en" }}Confirm your SAWA account{{ else if eq .Data.language "tr" }}SAWA hesabinizi dogrulayin{{ else }}تأكيد حسابك في سوا{{ end }}` |
| Reset password | `supabase/templates/reset_password.html` | `{{ if eq .Data.language "en" }}Reset your SAWA password{{ else if eq .Data.language "tr" }}SAWA parolanizi sifirlayin{{ else }}إعادة تعيين كلمة مرور سوا{{ end }}` |
| Invite user | `supabase/templates/invite_user.html` | `{{ if eq .Data.language "en" }}You have been invited to SAWA{{ else if eq .Data.language "tr" }}SAWA'ya davet edildiniz{{ else }}تمت دعوتك إلى سوا{{ end }}` |
| Magic link | `supabase/templates/magic_link.html` | `{{ if eq .Data.language "en" }}Log in to SAWA{{ else if eq .Data.language "tr" }}SAWA'ya giris yapin{{ else }}تسجيل الدخول إلى سوا{{ end }}` |
| Password changed | `supabase/templates/password_changed_notification.html` | `{{ if eq .Data.language "en" }}Your SAWA password was changed{{ else if eq .Data.language "tr" }}SAWA parolaniz degistirildi{{ else }}تم تغيير كلمة مرور حسابك في سوا{{ end }}` |

Dashboard path:

```text
Authentication > Emails > Templates
```

## Local Supabase Config

For local Supabase development, add this to `supabase/config.toml` if the file exists:

```toml
[auth.email.template.confirmation]
subject = "{{ if eq .Data.language \"en\" }}Confirm your SAWA account{{ else if eq .Data.language \"tr\" }}SAWA hesabinizi dogrulayin{{ else }}تأكيد حسابك في سوا{{ end }}"
content_path = "./supabase/templates/confirm_signup.html"

[auth.email.template.recovery]
subject = "{{ if eq .Data.language \"en\" }}Reset your SAWA password{{ else if eq .Data.language \"tr\" }}SAWA parolanizi sifirlayin{{ else }}إعادة تعيين كلمة مرور سوا{{ end }}"
content_path = "./supabase/templates/reset_password.html"

[auth.email.template.invite]
subject = "{{ if eq .Data.language \"en\" }}You have been invited to SAWA{{ else if eq .Data.language \"tr\" }}SAWA'ya davet edildiniz{{ else }}تمت دعوتك إلى سوا{{ end }}"
content_path = "./supabase/templates/invite_user.html"

[auth.email.template.magic_link]
subject = "{{ if eq .Data.language \"en\" }}Log in to SAWA{{ else if eq .Data.language \"tr\" }}SAWA'ya giris yapin{{ else }}تسجيل الدخول إلى سوا{{ end }}"
content_path = "./supabase/templates/magic_link.html"

[auth.email.notification.password_changed]
enabled = true
subject = "{{ if eq .Data.language \"en\" }}Your SAWA password was changed{{ else if eq .Data.language \"tr\" }}SAWA parolaniz degistirildi{{ else }}تم تغيير كلمة مرور حسابك في سوا{{ end }}"
content_path = "./supabase/templates/password_changed_notification.html"
```

## Password Changed Notification

Template file:

```text
supabase/templates/password_changed_notification.html
```

Dashboard values:

```text
Template: Password changed
Subject:
{{ if eq .Data.language "en" }}Your SAWA password was changed{{ else if eq .Data.language "tr" }}SAWA parolaniz degistirildi{{ else }}تم تغيير كلمة مرور حسابك في سوا{{ end }}
```

Then enable the security notification if it is not enabled:

```text
Authentication > Security > Security notifications > Password changed
```

The logo is loaded from:

```text
{{ .SiteURL }}/icons/Icon-192.png
```

Make sure the Supabase Auth Site URL points to a public HTTPS domain that serves `web/icons/Icon-192.png`. If SAWA is mobile-only or the Site URL does not serve this file, upload the app icon to a public Supabase Storage bucket or CDN and replace the `img src` in the template.

Language selection uses `{{ .Data.language }}` from `auth.users.user_metadata`. The app updates this metadata during registration, onboarding profile updates, and settings language changes.
