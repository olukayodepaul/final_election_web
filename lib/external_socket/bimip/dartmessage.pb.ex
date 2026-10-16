defmodule Bimip.VideoSource do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "bimip.VideoSource",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :VIDEO_SOURCE_UNSPECIFIED, 0
  field :CAMERA_FRONT, 1
  field :CAMERA_BACK, 2
  field :EXTERNAL_STREAM, 3
end

defmodule Bimip.VideoTrigger do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "bimip.VideoTrigger",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :VIDEO_TRIGGER_UNSPECIFIED, 0
  field :MANUAL_ALERT, 1
  field :AUTOMATIC_INCIDENT, 2
  field :PROXIMITY_ALERT, 3
end

defmodule Bimip.Identity do
  @moduledoc false

  use Protobuf, full_name: "bimip.Identity", protoc_gen_elixir_version: "0.17.0", syntax: :proto3

  field :eid, 1, type: :string

  field :connection_resource_id, 2,
    proto3_optional: true,
    type: :string,
    json_name: "connectionResourceId"

  field :node, 3, proto3_optional: true, type: :string
end

defmodule Bimip.Flow do
  @moduledoc false

  use Protobuf, full_name: "bimip.Flow", protoc_gen_elixir_version: "0.17.0", syntax: :proto3

  field :id, 1, type: :string
  field :from, 2, type: Bimip.Identity
  field :category, 3, type: :string
  field :timestamp, 4, type: :int64
  field :payload, 5, type: :bytes
  field :signature, 6, type: :bytes
  field :ttl, 7, proto3_optional: true, type: :int64
end

defmodule Bimip.LocationStream do
  @moduledoc false

  use Protobuf,
    full_name: "bimip.LocationStream",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :from, 1, type: Bimip.Identity
  field :to, 2, type: Bimip.Identity
  field :timestamp, 3, type: :int64
  field :key_version, 4, type: :string, json_name: "keyVersion"
  field :iv, 5, type: :bytes
  field :tag, 6, type: :bytes
  field :encrypted_blob, 7, type: :bytes, json_name: "encryptedBlob"
end

defmodule Bimip.LocationPayload do
  @moduledoc false

  use Protobuf,
    full_name: "bimip.LocationPayload",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :latitude, 1, type: :double
  field :longitude, 2, type: :double
  field :altitude, 3, proto3_optional: true, type: :double
  field :speed, 4, proto3_optional: true, type: :float
  field :heading, 5, proto3_optional: true, type: :float
end

defmodule Bimip.LocationVideoStream do
  @moduledoc false

  use Protobuf,
    full_name: "bimip.LocationVideoStream",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :from, 1, type: Bimip.Identity
  field :to, 2, type: Bimip.Identity
  field :timestamp, 3, type: :int64
  field :key_version, 4, type: :string, json_name: "keyVersion"
  field :iv, 5, type: :bytes
  field :tag, 6, type: :bytes
  field :encrypted_video_blob, 7, type: :bytes, json_name: "encryptedVideoBlob"
  field :is_emergency, 8, type: :bool, json_name: "isEmergency"
end

defmodule Bimip.VideoPayload do
  @moduledoc false

  use Protobuf,
    full_name: "bimip.VideoPayload",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :transport, 0

  field :latitude, 1, type: :double
  field :longitude, 2, type: :double
  field :speed, 3, type: :double
  field :heading, 4, type: :float
  field :stream_id, 5, type: :string, json_name: "streamId"
  field :source, 6, type: Bimip.VideoSource, enum: true
  field :trigger, 7, type: Bimip.VideoTrigger, enum: true
  field :hls_url, 8, type: :string, json_name: "hlsUrl", oneof: 0
  field :rtsp_url, 9, type: :string, json_name: "rtspUrl", oneof: 0
  field :clip_preview, 10, type: :bytes, json_name: "clipPreview", oneof: 0
end

defmodule Bimip.Token do
  @moduledoc false

  use Protobuf, full_name: "bimip.Token", protoc_gen_elixir_version: "0.17.0", syntax: :proto3

  field :id, 1, type: :string
  field :from, 2, type: Bimip.Identity
  field :token, 3, type: :string
  field :type, 4, type: :int32
  field :timestamp, 5, type: :int64
end

defmodule Bimip.Logout do
  @moduledoc false

  use Protobuf, full_name: "bimip.Logout", protoc_gen_elixir_version: "0.17.0", syntax: :proto3

  field :id, 1, type: :string
  field :from, 2, type: Bimip.Identity
  field :type, 3, type: :int32
  field :timestamp, 4, type: :int64
end

defmodule Bimip.Body do
  @moduledoc false

  use Protobuf, full_name: "bimip.Body", protoc_gen_elixir_version: "0.17.0", syntax: :proto3

  field :route_id, 1, type: :int32, json_name: "routeId"
  field :messages, 2, repeated: true, type: Bimip.Message
  field :flow, 3, repeated: true, type: Bimip.Flow
  field :timestamp, 4, type: :int64
end

defmodule Bimip.Ping do
  @moduledoc false

  use Protobuf, full_name: "bimip.Ping", protoc_gen_elixir_version: "0.17.0", syntax: :proto3

  field :id, 1, type: :string
  field :from, 2, type: Bimip.Identity
  field :type, 3, type: :int32
  field :timestamp, 4, type: :int64
end

defmodule Bimip.OffsetCommit do
  @moduledoc false

  use Protobuf,
    full_name: "bimip.OffsetCommit",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :from, 1, type: Bimip.Identity
  field :type, 2, type: :int32
  field :offset, 3, type: :int64
  field :timestamp, 4, type: :int64
end

defmodule Bimip.ProtocolError do
  @moduledoc false

  use Protobuf,
    full_name: "bimip.ProtocolError",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :route_id, 1, type: :int32, json_name: "routeId"
  field :details, 2, type: :string
  field :timestamp, 3, type: :int64
end

defmodule Bimip.MessageDeliveryReceipts do
  @moduledoc false

  use Protobuf,
    full_name: "bimip.MessageDeliveryReceipts",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :id, 1, type: :string
  field :from, 2, type: Bimip.Identity
  field :to, 3, type: Bimip.Identity
  field :offset, 4, type: :int64
  field :timestamp, 5, type: :int64
end

defmodule Bimip.Message do
  @moduledoc false

  use Protobuf, full_name: "bimip.Message", protoc_gen_elixir_version: "0.17.0", syntax: :proto3

  field :id, 1, type: :string
  field :from, 2, type: Bimip.Identity
  field :to, 3, type: Bimip.Identity
  field :offset, 4, proto3_optional: true, type: :int64
  field :timestamp, 5, type: :int64
  field :payload, 6, type: :bytes
  field :delivery_type, 7, proto3_optional: true, type: :int32, json_name: "deliveryType"
  field :participant_role, 8, type: :int32, json_name: "participantRole"
  field :content_type, 9, type: :int32, json_name: "contentType"
  field :ephemeral_public_key, 10, type: :bytes, json_name: "ephemeralPublicKey"
  field :mac, 11, type: :bytes
  field :message_type, 12, type: :int32, json_name: "messageType"
end

defmodule Bimip.Compose do
  @moduledoc false

  use Protobuf, full_name: "bimip.Compose", protoc_gen_elixir_version: "0.17.0", syntax: :proto3

  field :to, 1, type: Bimip.Identity
  field :from, 2, type: Bimip.Identity
  field :type, 3, type: :int32
  field :timestamp, 4, type: :int64
end

defmodule Bimip.Awareness do
  @moduledoc false

  use Protobuf, full_name: "bimip.Awareness", protoc_gen_elixir_version: "0.17.0", syntax: :proto3

  field :from, 1, type: Bimip.Identity
  field :presence, 2, type: :int32
  field :offset, 3, type: :int64
  field :broadcast, 4, type: :int32
  field :timestamp, 5, type: :int64
end

defmodule Bimip.Subscriber do
  @moduledoc false

  use Protobuf,
    full_name: "bimip.Subscriber",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  field :route_id, 14, type: :int64, json_name: "routeId"
end

defmodule Bimip.MessageScheme do
  @moduledoc false

  use Protobuf,
    full_name: "bimip.MessageScheme",
    protoc_gen_elixir_version: "0.17.0",
    syntax: :proto3

  oneof :payload, 0

  field :route_id, 1, type: :int64, json_name: "routeId"
  field :awareness, 2, type: Bimip.Awareness, oneof: 0
  field :ping, 3, type: Bimip.Ping, oneof: 0
  field :compose, 4, type: Bimip.Compose, oneof: 0
  field :token, 5, type: Bimip.Token, oneof: 0
  field :message, 6, type: Bimip.Message, oneof: 0
  field :offset_commit, 7, type: Bimip.OffsetCommit, json_name: "offsetCommit", oneof: 0
  field :flow, 8, type: Bimip.Flow, oneof: 0
  field :location_stream, 9, type: Bimip.LocationStream, json_name: "locationStream", oneof: 0
  field :body, 10, type: Bimip.Body, oneof: 0
  field :protocol_error, 11, type: Bimip.ProtocolError, json_name: "protocolError", oneof: 0
  field :logout, 12, type: Bimip.Logout, oneof: 0

  field :message_delivery_receipts, 13,
    type: Bimip.MessageDeliveryReceipts,
    json_name: "messageDeliveryReceipts",
    oneof: 0

  field :Subscriber, 14, type: Bimip.Subscriber, oneof: 0

  field :location_video_stream, 15,
    type: Bimip.LocationVideoStream,
    json_name: "locationVideoStream",
    oneof: 0
end
