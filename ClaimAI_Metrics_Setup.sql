-- ============================================================
-- ClaimAI Metrics — Combined Setup Script
-- Run this ONCE against the Spectra (McarePlus) database
-- Creates: 2 tables + 2 stored procedures
-- ============================================================

-- ============================================================
-- TABLE 1: ClaimAI_EventLog
-- Detailed log — one row per event (save click or field change)
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
        EventType   VARCHAR(50)     NOT NULL,
        FieldName   VARCHAR(100)    NULL,
        AIValue     NVARCHAR(1000)  NULL,
        UserValue   NVARCHAR(1000)  NULL,
        ClaimType   VARCHAR(50)     NULL,
        UserID      BIGINT          NULL,
        UserName    NVARCHAR(200)   NULL,
        IPAddress   VARCHAR(50)     NULL,
        CreatedAt   DATETIME        NOT NULL DEFAULT GETDATE(),

        CONSTRAINT PK_ClaimAI_EventLog PRIMARY KEY CLUSTERED (ID ASC)
    );

    CREATE NONCLUSTERED INDEX IX_ClaimAI_EventLog_ClaimID
        ON ClaimAI_EventLog (ClaimID, SlNo, CreatedAt DESC);

    CREATE NONCLUSTERED INDEX IX_ClaimAI_EventLog_EventType
        ON ClaimAI_EventLog (EventType, CreatedAt DESC);

    PRINT 'TABLE ClaimAI_EventLog — created successfully.';
END
ELSE
    PRINT 'TABLE ClaimAI_EventLog — already exists, skipped.';
GO

-- ============================================================
-- TABLE 2: ClaimAI_SaveCount
-- Summary — one row per claim, running save counter
-- ============================================================
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'ClaimAI_SaveCount'
)
BEGIN
    CREATE TABLE ClaimAI_SaveCount (
        ClaimID         BIGINT          NOT NULL,
        SlNo            INT             NOT NULL DEFAULT 1,
        SaveCount       INT             NOT NULL DEFAULT 0,
        FirstSavedAt    DATETIME        NULL,
        LastSavedAt     DATETIME        NULL,
        ClaimType       VARCHAR(50)     NULL,
        LastSavedBy     NVARCHAR(200)   NULL,

        CONSTRAINT PK_ClaimAI_SaveCount PRIMARY KEY CLUSTERED (ClaimID, SlNo)
    );

    PRINT 'TABLE ClaimAI_SaveCount — created successfully.';
END
ELSE
    PRINT 'TABLE ClaimAI_SaveCount — already exists, skipped.';
GO

-- ============================================================
-- SP 1: USP_ClaimAI_LogEvent
-- Inserts one row into ClaimAI_EventLog per event
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
        (ClaimID, SlNo, EventType, FieldName, AIValue, UserValue,
         ClaimType, UserID, UserName, IPAddress, CreatedAt)
    VALUES
        (@ClaimID, @SlNo, @EventType, @FieldName, @AIValue, @UserValue,
         @ClaimType, @UserID, @UserName, @IPAddress, GETDATE());
END
GO

PRINT 'SP USP_ClaimAI_LogEvent — created successfully.';
GO

-- ============================================================
-- SP 2: USP_ClaimAI_IncrementSaveCount
-- Upsert on ClaimAI_SaveCount — insert on first save, increment after
-- ============================================================
IF OBJECT_ID('USP_ClaimAI_IncrementSaveCount', 'P') IS NOT NULL
    DROP PROCEDURE USP_ClaimAI_IncrementSaveCount;
GO

CREATE PROCEDURE USP_ClaimAI_IncrementSaveCount
    @ClaimID    BIGINT,
    @SlNo       INT,
    @ClaimType  VARCHAR(50)     = NULL,
    @UserName   NVARCHAR(200)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM ClaimAI_SaveCount
        WHERE ClaimID = @ClaimID AND SlNo = @SlNo
    )
        UPDATE ClaimAI_SaveCount
        SET    SaveCount   = SaveCount + 1,
               LastSavedAt = GETDATE(),
               LastSavedBy = @UserName
        WHERE  ClaimID = @ClaimID AND SlNo = @SlNo;
    ELSE
        INSERT INTO ClaimAI_SaveCount
            (ClaimID, SlNo, SaveCount, FirstSavedAt, LastSavedAt, ClaimType, LastSavedBy)
        VALUES
            (@ClaimID, @SlNo, 1, GETDATE(), GETDATE(), @ClaimType, @UserName);
END
GO

PRINT 'SP USP_ClaimAI_IncrementSaveCount — created successfully.';
GO

-- ============================================================
-- VERIFY — run after execution to confirm everything is in place
-- ============================================================
SELECT
    'Tables'         AS ObjectType,
    TABLE_NAME       AS ObjectName
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('ClaimAI_EventLog', 'ClaimAI_SaveCount')

UNION ALL

SELECT
    'Stored Procedures',
    ROUTINE_NAME
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME IN ('USP_ClaimAI_LogEvent', 'USP_ClaimAI_IncrementSaveCount')

ORDER BY ObjectType, ObjectName;
GO
