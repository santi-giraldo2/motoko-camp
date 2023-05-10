import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Type "Types";

actor class Homework() {
  type Homework = Type.Homework;

  let homeworkDiary : Buffer.Buffer<Homework> = Buffer.Buffer<Homework>(0);

  func validateId(id : Nat) : Bool {
    return id >= homeworkDiary.size();
  };

  // Add a new homework task
  public shared func addHomework(homework : Homework) : async Nat {
    homeworkDiary.add(homework);
    let index = homeworkDiary.size();
    if (index > 0) {
      return index - 1;
    };
    return index;
  };

  // Get a specific homework task by id
  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    if (validateId(id)) {
      return #err("id out of range");
    };
    let homework = homeworkDiary.get(id);
    return #ok(homework);
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    if (validateId(id)) {
      return #err("id out of range");
    };
    homeworkDiary.put(id, homework);
    return #ok(());
  };

  // Mark a homework task as completed
  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    if (validateId(id)) {
      return #err("id out of range");
    };

    let homeworkOld = homeworkDiary.get(id);

    let homeworkNew : Type.Homework = {
      title = homeworkOld.title;
      description = homeworkOld.description;
      dueDate = homeworkOld.dueDate;
      completed = true;
    };

    homeworkDiary.put(id, homeworkNew);

    return #ok(());
  };

  // Delete a homework task by id
  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    if (validateId(id)) {
      return #err("id out of range");
    };
    ignore homeworkDiary.remove(id);
    return #ok(());
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray(homeworkDiary);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    var result = Buffer.mapFilter<Homework, Homework>(
      homeworkDiary,
      func(x) {
        if (x.completed) {
          return null;
        };
        return ?x;
      },
    );

    return Buffer.toArray(result);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    var result = Buffer.mapFilter<Homework, Homework>(
      homeworkDiary,
      func(x) {
        if (x.title == searchTerm or x.description == searchTerm) {
          return ?x;
        };
        return null;
      },
    );

    return Buffer.toArray(result);
  };
};
