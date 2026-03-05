/*
================================================================================
Procedure: admin.usp_ToggleCopyDataConfig_Demo
Purpose  : Toggle flagActive for a given ingestion configuration
================================================================================
*/

CREATE OR ALTER PROCEDURE admin.usp_ToggleCopyDataConfig_Demo
(
    @model varchar(256),
    @destinationObjectPattern varchar(64)
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE admin.copyDataConfig
    SET 
        flagActive = CASE 
                        WHEN flagActive = 1 THEN 0
                        ELSE 1
                     END,
        lastModifiedDate = SYSDATETIME()
    WHERE model = @model
      AND destinationObjectPattern = @destinationObjectPattern;

    SELECT 
        'TOGGLED' AS result;
END;