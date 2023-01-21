import Http "./http";
import Text "mo:base/Text";
import Principal "mo:base/Principal";

actor Webpage{

    public type HttpRequest = Http.HttpRequest;
    public type HttpResponse = Http.HttpResponse;

    var proposalState : Text = "No proposal yet";

    public shared ({caller}) func set_proposal_state(state: Text) : () {
        
        assert caller == Principal.fromText("qoctq-giaaa-aaaaa-aaaea-cai");
        proposalState := state;
    };

    public query func http_request(req: HttpRequest) : async HttpResponse {
        return ({
                body = Text.encodeUtf8("The proposal has been: " # proposalState);
                headers = [];
                status_code = 200;
                streaming_strategy = null;
            });
    };

};