<<<<<<< HEAD
/*
Minimum permissions required for Power Apps / Power Automate SQL connector identity.

Replace <principal> with your managed identity / service principal / user.
*/

-- Read for UI
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig_fields TO [<principal>];
-- (optional)
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig_search_v2 TO [<principal>];

-- Execute for flows
-- GRANT EXECUTE ON OBJECT::admin.usp_CreateCopyDataConfig_Basic TO [<principal>];
-- GRANT EXECUTE ON OBJECT::admin.usp_SetFlagActive TO [<principal>];
=======
/*
Minimum permissions required for Power Apps / Power Automate SQL connector identity.

Replace <principal> with your managed identity / service principal / user.
*/

-- Read for UI
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig TO [<principal>];
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig_fields TO [<principal>];
-- (optional)
-- GRANT SELECT ON OBJECT::admin.v_ui_copyDataConfig_search_v2 TO [<principal>];

-- Execute for flows
-- GRANT EXECUTE ON OBJECT::admin.usp_CreateCopyDataConfig_Basic TO [<principal>];
-- GRANT EXECUTE ON OBJECT::admin.usp_SetFlagActive TO [<principal>];
>>>>>>> 88bbf1aad7e883f8c19e0d3796f34cc884d3698b
-- GRANT EXECUTE ON OBJECT::admin.usp_SetFlagBlock TO [<principal>];