-- ============================================================
-- ClaimAI Event Log Table
-- Tracks: Save button clicks + field changes made by users
-- after ClaimAI populates values in Spectra
-- ============================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'ClaimAI_EventLog'
)
BEGIN
    CREATE TABLE ClaimAI_EventLog (
        ID          BIGINT          IDENTITY(1,1)   NOT NULL,
        ClaimID     BIGINT          NOT NULL,
        SlNo        INT             NOT NULL DEFAULT 1,
        EventType   VARCHAR(50)     NOT NULL,        -- 'SAVE_CLICK' | 'FIELD_CHANGE'
        FieldName   VARCHAR(100)    NULL,            -- null for SAVE_CLICK rows
        AIValue     NVARCHAR(1000)  NULL,            -- value ClaimAI populated
        UserValue   NVARCHAR(1000)  NULL,            -- value user changed to
        ClaimType   VARCHAR(50)     NULL,            -- 'cataract' | 'maternity' | 'other'
        UserID      BIGINT          NULL,
        UserName    NVARCHAR(200)   NULL,
        IPAddress   VARCHAR(50)     NULL,
        CreatedAt   DATETIME        NOT NULL DEFAULT GETDATE(),

        CONSTRAINT PK_ClaimAI_EventLog PRIMARY KEY CLUSTERED (ID ASC)
    );

    -- Index for fast lookup by claim
    CREATE NONCLUSTERED INDEX IX_ClaimAI_EventLog_ClaimID
        ON ClaimAI_EventLog (ClaimID, SlNo, CreatedAt DESC);

    -- Index for reporting by event type
    CREATE NONCLUSTERED INDEX IX_ClaimAI_EventLog_EventType
        ON ClaimAI_EventLog (EventType, CreatedAt DESC);

    PRINT 'ClaimAI_EventLog table created successfully.';
END
ELSE
BEGIN
    PRINT 'ClaimAI_EventLog table already exists — skipped.';
END
GO

-- ============================================================
-- Stored Procedure to insert log entries
-- Called by MedicalScrutinyController.LogClaimAIEvent
-- ============================================================

IF OBJECT_ID('USP_ClaimAI_LogEvent', 'P') IS NOT NULL
    DROP PROCEDURE USP_ClaimAI_LogEvent;
GO

CREATE PROCEDURE USP_ClaimAI_LogEvent
    @ClaimID    BIGINT,
    @SlNo       INT,
    @EventType  VARCHAR(50),
    @FieldName  VARCHAR(100)    = NULL,
    @AIValue    NVARCHAR(1000)  = NULL,
    @UserValue  NVARCHAR(1000)  = NULL,
    @ClaimType  VARCHAR(50)     = NULL,
    @UserID     BIGINT          = NULL,
    @UserName   NVARCHAR(200)   = NULL,
    @IPAddress  VARCHAR(50)     = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO ClaimAI_EventLog
        (ClaimID, SlNo, EventType, FieldName, AIValue, UserValue, ClaimType, UserID, UserName, IPAddress, CreatedAt)
    VALUES
        (@ClaimID, @SlNo, @EventType, @FieldName, @AIValue, @UserValue, @ClaimType, @UserID, @UserName, @IPAddress, GETDATE());
END
GO

-- ============================================================
-- Reporting query — Save click count per day
-- ============================================================
-- SELECT
--     CAST(CreatedAt AS DATE)     AS LogDate,
--     COUNT(*)                    AS SaveClicks,
--     ClaimType
-- FROM ClaimAI_EventLog
-- WHERE EventType = 'SAVE_CLICK'
-- GROUP BY CAST(CreatedAt AS DATE), ClaimType
-- ORDER BY LogDate DESC;

-- ============================================================
-- Reporting query — Field changes per field name
-- ============================================================
-- SELECT
--     FieldName,
--     COUNT(*)    AS ChangeCount,
--     ClaimType
-- FROM ClaimAI_EventLog
-- WHERE EventType = 'FIELD_CHANGE'
-- GROUP BY FieldName, ClaimType
-- ORDER BY ChangeCount DESC;

PRINT 'USP_ClaimAI_LogEvent procedure created successfully.';
GO
