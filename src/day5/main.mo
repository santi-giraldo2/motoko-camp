import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

import IC "Ic";
import Type "Types";

actor class Verifier() {
  type Principal = Principal.Principal;
  type StudentProfile = Type.StudentProfile;

  stable var entries : [(Principal, StudentProfile)] = [];
  let studentProfileStore : HashMap.HashMap<Principal, StudentProfile> = HashMap.fromIter<Principal, StudentProfile>(entries.vals(), 10, Principal.equal, Principal.hash);

  // STEP 1 - BEGIN

  func isRegistered(p : Principal) : Bool {
    let profile : ?StudentProfile = studentProfileStore.get(p);

    return profile == null;
  };

  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err "You must be Logged In";
    };
    // if (isRegistered(caller)) {
    //   return #err("You are already registered (" # Principal.toText(caller) # ") ");
    // };

    studentProfileStore.put(caller, profile);
    return #ok;
  };

  public query func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    let profile = studentProfileStore.get(p);
    if (profile == null) {
      return #err("not found");
    };
    switch (profile) {
      case (null) { return #err("not found") };
      case (?p) { return #ok(p) };
    };
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err "You must be Logged In";
    };
    // if (not isRegistered(caller)) {
    //   return #err("You are not registered");
    // };

    ignore studentProfileStore.replace(caller, profile);

    return #ok();
  };

  // Implement the deleteMyProfile function which allows a student to delete its student profile. If everything works, and the profile is deleted the function should return a simple unit value wrapped in an Ok result. If the caller doesn't have a student profile the function should return an error message wrapped in an Err result.
  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err "You must be Logged In";
    };
    // if (not isRegistered(caller)) {
    //   return #err("You are not registered");
    // };

    studentProfileStore.delete(caller);

    return #ok();
  };

  system func preupgrade() {
    entries := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade() {
    entries := [];
  };

  // STEP 1 - END

  // STEP 2 - BEGIN
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {
    let calculator = actor (Principal.toText(canisterId)) : actor {
      add : shared (n : Int) -> async Int;
      sub : shared (n : Int) -> async Int;
      reset : shared () -> async Int;
    };

    try {
      var result = await calculator.reset();
      if (result != 0) {
        return #err(#UnexpectedValue("the value is incorrect in resert"));
      };

      result := await calculator.add(1);
      if (result != 1) {
        return #err(#UnexpectedValue("the value is incorrect in add"));
      };

      result := await calculator.add(2);
      if (result != 3) {
        return #err(#UnexpectedValue("the value is incorrect in add"));
      };

      result := await calculator.sub(2);
      if (result != 1) {
        return #err(#UnexpectedValue("the value is incorrect in sub"));
      };

      return #ok;

    } catch (err) {
      return #err(#UnexpectedError("not implemented"));
    };
  };
  // STEP - 2 END

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
    try {
      let controllers = await IC.getCanisterControllers(canisterId);

      var isOwner : ?Principal = Array.find<Principal>(controllers, func prin = prin == p);

      if (isOwner == null) {
        return false;
      };

      return true;
    } catch (e) {
      return false;
    };
  };
  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    try {
      let isApproved = await test(canisterId);

      if (isApproved != #ok) {
        return #err("The current work has no passed the tests");
      };

      let isOwner = await verifyOwnership(canisterId, p);

      if (not isOwner) {
        return #err("The received work owner does not match with the received principal");
      };

      var xProfile : ?StudentProfile = studentProfileStore.get(p);

      switch (xProfile) {
        case null {
          return #err("The received principal does not belongs to a registered student");
        };

        case (?profile) {
          var updatedStudent = {
            name = profile.name;
            graduate = true;
            team = profile.team;
          };

          ignore studentProfileStore.replace(p, updatedStudent);
          return #ok();
        };
      };
    } catch (e) {
      return #err("Cannot verify the project");
    };
  };
  // STEP 4 - END
};
