-- Adds idempotent reconcile markers directly on daily_logs.
-- Safe to run multiple times.

alter table if exists public.daily_logs
  add column if not exists reconciled_at timestamptz,
  add column if not exists reconciled_transfer_amount numeric(14,2) not null default 0,
  add column if not exists reconciled_xp_awarded integer not null default 0;

create index if not exists idx_daily_logs_user_date_reconciled
  on public.daily_logs (user_id, date, reconciled_at);
