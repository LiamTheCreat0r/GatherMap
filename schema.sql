CREATE TABLE public.user (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  birthdate date NOT NULL,
  username text NOT NULL,
  name text NOT NULL,
  surname text NOT NULL,
  city text NOT NULL,
  email text NOT NULL,
  hash_password text NOT NULL,
  profile_picture text,
  private_account boolean NOT NULL DEFAULT false,
  CONSTRAINT user_pkey PRIMARY KEY (id)
);
CREATE TABLE public.event (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  owner_id bigint NOT NULL,
  scheduled_at timestamp with time zone NOT NULL,
  location text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  name text NOT NULL,
  emoji_icon text NOT NULL,
  color text NOT NULL DEFAULT '#F26419'::text,
  is_public boolean NOT NULL,
  CONSTRAINT event_pkey PRIMARY KEY (id),
  CONSTRAINT event_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.user(id)
);
CREATE TABLE public.event_invitation (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  accepted boolean,
  user_id bigint NOT NULL,
  event_id bigint NOT NULL,
  CONSTRAINT event_invitation_pkey PRIMARY KEY (id),
  CONSTRAINT invitation_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user(id),
  CONSTRAINT invitation_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id)
);
CREATE TABLE public.circle (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  owner_id bigint NOT NULL,
  CONSTRAINT circle_pkey PRIMARY KEY (id),
  CONSTRAINT circle_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.user(id)
);
CREATE TABLE public.circle_member (
  id bigint NOT NULL,
  user_id bigint NOT NULL,
  circle_id bigint NOT NULL,
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  user_nickname text,
  CONSTRAINT circle_member_pkey PRIMARY KEY (id),
  CONSTRAINT circle_member_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user(id),
  CONSTRAINT circle_member_circle_id_fkey FOREIGN KEY (circle_id) REFERENCES public.circle(id)
);
CREATE TABLE public.friend (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  friends_since timestamp with time zone NOT NULL DEFAULT now(),
  user_id_1 bigint NOT NULL,
  user_id_2 bigint NOT NULL,
  CONSTRAINT friend_pkey PRIMARY KEY (id),
  CONSTRAINT friend_user_id_1_fkey FOREIGN KEY (user_id_1) REFERENCES public.user(id),
  CONSTRAINT friend_user_id_2_fkey FOREIGN KEY (user_id_2) REFERENCES public.user(id)
);
CREATE TABLE public.chat (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  circle_id bigint,
  event_id bigint,
  friend_id bigint,
  CONSTRAINT chat_pkey PRIMARY KEY (id),
  CONSTRAINT chat_circle_id_fkey FOREIGN KEY (circle_id) REFERENCES public.circle(id),
  CONSTRAINT chat_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(id),
  CONSTRAINT chat_friend_id_fkey FOREIGN KEY (friend_id) REFERENCES public.friend(id)
);
CREATE TABLE public.message (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  image text,
  content text,
  sender_id bigint NOT NULL,
  chat_id bigint,
  CONSTRAINT message_pkey PRIMARY KEY (id),
  CONSTRAINT message_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.user(id),
  CONSTRAINT message_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES public.chat(id)
);
CREATE TABLE public.blocked_user (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  blocked_at timestamp with time zone NOT NULL DEFAULT now(),
  blocked_user bigint UNIQUE,
  user_who_blocked bigint UNIQUE,
  CONSTRAINT blocked_user_pkey PRIMARY KEY (id),
  CONSTRAINT blocked_user_blocked_user_fkey FOREIGN KEY (blocked_user) REFERENCES public.user(id),
  CONSTRAINT blocked_user_user_who_blocked_fkey FOREIGN KEY (user_who_blocked) REFERENCES public.user(id)
);

