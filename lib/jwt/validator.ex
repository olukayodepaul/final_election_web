defmodule JWT.Validator do
  @moduledoc """
  Handles token verification and claim extraction using the RS256 Public Key.
  """
  use Joken.Config
  require Logger

  @public_key_path "priv/keys/public.pem"

  # --- Key Loading ---

  defp load_public_key do
    case File.read(@public_key_path) do
      {:ok, binary} ->
        safe_decode_pem(binary)

      {:error, _reason} ->
        {:error, "System Error: Public key file is missing or inaccessible."}
    end
  end

  defp safe_decode_pem(binary) do
    jwk = JOSE.JWK.from_pem(binary)
    {_type, key_map} = JOSE.JWK.to_map(jwk)
    {:ok, key_map}
  rescue
    _e ->
      Logger.error("Public key PEM is malformed or tempered with.")
      {:error, "System Error: The security key is invalid or corrupted."}
  end

  @doc """
  Safely creates a signer. Returns {:ok, signer} or {:error, statement}.
  """
  def get_signer do
    case load_public_key() do
      {:ok, key_map} ->
        try do
          {:ok, Joken.Signer.create("RS256", key_map)}
        rescue
          e ->
            Logger.error("Signer creation failed: #{inspect(e)}")
            {:error, "System Error: Could not initialize security signer."}
        end

      {:error, statement} ->
        {:error, statement}
    end
  end

  # --- Verification Logic ---

  def verify_token(token) do
    case get_signer() do
      {:ok, signer} ->
        case verify_and_validate(token, signer) do
          {:ok, claims} ->
            if token_revoked?(claims["jti"]) do
              {:error, "Access Denied: This token has been revoked."}
            else
              {:ok, claims}
            end

          {:error, reason} ->
            Logger.warning("Token verification failed: #{inspect(reason)}")
            {:error, "Invalid Token: #{inspect(reason)}"}
        end

      {:error, statement} ->
        # Returns the full system error statement to the caller
        {:error, statement}
    end
  end

  def verify_from_header("Bearer " <> token), do: verify_token(token)
  def verify_from_header(token) when is_binary(token), do: verify_token(token)
  def verify_from_header(_), do: {:error, "Invalid Authorization Header format."}

  # --- Inspection Logic ---

  def token_revoked?(_jti), do: false

  def peek_jti(token) do
    case Joken.peek_claims(token) do
      {:ok, %{"jti" => jti}} -> {:ok, jti}
      _ -> {:error, :no_jti}
    end
  end
end
