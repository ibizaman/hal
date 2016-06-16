defmodule Alert.Email do
  defstruct [:from, :to, :cc, :bcc, :subject, :text, :html]
end
