import { Role } from '@prisma/client';
import { Socket } from 'socket.io';
import { ClientToServerEvents, InterServerEvents, ServerToClientEvents } from './chat-socket-events.type';

export type SocketUser = {
  id: string;
  email: string;
  role: Role;
};

export type ChatSocketData = {
  user: SocketUser;
};

export type AuthenticatedSocket = Socket<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  ChatSocketData
>;
