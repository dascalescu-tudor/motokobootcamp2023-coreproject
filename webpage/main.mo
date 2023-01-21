import Http "./http";
import Text "mo:base/Text";

actor {
    public type HttpRequest = Http.HttpRequest;
    public type HttpResponse = Http.HttpResponse;

    public query func http_request(req: HttpRequest) : async HttpResponse {
        return ({
                body = Text.encodeUtf8("Bine v-am gasit la urban groove");
                headers = [];
                status_code = 200;
                streaming_strategy = null;
            });
    };

};