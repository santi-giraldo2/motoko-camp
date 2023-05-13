import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import actorLocal "BootcampLocalActor";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";

actor class MotoCoin() {
  public type Account = Account.Account;

  let ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);
  stable let tokenName = "MotoCoin";
  stable let tokenSymbol = "MOC";

  // Returns the name of the token
  public query func name() : async Text {
    return tokenName;
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return tokenSymbol;
  };

  // Returns the the total number of tokens on all accounts
  public func totalSupply() : async Nat {
    var total : Nat = 0;
    for (n in ledger.vals()) {
      total += n;
    };
    return total;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    let balance = ledger.get(account);
    switch (balance) {
      case (null) { return 0 };
      case (?b) { return b };
    };
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {
    let fromBalance = ledger.get(from);
    switch (fromBalance) {
      case (null) { return #err("from account does not exist") };
      case (?fb) {
        if (fb < amount) {
          return #err("insufficient funds");
        } else {
          let toBalance = ledger.get(to);
          switch (toBalance) {
            case (null) { return #err("to account does not exist") };
            case (?tb) {
              ledger.put(from, fb - amount);
              ledger.put(to, tb + amount);
            };
          };
        };
      };
    };
    return #ok;
  };

  // Airdrop 1000 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
    let canisterStudent = actor ("rww3b-zqaaa-aaaam-abioa-cai") : actor {
      getAllStudentsPrincipal : shared () -> async [Principal];
    };

    try {
      let bootcamp = await canisterStudent.getAllStudentsPrincipal();

      for (student in bootcamp.vals()) {
        let accountStudent : Account = {
          owner = student;
          subaccount = null;
        };
        ledger.put(accountStudent, 100);
      };
      return #ok;
    } catch (err) {
      return #err("failed to airdrop");
    };
  };
};
