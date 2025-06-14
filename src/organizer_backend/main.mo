import Text "mo:base/Text";
import Map "mo:base/OrderedMap";
import RBTree "mo:base/RBTree";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";

actor {
  var votes: RBTree.RBTree<Text, Nat> = RBTree.RBTree(Text.compare);

  let natMap = Map.Make<Text>(Text.compare);

  public query func getVotes() : async [(Text, Nat)] {
    Iter.toArray(votes.entries())
  };

  public func vote(entry: Text) : async [(Text, Nat)] {
    let current_votes_for_entry = switch ( votes.get(entry) ) {
                                    case null 0;
                                    case (?val) val;
                                  };

    if (current_votes_for_entry == 0) {
      votes.put(entry, 1);
    } else {
      votes.put(entry, current_votes_for_entry + 1);
    };

    Iter.toArray(votes.entries())
  };

  public func resetVote() : async [(Text, Nat)] {
    for (entry in votes.entries()) {
      votes.put(entry.0, 0);
    };

    Iter.toArray(votes.entries())
  };
}
