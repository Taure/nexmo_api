-module(nexmo_api).

%% API
-export([
         send/3
        ]).

%Defines
-define(POST_OPTS,
        #{close => true,
          headers =>
              #{'Content-Type' => <<"application/x-www-form-urlencoded">>}}).

%% ===================================================================
%% API
%% ===================================================================

%%--------------------------------------------------------------------
-spec send(binary(), binary(), zstdlib_uuid:uuid()) -> {ok, Balance :: binary(), Price :: binary()} |
                                                       {error, Reason :: atom()}.
%%--------------------------------------------------------------------
send(Recipient, Message, UUID) ->
    {ok, Credentials} = application:get_env(nexmo_api, credentials),
    Server = proplists:get_value(server, Credentials, <<"rest.nexmo.com/sms/json">>),
    Key = proplists:get_value(key, Credentials),
    Secret = proplists:get_value(secret, Credentials),
    {ok, FromAlias} = application:get_env(nexmo_api, from_alias),

    Queries = cow_qs:qs([{<<"api_key">>, Key},
                         {<<"api_secret">>, Secret},
                         {<<"from">>, FromAlias},
                         {<<"to">>, Recipient},
                         {<<"type">>, <<"text">>},
                         {<<"text">>, Message},
                         {<<"client-ref">>, untag(UUID)}]),
    URL = [<<"https://">>, Server],
    #{body := RespBody} = shttpc:post(URL, Queries, ?POST_OPTS),
    #{<<"messages">> := [RespMessage]} = json:decode(RespBody, [maps]),
    case RespMessage of
        #{<<"status">> := <<"0">>,
          <<"remaining-balance">> := Balance,
          <<"message-price">> := Price} ->
            {ok, Balance, Price};
        #{<<"status">> := Status} ->
            {error, decode(Status)}
    end.

%% ===================================================================
%% Internal functions.
%% ===================================================================

decode(<<"1">>) -> throttled;
decode(<<"2">>) -> missing_params;
decode(<<"3">>) -> invalid_params;
decode(<<"4">>) -> invalid_credentials;
decode(<<"5">>) -> internal_error;
decode(<<"6">>) -> invalid_message;
decode(<<"7">>) -> number_barred;
decode(<<"8">>) -> partner_account_barred;
decode(<<"9">>) -> partner_quota_exceeded;
decode(<<"11">>) -> account_not_enabled_for_REST;
decode(<<"12">>) -> message_too_long;
decode(<<"13">>) -> communication_failed;
decode(<<"14">>) -> invalid_signature;
decode(<<"15">>) -> invalid_sender_address;
decode(<<"16">>) -> invalid_TTL;
decode(<<"19">>) -> facility_not_allowed;
decode(<<"20">>) -> invalid_message_class;
decode(<<"29">>) -> non_white_listed_destination;
decode(<<"101">>) -> response_invalid_account_campaign;
decode(<<"102">>) -> response_msisdn_opted_out_for_campaign;
decode(<<"103">>) -> response_invalid_msisdn;
decode(Code) -> Code.


untag(UUID) when byte_size(UUID) > 40 ->
    [_, ID] = binary:split(UUID, <<$:>>),
    ID;
untag(UUID) ->
    UUID.
