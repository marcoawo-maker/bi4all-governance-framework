/*
Minimum permissions required for the Power Apps / Power Automate SQL connector identity.
Replace <principal> with your managed identity / service principal / user.
*/

-- Read for UI
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig_fields TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig_search TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig_search_v2 TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_runPreview_orphans TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_runPreview_readiness TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_runPreview_readinessMessage TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_runPreview_lastRun TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_runPreview_processStatus TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_runPreview_readiness_v2 TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.vw_copyDataConfig_Yaml TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.vw_copyDataConfig_Yaml_Latest TO [<principal>];

-- Execute for flows
-- GRANT EXECUTE ON OBJECT::admin.usp_CreateCopyDataConfig_Basic TO [<principal>];
-- GRANT EXECUTE ON OBJECT::admin.usp_SetFlagActive TO [<principal>];
-- GRANT EXECUTE ON OBJECT::admin.usp_SetFlagBlock TO [<principal>];
-- GRANT EXECUTE ON OBJECT::admin.usp_CreateCopyDataConfig_UI TO [<principal>];
-- GRANT EXECUTE ON OBJECT::admin.usp_UpdateCopyDataConfig_UI TO [<principal>];
-- GRANT EXECUTE ON OBJECT::admin.usp_SetCopyDataConfigActive_UI TO [<principal>];
