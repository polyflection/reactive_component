abstract class User {
  UserKind get kind;
}

enum UserKind { anonymousUser, visitor }

class AnonymousUser implements User {
  AnonymousUser(this.id);
  @override
  final UserKind kind = UserKind.anonymousUser;
  final String id;
}

const visitor = Visitor();

class Visitor implements User {
  const Visitor();
  @override
  final UserKind kind = UserKind.visitor;
}
