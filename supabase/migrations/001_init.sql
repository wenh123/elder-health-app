-- ================================================================
-- 長者健康管理系統 — Supabase 初始化 SQL
-- 使用方式：
--   1. 至 Supabase Dashboard > SQL Editor
--   2. 貼上此檔內容，點擊 Run
-- ================================================================

-- ── 啟用 UUID 擴充 ────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ================================================================
-- 1. sites（社區據點）
-- ================================================================
CREATE TABLE IF NOT EXISTS public.sites (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        varchar(100) NOT NULL,
  address     text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 插入測試據點
INSERT INTO public.sites (name, address) VALUES
  ('北區社區據點', '台灣台南市北區'),
  ('東區社區據點', '台灣台南市東區');

-- ================================================================
-- 2. users（使用者，對應 Supabase Auth）
-- ================================================================
CREATE TABLE IF NOT EXISTS public.users (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  site_id     uuid REFERENCES public.sites(id),
  name        varchar(50)  NOT NULL,
  role        varchar(20)  NOT NULL DEFAULT 'caregiver'
                CHECK (role IN ('admin','manager','instructor','caregiver','medical')),
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 當新使用者透過 Auth 註冊時，自動建立 users 記錄
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.users (id, name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'caregiver')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ================================================================
-- 3. elders（長者基本資料）
-- ================================================================
CREATE TABLE IF NOT EXISTS public.elders (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id     uuid NOT NULL REFERENCES public.sites(id),
  name        varchar(50)  NOT NULL,
  gender      char(1)      NOT NULL CHECK (gender IN ('M','F')),
  birth_date  date         NOT NULL,
  education   varchar(30),
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_elders_site_id ON public.elders(site_id);

-- ================================================================
-- 4. assessments（評估記錄）
-- ================================================================
CREATE TABLE IF NOT EXISTS public.assessments (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  elder_id         uuid NOT NULL REFERENCES public.elders(id),
  assessor_id      uuid REFERENCES public.users(id),
  test_type        varchar(4)  NOT NULL CHECK (test_type IN ('pre','post')),
  test_date        date        NOT NULL,

  -- BHT 認知量表
  bht_orientation  smallint CHECK (bht_orientation BETWEEN 0 AND 4),
  bht_registration smallint CHECK (bht_registration BETWEEN 0 AND 5),
  bht_fluency      smallint CHECK (bht_fluency BETWEEN 0 AND 2),
  bht_recall       smallint CHECK (bht_recall BETWEEN 0 AND 5),
  bht_total        smallint GENERATED ALWAYS AS (
    COALESCE(bht_orientation,0) + COALESCE(bht_registration,0) +
    COALESCE(bht_fluency,0)     + COALESCE(bht_recall,0)
  ) STORED,

  -- 體適能
  fitness_chair_stand smallint,
  fitness_bicep_curl  smallint,
  fitness_step_march  smallint,

  -- ICOPE 篩檢
  icope_mobility    boolean DEFAULT false,
  icope_nutrition1  boolean DEFAULT false,
  icope_nutrition2  boolean DEFAULT false,
  icope_vision1     boolean DEFAULT false,
  icope_vision2     boolean DEFAULT false,
  icope_hearing     boolean DEFAULT false,
  icope_depression1 boolean DEFAULT false,
  icope_depression2 boolean DEFAULT false,

  -- 判讀結果（前端計算後存入）
  flag_cognitive  boolean DEFAULT false,
  flag_mobility   boolean DEFAULT false,
  flag_nutrition  boolean DEFAULT false,
  flag_vision     boolean DEFAULT false,
  flag_hearing    boolean DEFAULT false,
  flag_depression boolean DEFAULT false,
  risk_level      varchar(6) CHECK (risk_level IN ('low','medium','high')),

  -- 指導員紀錄
  teaching_adjustments jsonb DEFAULT '{}',
  notes                text,

  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_assessments_elder_id ON public.assessments(elder_id);

-- ================================================================
-- 5. referrals（轉介單）
-- ================================================================
CREATE TABLE IF NOT EXISTS public.referrals (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  elder_id        uuid NOT NULL REFERENCES public.elders(id),
  assessment_id   uuid REFERENCES public.assessments(id),
  referred_by     uuid REFERENCES public.users(id),
  type            varchar(20) NOT NULL
                  CHECK (type IN ('medical','dementia','depression','nutrition','hearing')),
  target          varchar(50),
  status          varchar(15) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','in_progress','completed')),
  notes           text,
  due_date        date,
  resolved_at     timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- ================================================================
-- 6. logs（稽核日誌，由 Trigger 自動寫入）
-- ================================================================
CREATE TABLE IF NOT EXISTS public.logs (
  id          bigserial PRIMARY KEY,
  user_id     uuid REFERENCES public.users(id),
  action      varchar(10) NOT NULL,
  table_name  varchar(30) NOT NULL,
  record_id   uuid,
  old_data    jsonb,
  new_data    jsonb,
  ip_address  inet,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_logs_created_at ON public.logs(created_at);

-- ================================================================
-- Row Level Security（RLS）
-- ================================================================

-- 啟用所有資料表的 RLS
ALTER TABLE public.sites       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.elders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs        ENABLE ROW LEVEL SECURITY;

-- Helper function：取得當前使用者的 role 與 site_id
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.current_user_site_id()
RETURNS uuid LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT site_id FROM public.users WHERE id = auth.uid();
$$;

-- ── sites ────────────────────────────────────────────────────────
-- admin / manager 可查看全部；其他人只能看自己的據點
CREATE POLICY "sites_select" ON public.sites FOR SELECT
  USING (
    public.current_user_role() IN ('admin','manager')
    OR id = public.current_user_site_id()
  );

-- ── users ────────────────────────────────────────────────────────
CREATE POLICY "users_select" ON public.users FOR SELECT
  USING (
    public.current_user_role() = 'admin'
    OR (public.current_user_role() = 'manager' AND site_id = public.current_user_site_id())
    OR id = auth.uid()
  );

CREATE POLICY "users_update_self" ON public.users FOR UPDATE
  USING (id = auth.uid());

-- ── elders ───────────────────────────────────────────────────────
CREATE POLICY "elders_select" ON public.elders FOR SELECT
  USING (
    public.current_user_role() IN ('admin','manager')
    OR site_id = public.current_user_site_id()
  );

CREATE POLICY "elders_insert" ON public.elders FOR INSERT
  WITH CHECK (
    public.current_user_role() IN ('admin','instructor','caregiver')
    AND site_id = public.current_user_site_id()
  );

CREATE POLICY "elders_update" ON public.elders FOR UPDATE
  USING (
    public.current_user_role() IN ('admin','instructor')
    AND site_id = public.current_user_site_id()
  );

-- ── assessments ──────────────────────────────────────────────────
CREATE POLICY "assessments_select" ON public.assessments FOR SELECT
  USING (
    public.current_user_role() IN ('admin','manager')
    OR EXISTS (
      SELECT 1 FROM public.elders e
      WHERE e.id = elder_id AND e.site_id = public.current_user_site_id()
    )
  );

CREATE POLICY "assessments_insert" ON public.assessments FOR INSERT
  WITH CHECK (
    public.current_user_role() IN ('admin','instructor','caregiver')
    AND EXISTS (
      SELECT 1 FROM public.elders e
      WHERE e.id = elder_id AND e.site_id = public.current_user_site_id()
    )
  );

CREATE POLICY "assessments_update" ON public.assessments FOR UPDATE
  USING (
    public.current_user_role() IN ('admin','instructor')
    AND EXISTS (
      SELECT 1 FROM public.elders e
      WHERE e.id = elder_id AND e.site_id = public.current_user_site_id()
    )
  );

-- ── referrals ────────────────────────────────────────────────────
CREATE POLICY "referrals_select" ON public.referrals FOR SELECT
  USING (
    public.current_user_role() IN ('admin','manager')
    OR EXISTS (
      SELECT 1 FROM public.elders e
      WHERE e.id = elder_id AND e.site_id = public.current_user_site_id()
    )
  );

CREATE POLICY "referrals_insert" ON public.referrals FOR INSERT
  WITH CHECK (public.current_user_role() IN ('admin','instructor'));

CREATE POLICY "referrals_update" ON public.referrals FOR UPDATE
  USING (public.current_user_role() IN ('admin','instructor'));

-- ── logs ─────────────────────────────────────────────────────────
CREATE POLICY "logs_select" ON public.logs FOR SELECT
  USING (public.current_user_role() IN ('admin','manager'));
