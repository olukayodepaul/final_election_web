defmodule JWT.Issuer do
  @moduledoc """
  Handles token generation and signing using the RS256 Private Key.
  """
  use Joken.Config
  require Logger

  @access_token_expiry  60 * 60 * 24
  @refresh_token_expiry 7 * 24 * 3600
  @private_key_path "priv/keys/private.pem"

  # --- Key Loading ---
  defp load_private_key do
    File.read!(@private_key_path)
    |> JOSE.JWK.from_pem()
    |> JOSE.JWK.to_map()
    |> elem(1)
  end

  def signer do
    Joken.Signer.create("RS256", load_private_key())
  end

  # --- Token Generation ---
  def generate_tokens(%{user_id: user_id, device_id: device_id, eid: eid}) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    access_claims = %{
      "uupid" => user_id,
      "device_id" => device_id,
      "eid" => eid,
      "type" => "access",
      "jti" => generate_jti(),
      "iat" => now,
      "exp" => now + @access_token_expiry
    }

    refresh_claims = %{
      "uupid" => user_id,
      "device_id" => device_id,
      "eid" => eid,
      "type" => "refresh",
      "jti" => generate_jti(),
      "iat" => now,
      "exp" => now + @refresh_token_expiry
    }

    with {:ok, a_token, _} <- generate_and_sign(access_claims, signer()),
         {:ok, r_token, _} <- generate_and_sign(refresh_claims, signer()) do
      Logger.info("Tokens issued for user_id: #{user_id}")
      {:ok, %{
        access: a_token,
        refresh: r_token,
        access_expires_in: @access_token_expiry,
        refresh_expires_in: @refresh_token_expiry
      }}
    end
  end

  def generate_access_token_from_refresh(refresh_token) do
    # Uses the Validator to check the refresh token first
    case JWT.Validator.verify_token(refresh_token) do
      {:ok, %{"type" => "refresh"} = claims} ->
        generate_tokens(%{
          user_id: claims["uupid"],
          device_id: claims["device_id"],
          eid: claims["eid"]
        })
      _ -> {:error, :invalid_refresh_token}
    end
  end

  # --- Helpers ---
  defp generate_jti, do: System.unique_integer([:positive]) |> Integer.to_string()

end
