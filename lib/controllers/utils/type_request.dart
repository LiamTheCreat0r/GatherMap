enum TypeRequest {
  EVENT('event.json','event'),
  FRIENDS('friends.json','friend'),
  CHAT('chat.json','chat'),
  CIRCLE('circle.json','circle'),
  EVENT_INVITATION('event_invitation.json','event_invitation'),
  CIRCLE_MEMBER('circle_member.json','circle_member'),
  MESSAGE('message.json','message'),
  BLOCKED_USER('blocked_user.json','blocked_user'),
  USER('user.json','user');


  final String _path;
  final String _uri;

  const TypeRequest(this._path, this._uri);

  String getPath(){
    return _path;
  }

  String getUri(){
    return _uri;
  }
}