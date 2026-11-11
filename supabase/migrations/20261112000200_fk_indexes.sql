-- =============================================================================
-- Rider Group — Migration 0007 : index des clés étrangères
-- -----------------------------------------------------------------------------
-- Signalé par le Performance Advisor de Supabase (lint 0001
-- unindexed_foreign_keys) : sans index, la suppression d'un profil (ON DELETE
-- SET NULL) parcourt ces tables entièrement.
-- =============================================================================
create index if not exists club_invitations_invited_by_idx
  on public.club_invitations (invited_by);
create index if not exists club_join_requests_decided_by_idx
  on public.club_join_requests (decided_by);
create index if not exists club_verification_requests_requested_by_idx
  on public.club_verification_requests (requested_by);
create index if not exists club_verification_requests_reviewed_by_idx
  on public.club_verification_requests (reviewed_by);
create index if not exists ride_invitations_invited_by_idx
  on public.ride_invitations (invited_by);
create index if not exists ride_participants_decided_by_idx
  on public.ride_participants (decided_by);
