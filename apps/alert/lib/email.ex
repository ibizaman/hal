defmodule Alert.Email do
  defstruct [:from, :to, :cc, :bcc, :subject, :text, :html]

  def alert(opts, tags, data) do
    Application.get_env(:alert, :services) |> Map.fetch!("mailgun")
    subject = "[" <> Enum.join(tags, ",") <> "] " <> data.summary
    email = %__MODULE__{
      from: Map.fetch!(opts, "from"),
      to: Map.fetch!(opts, "to"),
      subject: subject,
      text: data.message
    }
    Alert.Services.Mailgun.send_email(email)
  end
end
