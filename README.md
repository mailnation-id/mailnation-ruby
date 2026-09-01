# mailnation

Official Ruby SDK for the [Mailnation Email API](https://docs.mailnation.id).

```bash
gem install mailnation
# or
bundle add mailnation
```

```ruby
require "mailnation"

client = Mailnation::Client.new(
  username: ENV["MAILNATION_SMTP_USER"],
  password: ENV["MAILNATION_SMTP_PASSWORD"]
)

res = client.emails.send(
  from: "noreply@your-domain.id",
  to: "user@gmail.com",
  subject: "OTP",
  html: "<p>847291</p>",
  text: "847291"
)
puts res["id"]
```

Repo: https://github.com/riyanathariq/mailnation-ruby

## License

MIT
