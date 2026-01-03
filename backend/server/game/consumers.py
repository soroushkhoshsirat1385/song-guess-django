from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

from .services import build_room_state, reveal_and_score_round, submit_guess


class RoomConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        user = self.scope.get('user')
        if not user or getattr(user, 'is_authenticated', False) is not True:
            await self.close(code=4401)
            return

        self.room_code = self.scope['url_route']['kwargs']['room_code']
        self.room_group_name = f"room_{self.room_code}"

        allowed = await self._is_member()
        if not allowed:
            await self.close(code=4403)
            return

        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

        await self.send_json({'type': 'connected', 'room_code': self.room_code})

        # Push initial state.
        state = await self._state()
        await self.send_json({'type': 'state', 'state': state})

    async def disconnect(self, close_code):
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive_json(self, content, **kwargs):
        msg_type = content.get('type')

        if msg_type == 'ping':
            await self.send_json({'type': 'pong'})
            return

        if msg_type == 'state':
            state = await self._state()
            await self.send_json({'type': 'state', 'state': state})
            return

        if msg_type == 'guess':
            submission_id = content.get('submission_id')
            guessed_username = content.get('guessed_username')
            if not isinstance(submission_id, int):
                await self.send_json({'type': 'error', 'message': 'submission_id must be an int'})
                return

            res = await self._submit_guess(submission_id=submission_id, guessed_username=guessed_username)
            if res.get('error'):
                await self.send_json({'type': 'error', **res})
                return

            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'room.event',
                    'payload': {'type': 'guess', **res},
                },
            )
            return

        if msg_type == 'reveal':
            res = await self._reveal(round_index=int(content.get('round', 1)))
            if res.get('error'):
                await self.send_json({'type': 'error', **res})
                return

            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'room.event',
                    'payload': {'type': 'reveal', **res},
                },
            )
            return

        await self.send_json({'type': 'error', 'message': 'unknown message type', 'received': content})

    async def room_event(self, event):
        await self.send_json(event.get('payload'))

    @database_sync_to_async
    def _state(self) -> dict:
        return build_room_state(self.room_code)

    @database_sync_to_async
    def _submit_guess(self, submission_id: int, guessed_username):
        return submit_guess(
            room_code=self.room_code,
            guesser=self.scope['user'],
            submission_id=submission_id,
            guessed_username=guessed_username,
        )

    @database_sync_to_async
    def _reveal(self, round_index: int):
        return reveal_and_score_round(self.room_code, round_index=round_index)

    @database_sync_to_async
    def _is_member(self) -> bool:
        user = self.scope['user']
        state = build_room_state(self.room_code)
        if state.get('error'):
            return False
        # members is a list of dicts: {user__id, user__username, ...}
        return any(m.get('user__id') == user.id for m in state.get('members', []))
