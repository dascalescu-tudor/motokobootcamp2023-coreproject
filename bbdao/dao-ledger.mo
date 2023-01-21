import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Result "mo:base/Result";


actor DaoLedger{

    let accounts : HashMap.HashMap<Principal, Nat> = HashMap.fromIter(Iter.fromArray([]), 5, Principal.equal, Principal.hash);

    public shared ({caller}) func deposit(amount : Nat, account: ?Principal) : async Bool{
        
        let acc = Option.get(account, caller);
        let current_balance = accounts.get(acc);

        switch (current_balance){
            case (?balance){
                accounts.put(acc, balance + amount);
            };
            case (_){
                accounts.put(acc, amount);
            };
        };
        return true;
    };

    public shared ({caller}) func get_balance (account: ?Principal) : async Nat{
        
        let acc = Option.get(account, caller);
        let current_balance = accounts.get(acc);

        switch (current_balance){
            case (?balance){
                return balance;
            };
            case (_){
                return 0;
            };
        };   
    };
};