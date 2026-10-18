-- ============================================================
-- Electoral Database Schema — INTEGER ID VERSION
-- Hierarchy: State → Local Government → Ward → Polling Unit
-- PostgreSQL
-- ============================================================

-- ============================================================
-- 1. STATES
-- ============================================================
CREATE TABLE states (
    id          BIGSERIAL       PRIMARY KEY,
    name        VARCHAR(100)    NOT NULL,
    code        VARCHAR(10)     NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT states_name_unique UNIQUE (name),
    CONSTRAINT states_code_unique UNIQUE (code),
    CONSTRAINT states_code_format CHECK (code ~ '^[A-Z0-9\-]+$')
);

CREATE INDEX idx_states_code ON states (code);
CREATE INDEX idx_states_name ON states (name);


-- ============================================================
-- 2. LOCAL GOVERNMENTS
-- ============================================================
CREATE TABLE local_governments (
    id          BIGSERIAL       PRIMARY KEY,
    state_id    BIGINT          NOT NULL,
    name        VARCHAR(150)    NOT NULL,
    code        VARCHAR(20)     NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT lga_fk_state
        FOREIGN KEY (state_id) REFERENCES states (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT lga_code_unique_per_state UNIQUE (state_id, code),
    CONSTRAINT lga_name_unique_per_state UNIQUE (state_id, name),
    CONSTRAINT lga_code_format           CHECK (code ~ '^[A-Z0-9\-]+$')
);

CREATE INDEX idx_lga_state_id ON local_governments (state_id);
CREATE INDEX idx_lga_code     ON local_governments (code);
CREATE INDEX idx_lga_name     ON local_governments (name);


-- ============================================================
-- 3. WARDS
-- ============================================================
CREATE TABLE wards (
    id          BIGSERIAL       PRIMARY KEY,
    lga_id      BIGINT          NOT NULL,
    name        VARCHAR(150)    NOT NULL,
    code        VARCHAR(20)     NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT ward_fk_lga
        FOREIGN KEY (lga_id) REFERENCES local_governments (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT ward_code_unique_per_lga UNIQUE (lga_id, code),
    CONSTRAINT ward_name_unique_per_lga UNIQUE (lga_id, name),
    CONSTRAINT ward_code_format         CHECK (code ~ '^[A-Z0-9\-]+$')
);

CREATE INDEX idx_ward_lga_id ON wards (lga_id);
CREATE INDEX idx_ward_code   ON wards (code);
CREATE INDEX idx_ward_name   ON wards (name);


-- ============================================================
-- 4. POLLING UNITS
-- ============================================================
CREATE TABLE polling_units (
    id          BIGSERIAL       PRIMARY KEY,
    ward_id     BIGINT          NOT NULL,
    name        VARCHAR(200)    NOT NULL,
    code        VARCHAR(30)     NOT NULL,
    address     TEXT,
    latitude    NUMERIC(9, 6),
    longitude   NUMERIC(9, 6),
    is_active   BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pu_fk_ward
        FOREIGN KEY (ward_id) REFERENCES wards (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT pu_code_unique_per_ward UNIQUE (ward_id, code),
    CONSTRAINT pu_code_format          CHECK (code ~ '^[A-Z0-9\-]+$'),
    CONSTRAINT pu_latitude_range       CHECK (latitude  IS NULL OR latitude  BETWEEN -90  AND 90),
    CONSTRAINT pu_longitude_range      CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
);

CREATE INDEX idx_pu_ward_id   ON polling_units (ward_id);
CREATE INDEX idx_pu_code      ON polling_units (code);
CREATE INDEX idx_pu_is_active ON polling_units (is_active);
CREATE INDEX idx_pu_location  ON polling_units (latitude, longitude)
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;


-- ============================================================
-- AUTO-UPDATE updated_at TRIGGER FUNCTION (shared by all tables)
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_states_updated_at
    BEFORE UPDATE ON states
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_lga_updated_at
    BEFORE UPDATE ON local_governments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_ward_updated_at
    BEFORE UPDATE ON wards
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_pu_updated_at
    BEFORE UPDATE ON polling_units
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ============================================================
-- VIEW: full hierarchy flat view
-- ============================================================
CREATE OR REPLACE VIEW v_polling_unit_full AS
SELECT
    pu.id              AS polling_unit_id,
    pu.code            AS pu_code,
    pu.name            AS pu_name,
    pu.address,
    pu.latitude,
    pu.longitude,
    pu.is_active,
    w.id               AS ward_id,
    w.code             AS ward_code,
    w.name             AS ward_name,
    l.id               AS lga_id,
    l.code             AS lga_code,
    l.name             AS lga_name,
    s.id               AS state_id,
    s.code             AS state_code,
    s.name             AS state_name
FROM polling_units pu
JOIN wards             w ON w.id = pu.ward_id
JOIN local_governments l ON l.id = w.lga_id
JOIN states            s ON s.id = l.state_id;


-- ============================================================
-- 5. USER ROLES
-- ============================================================
CREATE TABLE user_roles (
    id          BIGSERIAL       PRIMARY KEY,
    name        VARCHAR(50)     NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT role_name_unique UNIQUE (name),
    CONSTRAINT role_name_format CHECK (name ~ '^[a-z_]+$')
);

INSERT INTO user_roles (name, description) VALUES
    ('supervisor',
     'Assigned to one or more wards; sees all field officers in those wards'),
    ('field_officer',
     'Assigned to one supervisor; sees only their assigned supervisor');


-- ============================================================
-- 6. USERS
-- ============================================================
CREATE TABLE users (
    id          BIGSERIAL       PRIMARY KEY,
    role_id     BIGINT          NOT NULL,
    full_name   VARCHAR(200)    NOT NULL,
    username    VARCHAR(100)    NOT NULL,
    password    TEXT            NOT NULL,   -- store bcrypt/argon2 hash ONLY
    eid         VARCHAR(50),               -- external / employee ID
    device_id   VARCHAR(200),              -- mobile device identifier
    is_active   BOOLEAN         NOT NULL DEFAULT TRUE,
    last_login  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT user_fk_role
        FOREIGN KEY (role_id) REFERENCES user_roles (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT user_username_unique UNIQUE (username),
    CONSTRAINT user_eid_unique      UNIQUE (eid),
    CONSTRAINT user_username_format CHECK (username ~ '^[a-zA-Z0-9._\-]+$'),
    CONSTRAINT user_password_not_plain CHECK (LENGTH(password) >= 60)
);

CREATE INDEX idx_users_role_id   ON users (role_id);
CREATE INDEX idx_users_username  ON users (username);
CREATE INDEX idx_users_eid       ON users (eid)       WHERE eid IS NOT NULL;
CREATE INDEX idx_users_device_id ON users (device_id) WHERE device_id IS NOT NULL;
CREATE INDEX idx_users_is_active ON users (is_active);


-- ============================================================
-- 7. SUPERVISOR WARD ASSIGNMENTS
-- ============================================================
CREATE TABLE supervisor_ward_assignments (
    id              BIGSERIAL   PRIMARY KEY,
    supervisor_id   BIGINT      NOT NULL,
    ward_id         BIGINT      NOT NULL,
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by     BIGINT,
    revoked_at      TIMESTAMPTZ,
    revoked_by      BIGINT,

    CONSTRAINT swa_fk_supervisor
        FOREIGN KEY (supervisor_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT swa_fk_ward
        FOREIGN KEY (ward_id) REFERENCES wards (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT swa_fk_assigned_by
        FOREIGN KEY (assigned_by) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT swa_fk_revoked_by
        FOREIGN KEY (revoked_by) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT swa_unique_active
        UNIQUE NULLS NOT DISTINCT (supervisor_id, ward_id, revoked_at)
);

CREATE OR REPLACE FUNCTION check_user_is_supervisor()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM users u
        JOIN user_roles r ON r.id = u.role_id
        WHERE u.id = NEW.supervisor_id
          AND r.name = 'supervisor'
    ) THEN
        RAISE EXCEPTION 'User % is not a supervisor', NEW.supervisor_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_swa_role_check
    BEFORE INSERT OR UPDATE ON supervisor_ward_assignments
    FOR EACH ROW EXECUTE FUNCTION check_user_is_supervisor();

CREATE INDEX idx_swa_supervisor_id ON supervisor_ward_assignments (supervisor_id);
CREATE INDEX idx_swa_ward_id       ON supervisor_ward_assignments (ward_id);
CREATE INDEX idx_swa_active        ON supervisor_ward_assignments (supervisor_id, ward_id)
    WHERE revoked_at IS NULL;


-- ============================================================
-- 8. FIELD OFFICER → SUPERVISOR ASSIGNMENTS
-- ============================================================
CREATE TABLE field_officer_assignments (
    id                BIGSERIAL   PRIMARY KEY,
    field_officer_id  BIGINT      NOT NULL,
    supervisor_id     BIGINT      NOT NULL,
    ward_id           BIGINT      NOT NULL,
    assigned_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_until    TIMESTAMPTZ,
    assigned_by       BIGINT,
    reassigned_by     BIGINT,
    notes             TEXT,

    CONSTRAINT foa_fk_field_officer
        FOREIGN KEY (field_officer_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT foa_fk_supervisor
        FOREIGN KEY (supervisor_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT foa_fk_ward
        FOREIGN KEY (ward_id) REFERENCES wards (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT foa_fk_assigned_by
        FOREIGN KEY (assigned_by) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT foa_fk_reassigned_by
        FOREIGN KEY (reassigned_by) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT foa_unique_active
        UNIQUE NULLS NOT DISTINCT (field_officer_id, assigned_until),

    CONSTRAINT foa_dates_valid
        CHECK (assigned_until IS NULL OR assigned_until > assigned_at)
);

CREATE OR REPLACE FUNCTION check_user_is_field_officer()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM users u
        JOIN user_roles r ON r.id = u.role_id
        WHERE u.id = NEW.field_officer_id
          AND r.name = 'field_officer'
    ) THEN
        RAISE EXCEPTION 'User % is not a field officer', NEW.field_officer_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_foa_role_check
    BEFORE INSERT OR UPDATE ON field_officer_assignments
    FOR EACH ROW EXECUTE FUNCTION check_user_is_field_officer();

CREATE OR REPLACE FUNCTION check_supervisor_covers_ward()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM supervisor_ward_assignments swa
        WHERE swa.supervisor_id = NEW.supervisor_id
          AND swa.ward_id       = NEW.ward_id
          AND swa.revoked_at IS NULL
    ) THEN
        RAISE EXCEPTION
            'Supervisor % has no active assignment to ward %',
            NEW.supervisor_id, NEW.ward_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_foa_ward_coverage_check
    BEFORE INSERT OR UPDATE ON field_officer_assignments
    FOR EACH ROW EXECUTE FUNCTION check_supervisor_covers_ward();

CREATE INDEX idx_foa_field_officer_id ON field_officer_assignments (field_officer_id);
CREATE INDEX idx_foa_supervisor_id    ON field_officer_assignments (supervisor_id);
CREATE INDEX idx_foa_ward_id          ON field_officer_assignments (ward_id);
CREATE INDEX idx_foa_active           ON field_officer_assignments (field_officer_id)
    WHERE assigned_until IS NULL;


-- ============================================================
-- HELPER FUNCTION: reassign a field officer
-- ============================================================
CREATE OR REPLACE FUNCTION reassign_field_officer(
    p_officer_id        BIGINT,
    p_new_supervisor_id BIGINT,
    p_new_ward_id       BIGINT,
    p_done_by           BIGINT,
    p_notes             TEXT DEFAULT NULL
)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
    v_new_id BIGINT;
BEGIN
    UPDATE field_officer_assignments
    SET    assigned_until = NOW(),
           reassigned_by  = p_done_by
    WHERE  field_officer_id = p_officer_id
      AND  assigned_until IS NULL;

    INSERT INTO field_officer_assignments
        (field_officer_id, supervisor_id, ward_id, assigned_by, notes)
    VALUES
        (p_officer_id, p_new_supervisor_id, p_new_ward_id, p_done_by, p_notes)
    RETURNING id INTO v_new_id;

    RETURN v_new_id;
END;
$$;


-- ============================================================
-- TRIGGERS: updated_at on user_roles / users
-- ============================================================
CREATE TRIGGER trg_user_roles_updated_at
    BEFORE UPDATE ON user_roles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ============================================================
-- VIEWS
-- ============================================================
CREATE OR REPLACE VIEW v_supervisor_wards AS
SELECT
    u.id            AS supervisor_id,
    u.full_name     AS supervisor_name,
    u.username      AS supervisor_username,
    u.eid           AS supervisor_eid,
    w.id            AS ward_id,
    w.name          AS ward_name,
    w.code          AS ward_code,
    l.id            AS lga_id,
    l.name          AS lga_name,
    s.id            AS state_id,
    s.name          AS state_name,
    swa.assigned_at
FROM supervisor_ward_assignments swa
JOIN users             u  ON u.id  = swa.supervisor_id
JOIN wards             w  ON w.id  = swa.ward_id
JOIN local_governments l  ON l.id  = w.lga_id
JOIN states            s  ON s.id  = l.state_id
WHERE swa.revoked_at IS NULL
  AND u.is_active = TRUE;

CREATE OR REPLACE VIEW v_supervisor_field_officers AS
SELECT
    swa.supervisor_id,
    sup.full_name       AS supervisor_name,
    u.id                AS field_officer_id,
    u.full_name         AS field_officer_name,
    u.username          AS field_officer_username,
    u.eid               AS field_officer_eid,
    u.device_id,
    u.is_active,
    w.id                AS ward_id,
    w.name              AS ward_name,
    foa.assigned_at
FROM supervisor_ward_assignments swa
JOIN field_officer_assignments foa
     ON  foa.supervisor_id = swa.supervisor_id
     AND foa.ward_id       = swa.ward_id
     AND foa.assigned_until IS NULL
JOIN users sup ON sup.id = swa.supervisor_id
JOIN users u   ON u.id  = foa.field_officer_id
JOIN wards w   ON w.id  = swa.ward_id
WHERE swa.revoked_at IS NULL;

CREATE OR REPLACE VIEW v_field_officer_supervisor AS
SELECT
    foa.field_officer_id,
    fo.full_name        AS field_officer_name,
    sup.id              AS supervisor_id,
    sup.full_name       AS supervisor_name,
    sup.username        AS supervisor_username,
    sup.eid             AS supervisor_eid,
    w.id                AS ward_id,
    w.name              AS ward_name,
    foa.assigned_at
FROM field_officer_assignments foa
JOIN users sup ON sup.id = foa.supervisor_id
JOIN users fo  ON fo.id  = foa.field_officer_id
JOIN wards w   ON w.id   = foa.ward_id
WHERE foa.assigned_until IS NULL;


-- ============================================================
-- 9. FIELD OFFICER REPORTS (insert only — full history)
-- ============================================================
CREATE TABLE field_officer_reports (
    id              BIGSERIAL   PRIMARY KEY,
    user_id         BIGINT      NOT NULL,

    state_id        BIGINT      NOT NULL,
    lga_id          BIGINT      NOT NULL,
    ward_id         BIGINT      NOT NULL,
    polling_unit_id BIGINT,

    submitted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    device_id       VARCHAR(200),

    CONSTRAINT rpt_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT rpt_fk_state
        FOREIGN KEY (state_id) REFERENCES states (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT rpt_fk_lga
        FOREIGN KEY (lga_id) REFERENCES local_governments (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT rpt_fk_ward
        FOREIGN KEY (ward_id) REFERENCES wards (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT rpt_fk_polling_unit
        FOREIGN KEY (polling_unit_id) REFERENCES polling_units (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_rpt_user_id         ON field_officer_reports (user_id);
CREATE INDEX idx_rpt_state_id        ON field_officer_reports (state_id);
CREATE INDEX idx_rpt_lga_id          ON field_officer_reports (lga_id);
CREATE INDEX idx_rpt_ward_id         ON field_officer_reports (ward_id);
CREATE INDEX idx_rpt_polling_unit_id ON field_officer_reports (polling_unit_id);
CREATE INDEX idx_rpt_submitted_at    ON field_officer_reports (submitted_at DESC);
CREATE INDEX idx_rpt_user_time       ON field_officer_reports (user_id, submitted_at DESC);


-- ============================================================
-- 10. FIELD OFFICER CURRENT STATE (one row per officer)
-- ============================================================
CREATE TABLE field_officer_current_state (
    id                  BIGSERIAL   PRIMARY KEY,
    user_id             BIGINT      NOT NULL,

    state_id            BIGINT,
    lga_id              BIGINT,
    ward_id             BIGINT,
    polling_unit_id     BIGINT,

    last_report_id      BIGINT,

    report_count        INTEGER     NOT NULL DEFAULT 0,
    first_report_at     TIMESTAMPTZ,
    last_updated_at     TIMESTAMPTZ,
    device_id           VARCHAR(200),

    acknowledged_by     BIGINT,
    acknowledged_at     TIMESTAMPTZ,

    CONSTRAINT cs_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT cs_fk_state
        FOREIGN KEY (state_id) REFERENCES states (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT cs_fk_lga
        FOREIGN KEY (lga_id) REFERENCES local_governments (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT cs_fk_ward
        FOREIGN KEY (ward_id) REFERENCES wards (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT cs_fk_polling_unit
        FOREIGN KEY (polling_unit_id) REFERENCES polling_units (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT cs_fk_last_report
        FOREIGN KEY (last_report_id) REFERENCES field_officer_reports (id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT cs_fk_acknowledged_by
        FOREIGN KEY (acknowledged_by) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT cs_user_unique UNIQUE (user_id),
    CONSTRAINT cs_report_count_positive CHECK (report_count >= 0)
);

CREATE INDEX idx_cs_user_id         ON field_officer_current_state (user_id);
CREATE INDEX idx_cs_state_id        ON field_officer_current_state (state_id);
CREATE INDEX idx_cs_lga_id          ON field_officer_current_state (lga_id);
CREATE INDEX idx_cs_ward_id         ON field_officer_current_state (ward_id);
CREATE INDEX idx_cs_polling_unit_id ON field_officer_current_state (polling_unit_id);
CREATE INDEX idx_cs_last_updated_at ON field_officer_current_state (last_updated_at DESC);


-- ============================================================
-- TRIGGER: auto-create current_state row on new field officer
-- ============================================================
CREATE OR REPLACE FUNCTION create_field_officer_state()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM user_roles
        WHERE id = NEW.role_id AND name = 'field_officer'
    ) THEN
        INSERT INTO field_officer_current_state (user_id)
        VALUES (NEW.id)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_create_field_officer_state
    AFTER INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION create_field_officer_state();


-- ============================================================
-- FUNCTION: submit_field_officer_report()
-- ============================================================
CREATE OR REPLACE FUNCTION submit_field_officer_report(
    p_user_id           BIGINT,
    p_state_id          BIGINT,
    p_lga_id            BIGINT,
    p_ward_id           BIGINT,
    p_polling_unit_id   BIGINT  DEFAULT NULL,
    p_device_id         VARCHAR DEFAULT NULL
)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
    v_report_id BIGINT;
BEGIN
    INSERT INTO field_officer_reports (
        user_id, state_id, lga_id, ward_id, polling_unit_id, device_id
    )
    VALUES (
        p_user_id, p_state_id, p_lga_id, p_ward_id, p_polling_unit_id, p_device_id
    )
    RETURNING id INTO v_report_id;

    UPDATE field_officer_current_state SET
        state_id            = p_state_id,
        lga_id              = p_lga_id,
        ward_id             = p_ward_id,
        polling_unit_id     = p_polling_unit_id,
        last_report_id      = v_report_id,
        report_count        = report_count + 1,
        first_report_at     = COALESCE(first_report_at, NOW()),
        last_updated_at     = NOW(),
        device_id           = p_device_id,
        acknowledged_by     = NULL,
        acknowledged_at     = NULL
    WHERE user_id = p_user_id;

    RETURN v_report_id;
END;
$$;


-- ============================================================
-- VIEW: v_supervisor_current_states
-- ============================================================
CREATE OR REPLACE VIEW v_supervisor_current_states AS
SELECT
    swa.supervisor_id,
    sup.full_name           AS supervisor_name,

    cs.user_id              AS field_officer_id,
    u.full_name             AS field_officer_name,
    u.username,
    u.eid,

    s.name                  AS state_name,
    l.name                  AS lga_name,
    w.name                  AS ward_name,
    pu.name                 AS polling_unit_name,

    cs.report_count,
    cs.first_report_at,
    cs.last_updated_at,
    cs.device_id,
    cs.last_report_id,

    cs.acknowledged_by,
    cs.acknowledged_at,
    CASE
        WHEN cs.acknowledged_at IS NULL AND cs.report_count > 0
        THEN TRUE ELSE FALSE
    END                     AS has_unread_update

FROM field_officer_current_state cs
JOIN users u    ON u.id  = cs.user_id
JOIN field_officer_assignments foa
     ON foa.field_officer_id = cs.user_id
     AND foa.assigned_until IS NULL
JOIN supervisor_ward_assignments swa
     ON swa.supervisor_id = foa.supervisor_id
     AND swa.ward_id      = foa.ward_id
     AND swa.revoked_at IS NULL
JOIN users sup  ON sup.id = swa.supervisor_id
LEFT JOIN states            s  ON s.id  = cs.state_id
LEFT JOIN local_governments l  ON l.id  = cs.lga_id
LEFT JOIN wards             w  ON w.id  = cs.ward_id
LEFT JOIN polling_units     pu ON pu.id = cs.polling_unit_id;


-- ============================================================
-- 11. ELECTION SCHEDULE
-- ============================================================
CREATE TABLE election_schedule (
    id              BIGSERIAL    PRIMARY KEY,
    election_name   VARCHAR(200) NOT NULL,
    start_date      TIMESTAMPTZ  NOT NULL,
    end_date        TIMESTAMPTZ  NOT NULL,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT es_end_after_start  CHECK (end_date > start_date),
    CONSTRAINT es_one_active       UNIQUE (is_active)
);

CREATE OR REPLACE FUNCTION enforce_single_election_row()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT COUNT(*) FROM election_schedule) >= 1 THEN
        RAISE EXCEPTION 'election_schedule is a system table — only one row is allowed. Use UPDATE to change the schedule.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_single_election_row
    BEFORE INSERT ON election_schedule
    FOR EACH ROW EXECUTE FUNCTION enforce_single_election_row();

CREATE TRIGGER trg_election_schedule_updated_at
    BEFORE UPDATE ON election_schedule
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE FUNCTION is_election_open()
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM election_schedule
        WHERE is_active = TRUE
          AND NOW() BETWEEN start_date AND end_date
    );
$$;

INSERT INTO election_schedule (election_name, start_date, end_date) VALUES (
    'General Election',
    '2026-05-24 00:00:00+01',
    '2026-05-26 23:59:59+01'
);


-- ============================================================
-- 12. ELECTIONS (master catalogue)
-- ============================================================
CREATE TABLE elections (
    id          BIGSERIAL       PRIMARY KEY,
    map_id      SMALLINT        NOT NULL,
    name        VARCHAR(200)    NOT NULL,
    is_active   BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT elec_map_id_range    CHECK (map_id IN (1, 2)),
    CONSTRAINT elec_name_unique_per_map UNIQUE (map_id, name),
    CONSTRAINT elec_name_not_empty  CHECK (LENGTH(TRIM(name)) > 0)
);

CREATE INDEX idx_elec_map_id    ON elections (map_id);
CREATE INDEX idx_elec_is_active ON elections (is_active);

CREATE TRIGGER trg_elections_updated_at
    BEFORE UPDATE ON elections
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO elections (map_id, name) VALUES
    (1, 'Presidential'),
    (1, 'Governorship'),
    (2, 'Senate'),
    (2, 'House of Representatives');


-- ============================================================
-- 13. ELECTION TYPES (current active — one row only)
-- ============================================================
CREATE TABLE election_types (
    id              BIGSERIAL   PRIMARY KEY,

    map_id_1        SMALLINT    NOT NULL DEFAULT 1,
    election_id_1   BIGINT      NOT NULL,

    map_id_2        SMALLINT    NOT NULL DEFAULT 2,
    election_id_2   BIGINT      NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT et_fk_election_1
        FOREIGN KEY (election_id_1) REFERENCES elections (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT et_fk_election_2
        FOREIGN KEY (election_id_2) REFERENCES elections (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT et_map_id_1_fixed CHECK (map_id_1 = 1),
    CONSTRAINT et_map_id_2_fixed CHECK (map_id_2 = 2)
);

CREATE INDEX idx_et_election_id_1 ON election_types (election_id_1);
CREATE INDEX idx_et_election_id_2 ON election_types (election_id_2);

CREATE OR REPLACE FUNCTION enforce_single_election_type_row()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT COUNT(*) FROM election_types) >= 1 THEN
        RAISE EXCEPTION
            'election_types is a single-row system table. Use UPDATE to change the active elections per slot.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_single_election_type_row
    BEFORE INSERT ON election_types
    FOR EACH ROW EXECUTE FUNCTION enforce_single_election_type_row();

CREATE OR REPLACE FUNCTION block_election_type_delete()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'election_types cannot be deleted. Use UPDATE to change active elections.';
END;
$$;

CREATE TRIGGER trg_block_election_type_delete
    BEFORE DELETE ON election_types
    FOR EACH ROW EXECUTE FUNCTION block_election_type_delete();

CREATE OR REPLACE FUNCTION check_election_map_ids()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM elections
        WHERE id = NEW.election_id_1 AND map_id = 1 AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION
            'election_id_1 must reference an active election with map_id = 1 (slot 1 group)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM elections
        WHERE id = NEW.election_id_2 AND map_id = 2 AND is_active = TRUE
    ) THEN
        RAISE EXCEPTION
            'election_id_2 must reference an active election with map_id = 2 (slot 2 group)';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_election_map_ids
    BEFORE INSERT OR UPDATE ON election_types
    FOR EACH ROW EXECUTE FUNCTION check_election_map_ids();

CREATE TRIGGER trg_election_types_updated_at
    BEFORE UPDATE ON election_types
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO election_types (election_id_1, election_id_2)
SELECT
    (SELECT id FROM elections WHERE name = 'Presidential'),
    (SELECT id FROM elections WHERE name = 'Senate');

CREATE OR REPLACE VIEW v_current_elections AS
SELECT
    et.id                       AS election_type_id,

    et.map_id_1                 AS slot_1_map_id,
    e1.id                       AS slot_1_election_id,
    e1.name                     AS slot_1_election_name,
    e1.is_active                AS slot_1_is_active,

    et.map_id_2                 AS slot_2_map_id,
    e2.id                       AS slot_2_election_id,
    e2.name                     AS slot_2_election_name,
    e2.is_active                AS slot_2_is_active

FROM election_types et
JOIN elections e1 ON e1.id = et.election_id_1
JOIN elections e2 ON e2.id = et.election_id_2;


-- ============================================================
-- 14. ELECTION CURRENT STATE (per-user live reporting snapshot)
-- ============================================================
CREATE TABLE elec_current_state (
    id                        BIGSERIAL   PRIMARY KEY,
    user_id                   BIGINT      NOT NULL,

    inec_ar_time              TIMESTAMPTZ  DEFAULT NULL,
    official_no               VARCHAR(50),

    security_present          BOOLEAN     NOT NULL DEFAULT FALSE,
    is_bvas_available         BOOLEAN     NOT NULL DEFAULT FALSE,
    is_bvas_working           BOOLEAN     NOT NULL DEFAULT FALSE,
    is_voters_verify          BOOLEAN     NOT NULL DEFAULT FALSE,
    has_accr_commence         BOOLEAN     NOT NULL DEFAULT FALSE,
    has_voting_commence       BOOLEAN     NOT NULL DEFAULT FALSE,
    is_voting_cancel          BOOLEAN     NOT NULL DEFAULT FALSE,
    are_security_present      BOOLEAN     NOT NULL DEFAULT FALSE,
    is_agent_at_polling_unit  BOOLEAN     NOT NULL DEFAULT FALSE,
    did_inec_clear_agent      BOOLEAN     NOT NULL DEFAULT FALSE,

    created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ecs_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT ecs_user_unique UNIQUE (user_id)
);

CREATE INDEX idx_ecs_user_id      ON elec_current_state (user_id);
CREATE INDEX idx_ecs_inec_ar_time ON elec_current_state (inec_ar_time);
CREATE INDEX idx_ecs_updated_at   ON elec_current_state (updated_at DESC);

CREATE TRIGGER trg_ecs_updated_at
    BEFORE UPDATE ON elec_current_state
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ============================================================
-- 15. POLLING UNIT REPORT
-- ============================================================

create table election_result_report(
	id          BIGSERIAL       PRIMARY KEY,
	uuids       TEXT   NOT NULL,
	user_id     BIGINT      NOT NULL,
	election_type varchar(100),
	election_name varchar(200),
	election_form varchar(100),
	pu  varchar(100),
	ward  varchar(100),
	lg  varchar(100),
	states  varchar(100),
	results JSONB       NOT NULL DEFAULT '{}'::jsonb,
	image_url TEXT,
	variables JSONB       NOT NULL DEFAULT '{}'::jsonb,
	created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
)

CREATE TABLE polling_unit_report (
    id          BIGSERIAL   PRIMARY KEY,
	user_id     BIGINT      NOT NULL,
    uuids       TEXT   NOT NULL,
	pu_id       INTEGER     NOT NULL,
	ward_id     INTEGER     NOT NULL,
	lg_id       INTEGER     NOT NULL,
	state_id    INTEGER     NOT NULL,
    payload     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT pur_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_pur_user_id     ON polling_unit_report (user_id);
CREATE INDEX idx_pur_created_at  ON polling_unit_report (created_at DESC);
CREATE INDEX idx_pur_payload_gin ON polling_unit_report USING GIN (payload);


CREATE TRIGGER trg_polling_unit_report_updated_at
    BEFORE UPDATE ON polling_unit_report
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();



-- ============================================================
-- 16. WARD COLLATION RESULT
-- ============================================================
CREATE TABLE ward_collation_report (
    id          BIGSERIAL   PRIMARY KEY,
    user_id     BIGINT      NOT NULL,
    payload     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT wcr_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX idx_wcr_user_id     ON ward_collation_report (user_id);
CREATE INDEX idx_wcr_created_at  ON ward_collation_report (created_at DESC);
CREATE INDEX idx_wcr_payload_gin ON ward_collation_report USING GIN (payload);

COMMENT ON TABLE  ward_collation_report          IS 'Flexible JSONB ward collation submissions, one row per submission, linked to the submitting user.';
COMMENT ON COLUMN ward_collation_report.user_id  IS 'FK → users.id — the supervisor/collation officer who submitted this result.';
COMMENT ON COLUMN ward_collation_report.payload  IS 'Arbitrary collation data (candidate votes, ward totals, etc.) stored as JSONB.';


-- ============================================================
-- 17. INCIDENT REPORT
-- ============================================================
CREATE TABLE incident_report (
    id          BIGSERIAL   PRIMARY KEY,
    user_id     BIGINT      NOT NULL,
    payload     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ir_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX idx_ir_user_id     ON incident_report (user_id);
CREATE INDEX idx_ir_created_at  ON incident_report (created_at DESC);
CREATE INDEX idx_ir_payload_gin ON incident_report USING GIN (payload);

COMMENT ON TABLE  incident_report          IS 'Flexible JSONB incident submissions, one row per submission, linked to the submitting user.';
COMMENT ON COLUMN incident_report.user_id  IS 'FK → users.id — the field officer/supervisor who submitted this incident.';
COMMENT ON COLUMN incident_report.payload  IS 'Arbitrary incident data (type, description, severity, media refs, etc.) stored as JSONB.';


-- ============================================================
-- 18. POLLING UNIT SECURITY REPORT
-- ============================================================
CREATE TABLE polling_unit_security_report (
    id          BIGSERIAL   PRIMARY KEY,
    user_id     BIGINT      NOT NULL,
    payload     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT pusr_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX idx_pusr_user_id     ON polling_unit_security_report (user_id);
CREATE INDEX idx_pusr_created_at  ON polling_unit_security_report (created_at DESC);
CREATE INDEX idx_pusr_payload_gin ON polling_unit_security_report USING GIN (payload);

COMMENT ON TABLE  polling_unit_security_report          IS 'Flexible JSONB polling-unit-level security submissions, one row per submission, linked to the submitting user.';
COMMENT ON COLUMN polling_unit_security_report.user_id  IS 'FK → users.id — the field officer who submitted this security report.';
COMMENT ON COLUMN polling_unit_security_report.payload  IS 'Arbitrary security data (personnel count, agency, presence flags, etc.) stored as JSONB.';


-- ============================================================
-- 19. WARD SECURITY REPORT
-- ============================================================
CREATE TABLE ward_security_report (
    id          BIGSERIAL   PRIMARY KEY,
    user_id     BIGINT      NOT NULL,
    payload     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT wsr_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX idx_wsr_user_id     ON ward_security_report (user_id);
CREATE INDEX idx_wsr_created_at  ON ward_security_report (created_at DESC);
CREATE INDEX idx_wsr_payload_gin ON ward_security_report USING GIN (payload);

COMMENT ON TABLE  ward_security_report          IS 'Flexible JSONB ward-level security submissions, one row per submission, linked to the submitting user.';
COMMENT ON COLUMN ward_security_report.user_id  IS 'FK → users.id — the supervisor who submitted this ward security report.';
COMMENT ON COLUMN ward_security_report.payload  IS 'Arbitrary ward security data (overall status, escalations, agency coverage, etc.) stored as JSONB.';


-- ============================================================
-- 20. PARTY AGENT REPORT
-- ============================================================
CREATE TABLE party_agent_report (
    id          BIGSERIAL   PRIMARY KEY,
    user_id     BIGINT      NOT NULL,
    payload     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT par_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX idx_par_user_id     ON party_agent_report (user_id);
CREATE INDEX idx_par_created_at  ON party_agent_report (created_at DESC);
CREATE INDEX idx_par_payload_gin ON party_agent_report USING GIN (payload);

COMMENT ON TABLE  party_agent_report          IS 'Flexible JSONB party agent coordination submissions, one row per submission, linked to the submitting user.';
COMMENT ON COLUMN party_agent_report.user_id  IS 'FK → users.id — the field officer who submitted this party agent report.';
COMMENT ON COLUMN party_agent_report.payload  IS 'Arbitrary party agent data (party, agent name, presence, accreditation status, etc.) stored as JSONB.';


-- ============================================================
-- 21. ELECTION RESULT REPORT
-- ============================================================
CREATE TABLE election_result_report (
    id          BIGSERIAL   PRIMARY KEY,
    user_id     BIGINT      NOT NULL,
    payload     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT err_fk_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX idx_err_user_id     ON election_result_report (user_id);
CREATE INDEX idx_err_created_at  ON election_result_report (created_at DESC);
CREATE INDEX idx_err_payload_gin ON election_result_report USING GIN (payload);

COMMENT ON TABLE  election_result_report          IS 'Flexible JSONB election result submissions, one row per submission, linked to the submitting user.';
COMMENT ON COLUMN election_result_report.user_id  IS 'FK → users.id — the field officer/collation officer who submitted this result.';
COMMENT ON COLUMN election_result_report.payload  IS 'Arbitrary election result data (candidate vote counts, election type, form image refs, etc.) stored as JSONB.';