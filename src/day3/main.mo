// Define un nuevo tipo de registro llamado Message. Un mensaje de tipo Message contiene un campo vote de tipo Int, un campo content de tipo Content y un campo creator de tipo Principal que representa al creador del mensaje.
// Define una variable llamada messageId que sirve como un contador continuamente creciente, manteniendo un registro del total de mensajes publicados.
// Crea una variable llamada wall, que es un HashMap diseñado para almacenar mensajes. En este muro, las claves son de tipo Nat y representan los ID de los mensajes, mientras que los valores son de tipo Message.
// Implementa la función writeMessage, que acepta un contenido c de tipo Content, crea un mensaje a partir del contenido, lo agrega al muro y devuelve el ID del mensaje.
// Implementa la función getMessage, que acepta un messageId de tipo Nat y devuelve el mensaje correspondiente envuelto en un resultado Ok. Si el messageId es inválido, la función debe devolver un mensaje de error envuelto en un resultado Err.
// Implementa la función updateMessage, que acepta un messageId de tipo Nat y un contenido c de tipo Content, y actualiza el contenido del mensaje correspondiente. Esto solo debe funcionar si el llamador es el creator del mensaje. Si el messageId es inválido o el llamador no es el creator, la función debe devolver un mensaje de error envuelto en un resultado Err. Si todo funciona y el mensaje se actualiza, la función debe devolver un valor de unidad simple envuelto en un resultado Ok.
// Implementa la función deleteMessage, que acepta un messageId de tipo Nat, elimina el mensaje correspondiente del wall y devuelve un valor de unidad envuelto en un resultado Ok. Si el messageId es inválido, la función debe devolver un mensaje de error envuelto en un resultado Err.
// Implementa la función upVote, que acepta un messageId de tipo Nat, agrega un voto al mensaje y devuelve un valor de unidad envuelto en un resultado Ok. Si el messageId es inválido, la función debe devolver un mensaje de error envuelto en un resultado Err.
// Implementa la función downVote, que acepta un messageId de tipo Nat, resta un voto al mensaje y devuelve un valor de unidad envuelto en un resultado Ok. Si el messageId es inválido, la función debe devolver un mensaje de error envuelto en un resultado Err.
// Implementa la función de consulta getAllMessages, que devuelve la lista de todos los mensajes.
// Implementa la función de consulta getAllMessagesRanked, que devuelve la lista de todos los mensajes, donde cada mensaje está ordenado por el número de votos. El primer mensaje de la lista debe ser el mensaje con más votos.
// Despliega el muro de estudiantes en Internet Computer.
// (Paso de bonificación) Construye una interfaz de usuario para el muro e integra Internet Identity para autenticar a los usuarios que publiquen en el muro.
import Type "Types";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Buffer "mo:base/Buffer";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  var messageId : Nat = 0;

  let wall = HashMap.HashMap<Nat, Message>(10, Nat.equal, Hash.hash);

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let newMessage : Message = {
      vote = 0;
      content = c;
      creator = caller;
    };

    messageId += 1;

    wall.put(messageId, newMessage);

    return messageId;
  };

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    let message : ?Message = wall.get(messageId);
    switch (message) {
      case (null) { return #err("message not found") };
      case (?m) { return #ok(m) };
    };
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);
    switch (message) {
      case (null) { return #err("message not found") };
      case (?m) {
        if (m.creator == caller) {
          let updatedMessage : Message = {
            vote = m.vote;
            content = c;
            creator = m.creator;
          };
          wall.put(messageId, updatedMessage);
          return #ok(());
        } else {
          return #err("not authorized");
        };
      };
    };
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);
    switch (message) {
      case (null) { return #err("message not found") };
      case (?m) {
        if (m.creator == caller) {
          wall.delete(messageId);
          return #ok(());
        } else {
          return #err("not authorized");
        };
      };
    };
  };

  // Voting
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);
    switch (message) {
      case (null) { return #err("message not found") };
      case (?m) {
        let updatedMessage : Message = {
          vote = m.vote + 1;
          content = m.content;
          creator = m.creator;
        };
        wall.put(messageId, updatedMessage);
        return #ok(());
      };
    };
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);
    switch (message) {
      case (null) { return #err("message not found") };
      case (?m) {
        if (m.vote == 0) {
          return #err("vote cannot be negative");
        };
        let updatedMessage : Message = {
          vote = m.vote - 1;
          content = m.content;
          creator = m.creator;
        };
        wall.put(messageId, updatedMessage);
        return #ok(());
      };
    };
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    let values = wall.vals();

    let messages = Buffer.Buffer<Message>(wall.size());

    for (v in values) {
      messages.add(v);
    };

    return Buffer.toArray(messages);
  };

  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {
    let messages = await getAllMessages();

    let result = Array.sort<Message>(
      messages,
      func(m1 : Message, m2 : Message) {
        if (m1.vote < m2.vote) {
          return #greater;
        } else if (m1.vote < m2.vote) {
          return #less;
        } else {
          return #equal;
        };
      },
    );
    return result;
  };
};
