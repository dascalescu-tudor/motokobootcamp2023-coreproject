import Array "mo:base/Array";
import Bool "mo:base/Bool";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import List "mo:base/List";
import Webpage "canister:webpage";


actor Dao{

    type Voters = List.List<Principal>;

    type Status = {
		#Pending;
		#Accepted;
		#Rejected;
	};

    type Proposal = {
        id: Nat;
        creator: Principal;
        motion: Text;
        downVotes: Nat;
        upVotes: Nat;
        status : Status;
        voters : Voters;
    };

    stable var stableProposals : [(Nat, Proposal)] = [];

    let proposals = HashMap.fromIter<Nat, Proposal>(stableProposals.vals(), Iter.size(stableProposals.vals()), Nat.equal, Hash.hash);

    system func preupgrade() {
        stableProposals := Iter.toArray(proposals.entries());
    };

    system func postupgrade() {
        
        // for(proposal in stableProposals.vals()){
        //     proposals.put(proposal.0, proposal.1);
        // };
        stableProposals := [];
    };

    stable var proposalCurrentID : Nat = 0;

    stable let unit : Nat = 10_000_000;

    let faucet : actor {  icrc1_balance_of : ({owner:Principal; subaccount:?[Nat8]}) -> async Nat; } = actor("db3eq-6iaaa-aaaah-abz6a-cai");

    func checkBalance(caller : Principal, subaccount : ?[Nat8]) : async Nat {

        return await faucet.icrc1_balance_of({owner = caller; subaccount = subaccount});
    };

    public shared ({caller}) func create_proposal(motion : Text) : async {#ok : Text; #error : Text}{
        if(Principal.isAnonymous(caller))
        {
            return #error("You must login with your identity");
        } else {
            if(motion == "") {
                return #error("Enter a valid proposal");
            } else {
                let newProposal = {
                    id = proposalCurrentID;
                    creator = caller;
                    motion = motion;
                    downVotes = 0;
                    upVotes = 0;
                    status = #Pending;
                    voters = List.nil<Principal>();
                };
                proposals.put(proposalCurrentID, newProposal);
                proposalCurrentID += 1;
                return #ok("New proposal have been created successfully");
            };
        };
    };

    public query func list_all_proposals() : async [(Nat, Proposal)] {
        return Iter.toArray<(Nat, Proposal)>(proposals.entries());
    };

    public query func get_proposal_by_id(id : Nat) : async {#ok : (Nat,Proposal); #error : Text} {
        let wantedProposal : ?Proposal = proposals.get(id);
        switch(wantedProposal){
            case null {
                return #error("Proposal with id: " # Nat.toText(id) # " does not exist");
            };
            case(?found){
                return #ok((id, found));
            };
        };
    };

    public shared ({caller}) func update_proposal_motion(id : Nat, newMotion : Text) : async {#ok : Text; #error : Text}{
         if(Principal.isAnonymous(caller))
        {
            return #error("You must login with your identity");
        } else {
            let wantedProposal : ?Proposal = proposals.get(id);
            switch(wantedProposal){
                case null {
                    return #error("Proposal with id: " # Nat.toText(id) # " does not exist");
                };
                case(?found){
                    if(caller == found.creator){
                        let updatedProposal = {
                            id = found.id;
                            creator = found.creator;
                            motion = newMotion;
                            downVotes = found.downVotes;
                            upVotes = found.upVotes;
                            status = found.status;
                            voters = found.voters;
                        };
                        let result = proposals.replace(id, updatedProposal);
                        switch(result){
                            case null {
                                return #error("Proposal does not exist");
                            };
                            case(?allGood){
                                return #ok("New proposal have been created successfully");
                            };
                        };
                    } else return #error("You are not allowed to change the proposal");
                };
            };
        };
    };

    public shared ({caller}) func vote(id : Nat, answer : Bool) : async {#ok : Text; #error : Text}{
        if(Principal.isAnonymous(caller))
        {
            return #error("You must login with your identity");
        } else {

            let callerDeposit = await checkBalance(caller, null);

            if(callerDeposit <= unit){
                return #error("You have to own at least one mbt in order to vote");
            } else {

                let wantedProposal : ?Proposal = proposals.get(id);

                switch(wantedProposal){
                    case null {
                        return #error("Proposal with id: " # Nat.toText(id) # " does not exist");
                    };
                    case(?found){

                        let findVoter : ?Principal = List.find<Principal>(found.voters, func x = if(Principal.equal(x, caller)){true} else {false}); 

                        switch(findVoter){
                            case(null){
                                let newVotersList = List.push<Principal>(caller, found.voters);
                                var newProposalState : Status = found.status;

                                if(answer == true){

                                    if(found.upVotes + callerDeposit >= unit * 100){
                                        newProposalState := #Accepted;
                                        Webpage.set_proposal_state("Accepted");
                                    };
                                    let updatedProposal = {
                                        id = found.id;
                                        creator = found.creator;
                                        motion = found.motion;
                                        downVotes = found.downVotes;
                                        upVotes = found.upVotes + callerDeposit;
                                        status = newProposalState;
                                        voters = newVotersList;
                                    };
                                    let result = proposals.replace(id, updatedProposal);
                                    switch(result){
                                        case null {
                                            return #error("Proposal does not exist");
                                        };
                                        case(?allGood){
                                            return #ok("Thanks for your vote.");
                                        };
                                    };
                                } else {

                                    if(found.downVotes + callerDeposit >= unit * 100){
                                        newProposalState := #Rejected;
                                        Webpage.set_proposal_state("Rejected");
                                    };
                                    let updatedProposal = {
                                        id = found.id;
                                        creator = found.creator;
                                        motion = found.motion;
                                        downVotes = found.downVotes + callerDeposit;
                                        upVotes = found.upVotes;
                                        status = newProposalState;
                                        voters = newVotersList;
                                    };
                                    let result = proposals.replace(id, updatedProposal);
                                    switch(result){
                                        case null {
                                            return #error("Proposal does not exist");
                                        };
                                        case(?allGood){
                                            return #ok("Thanks for your vote.");
                                        };
                                    };
                                };
                            }; 
                            case(?alreadyVoted){
                                return #error("You are not allowed to vote twice");
                            };
                        };
                    };
                };
            };
        };
    };

    public shared ({caller}) func delete_proposal(id : Nat) : async {#ok : Text; #error : Text}{
        if(Principal.isAnonymous(caller))
            {
                return #error("You must login with your identity");
            } else { 
                let wantedProposal : ?Proposal = proposals.get(id);
            switch(wantedProposal){
                case null {
                    return #error("Proposal with id: " # Nat.toText(id) # " does not exist");
                };
                case(?found){
                    if(caller == found.creator){
                        let result = proposals.remove(id);
                        switch(result){
                            case null {
                                return #error("Proposal does not exist");
                            };
                            case(?allGood){
                                return #ok("Proposal with id: " # Nat.toText(id) # " has been deleted");
                            };
                        };
                    } else return #error("You are not allowed to delete this proposal");
                };
            };
        }
    };
};