-- adopt_snapshot.sql -- SQL equivalent of `manage.py adopt_snapshot`.
--
-- Makes a restored snapshot safe for a laptop:
--   1. Every Authorize.net merchant (bbp_pluginconfiguration for the
--      authorize_net plugin) gets a client-wide `environment = sandbox` setting.
--   2. Every stored production credential on those merchants is blanked
--      (all scopes: client / role / user).
--   3. bbp_deploymentstamp is set to 'local:<current database>', which is what
--      a local backend expects before it will start.
--
-- Mirrors bbp/plugins/authorize_net/snapshot_scrub.py and
-- bbp/multi_tenant/deployment_stamp.py. Idempotent; safe to re-run.
--
-- Usage:
--   psql -h localhost -U core -d <db> -v ON_ERROR_STOP=1 -f adopt_snapshot.sql

\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
    ct_id      integer;
    merchants  integer := 0;
    cleared    integer := 0;
BEGIN
    -- ---------------------------------------------------------------- Authorize.net
    IF to_regclass('public.bbp_pluginconfiguration') IS NULL
       OR to_regclass('public.bbp_pluginnavvalue') IS NULL THEN
        RAISE NOTICE 'Authorize.net: plugin tables missing, skipped';
    ELSE
        SELECT id INTO ct_id
          FROM django_content_type
         WHERE app_label = 'bbp' AND model = 'pluginconfiguration';

        CREATE TEMP TABLE _authnet_conf ON COMMIT DROP AS
            SELECT pc.id, pc.tenant_id, pc.program_id
              FROM bbp_pluginconfiguration pc
              JOIN bbp_pluginbase p ON p.id = pc.plugin_id
             WHERE p.name = 'authorize_net';
        SELECT count(*) INTO merchants FROM _authnet_conf;

        -- The `environment` attribute is per tenant/program; create it where missing.
        INSERT INTO bbp_navattribute (namespace, name, data_type, created, modified,
                                      tenant_id, program_id)
        SELECT DISTINCT 'PluginConfig::authorize_net', 'environment', 'str', now(), now(),
               c.tenant_id, c.program_id
          FROM _authnet_conf c
        ON CONFLICT (namespace, name, tenant_id, program_id) DO NOTHING;

        -- Environment defaults to production, so a missing row must be written.
        UPDATE bbp_pluginnavvalue v
           SET stored_value = 'sandbox', modified = now(),
               applies_to_member_id = NULL, applies_to_role_id = NULL
          FROM _authnet_conf c, bbp_navattribute a
         WHERE v.content_type_id = ct_id
           AND v.object_id = c.id
           AND v.applies_to = 'client'
           AND v.attribute_id = a.id
           AND a.namespace = 'PluginConfig::authorize_net'
           AND a.name = 'environment'
           AND a.tenant_id = c.tenant_id
           AND a.program_id = c.program_id;

        INSERT INTO bbp_pluginnavvalue (created, modified, stored_value, object_id, applies_to,
                                        attribute_id, content_type_id, tenant_id, program_id)
        SELECT now(), now(), 'sandbox', c.id, 'client', a.id, ct_id, c.tenant_id, c.program_id
          FROM _authnet_conf c
          JOIN bbp_navattribute a
            ON a.namespace = 'PluginConfig::authorize_net'
           AND a.name = 'environment'
           AND a.tenant_id = c.tenant_id
           AND a.program_id = c.program_id
         WHERE NOT EXISTS (
               SELECT 1 FROM bbp_pluginnavvalue v
                WHERE v.content_type_id = ct_id
                  AND v.object_id = c.id
                  AND v.applies_to = 'client'
                  AND v.attribute_id = a.id);

        -- Credentials default to blank, so clearing the stored rows at every scope suffices.
        UPDATE bbp_pluginnavvalue v
           SET stored_value = '', modified = now()
          FROM bbp_navattribute a
         WHERE v.attribute_id = a.id
           AND v.content_type_id = ct_id
           AND v.object_id IN (SELECT id FROM _authnet_conf)
           AND a.name IN ('production_api_login_id', 'production_transaction_key',
                          'production_signature_key', 'production_public_client_key')
           AND v.stored_value IS DISTINCT FROM '';
        GET DIAGNOSTICS cleared = ROW_COUNT;

        RAISE NOTICE 'Authorize.net: % merchant(s) moved to sandbox, % live key value(s) cleared',
                     merchants, cleared;
    END IF;

    -- ------------------------------------------------------------- Deployment stamp
    IF to_regclass('public.bbp_deploymentstamp') IS NULL THEN
        RAISE NOTICE 'Deployment stamp: table missing, written by the next migrate';
    ELSE
        INSERT INTO bbp_deploymentstamp (id, created, modified, swimlane)
        VALUES (1, now(), now(), 'local:' || current_database())
        ON CONFLICT (id) DO UPDATE
            SET swimlane = EXCLUDED.swimlane, modified = now();
        RAISE NOTICE 'Deployment stamp: local:%', current_database();
    END IF;
END
$$;

COMMIT;
