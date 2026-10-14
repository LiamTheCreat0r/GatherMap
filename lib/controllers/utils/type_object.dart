enum TypeObject {
  EVENT('/event'),
  FRIEND('/friend'),
  CHAT('/chat'),
  CIRCLE('/circle'),
  EVENT_INVITATION('/event_invitation'),
  CIRCLE_MEMBER('/circle_member'),
  MESSAGE('/message'),
  BLOCKED_USER('/blocked_user'),
  USER('/user');


  final String _uri;

  const TypeObject(this._uri);

  String getUri(){
    return _uri;
  }
}