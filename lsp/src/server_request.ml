open Import
open Types

type _ t =
  | WorkspaceApplyEdit :
      ApplyWorkspaceEditParams.t
      -> ApplyWorkspaceEditResponse.t t
  | WorkspaceFolders : WorkspaceFolder.t list t
  | WorkspaceConfiguration : ConfigurationParams.t -> Json.t list t
  | ClientRegisterCapability : RegistrationParams.t -> unit t
  | ClientUnregisterCapability : UnregistrationParams.t -> unit t
  | ShowMessageRequest :
      ShowMessageRequestParams.t
      -> MessageActionItem.t option t
  | UnknownRequest : string * Json.t option -> unit t

type packed = E : 'r t -> packed

let method_ (type a) (t : a t) =
  match t with
  | WorkspaceConfiguration _ -> "workspace/configuration"
  | WorkspaceFolders -> "workspace/workspaceFolders"
  | WorkspaceApplyEdit _ -> "workspace/applyEdit"
  | ClientRegisterCapability _ -> "client/registerCapability"
  | ClientUnregisterCapability _ -> "client/unregisterCapability"
  | ShowMessageRequest _ -> "window/showMessageRequest"
  | UnknownRequest _ -> assert false

let params (type a) (t : a t) =
  match t with
  | WorkspaceApplyEdit params -> ApplyWorkspaceEditParams.yojson_of_t params
  | WorkspaceFolders -> `Null
  | WorkspaceConfiguration params -> ConfigurationParams.yojson_of_t params
  | ClientRegisterCapability params -> RegistrationParams.yojson_of_t params
  | ClientUnregisterCapability params -> UnregistrationParams.yojson_of_t params
  | ShowMessageRequest params -> ShowMessageRequestParams.yojson_of_t params
  | UnknownRequest (_, _) -> assert false

let to_jsonrpc_request t ~id =
  let method_ = method_ t in
  let params = params t in
  Jsonrpc.Request.create ~id ~method_ ~params ()

let of_jsonrpc (r : Jsonrpc.Request.t) : (packed, string) Result.t =
  let open Result.O in
  let parse f = Jsonrpc.Request.params r f in
  match r.method_ with
  | "workspace/configuration" ->
    let+ params = parse ConfigurationParams.t_of_yojson in
    E (WorkspaceConfiguration params)
  | "workspace/workspaceFolders" -> Ok (E WorkspaceFolders)
  | "workspace/applyEdit" ->
    let+ params = parse ApplyWorkspaceEditParams.t_of_yojson in
    E (WorkspaceApplyEdit params)
  | "client/registerCapability" ->
    let+ params = parse RegistrationParams.t_of_yojson in
    E (ClientRegisterCapability params)
  | "client/unregisterCapability" ->
    let+ params = parse UnregistrationParams.t_of_yojson in
    E (ClientUnregisterCapability params)
  | "window/showMessageRequest" ->
    let+ params = parse ShowMessageRequestParams.t_of_yojson in
    E (ShowMessageRequest params)
  | m -> Ok (E (UnknownRequest (m, r.params)))

let yojson_of_result _ = assert false
