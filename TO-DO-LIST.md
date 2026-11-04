# Synapse — Chat Application Roadmap

Status: `[x]` shipped · `[ ]` planned · `[~]` partial or needs verification

## Alpha — Foundation and security

- [x] Define the core data model and API contracts
- [x] Add JWT authentication
- [x] Hash passwords with bcrypt
- [x] Enforce server-side authorization for authenticated operations
- [x] Validate and store profile image uploads
- [x] Add session management, token revocation and device logout
- [x] Add refresh-token rotation and expiration policies
- [x] Add rate limiting and basic abuse protection
- [x] Add account deletion and data-retention behavior
- [ ] Add automated backend and client coverage for authentication and authorization
- [x] Establish secure configuration and secret management
- [x] Define message delivery and synchronization semantics

## Beta — Minimum viable chat

- [x] Build profiles with usernames, display names, avatars and bios
- [x] Add direct-message conversations
- [x] Send, receive and persist messages in real time
- [x] Show message history
- [x] Add basic loading, error and empty states
- [x] Add unread notification handling
- [~] Add friends and contacts
- [ ] Add group conversations and invitations
- [ ] Add group membership and authorization
- [ ] Add message editing and deletion
- [ ] Add replies and quoted messages
- [ ] Add typing indicators
- [x] Add message delivery status and read receipts
- [ ] Add online, offline and idle presence
- [ ] Add unread message indicators
- [ ] Add conversation creation and invitation validation
- [x] Add message pagination and incremental history loading
- [x] Add WebSocket reconnection and missed-event recovery
- [x] Add duplicate message prevention through idempotency
- [x] Add authoritative server-side timestamps and message ordering
- [ ] Handle concurrent message updates and deletions
- [ ] Add automated coverage for messaging and group authorization

## Release 1 — Everyday messaging

- [ ] Add emoji reactions
- [ ] Add image, video and file attachments beyond profile images
- [ ] Add attachment previews and upload progress
- [ ] Add drag-and-drop attachments
- [ ] Add upload size and file-type restrictions
- [ ] Add message forwarding
- [ ] Add pinned messages
- [ ] Add link previews
- [ ] Add Markdown message formatting
- [ ] Add reply previews
- [ ] Persist message drafts
- [ ] Add mute and archive controls
- [ ] Add per-conversation notification settings
- [ ] Add global message search
- [ ] Add message search filters (sender, date and attachment type)
- [ ] Add message retry for failed delivery
- [ ] Add message selection and bulk actions
- [ ] Add scheduled messages
- [ ] Add voice messages

## Release 2 — Groups and social features

- [ ] Add group roles, permissions and administrators
- [ ] Add group ownership transfer
- [ ] Add group member management
- [ ] Add temporary and permanent bans
- [ ] Add group invite links with expiration
- [ ] Add threads
- [ ] Add group announcements
- [ ] Add a shared media gallery
- [ ] Add group-specific pinned messages
- [ ] Add group-specific notification preferences
- [ ] Add custom status messages and activity status
- [ ] Add custom emojis and GIF support
- [ ] Add user blocking and reporting flows
- [ ] Add message request controls
- [ ] Add user discovery and friend requests
- [ ] Add profile customization

## Release 3 — Notifications, synchronization and accessibility

- [x] Add a notification center
- [x] Add light and dark theme settings
- [ ] Add push notifications (FCM / APNs)
- [ ] Add notification preferences per device
- [ ] Add keyboard shortcuts
- [ ] Add multi-device synchronization
- [x] Add cross-device session management
- [ ] Add offline message queue
- [ ] Add synchronization checkpoints and missed-event recovery
- [ ] Add conflict resolution for concurrent updates
- [ ] Add privacy controls for presence and read receipts
- [ ] Add compact and comfortable chat layouts
- [ ] Add font scaling
- [ ] Add system theme detection
- [ ] Test keyboard navigation and screen-reader support
- [ ] Add localization and language selection

## Release 4 — Personalization

- [ ] Add custom application themes
- [ ] Add per-chat themes and accent colors
- [ ] Add custom backgrounds
- [ ] Add custom profile banners
- [ ] Add custom notification sounds
- [ ] Add stories or temporary status updates

## Release 5 — Advanced communication and security

- [ ] Add voice and video calls
- [ ] Add voice channels
- [ ] Add screen sharing
- [ ] Evaluate and design optional end-to-end encryption properly
- [ ] Add device-to-device encryption key management
- [ ] Add secure attachment encryption
- [ ] Add encrypted backup and recovery mechanisms
- [ ] Add configurable message retention policies
- [ ] Add user data export
- [ ] Review performance, reliability and scalability
- [ ] Complete security, privacy and accessibility audits

---

## Long-term vision

Synapse aims to become a cross-platform communication platform combining:

- The real-time communication and community features of Discord.
- The social interaction and personalization of Instagram.
- The synchronization and messaging flexibility of modern messaging platforms.

**Core priorities:** Reliability, privacy, performance, extensibility and user experience.
