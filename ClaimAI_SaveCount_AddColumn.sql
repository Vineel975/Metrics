-- ============================================================
-- Add SaveCount column to track how many times Save was clicked
-- per claim directly — for instant reporting without aggregation
-- ============================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'ClaimAI_EventLog'
    AND COLUMN_NAME = 'SaveCount'
)
BEGIN
    -- Add a summary table for per-claim save counts
    -- Easier to query than counting rows in the log table
    PRINT 'Creating ClaimAI_SaveCount table...';
END
GO

-- ============================================================
-- New summary table — one row per claim, incremented on save
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

    PRINT 'ClaimAI_SaveCount table created successfully.';
END
ELSE
BEGIN
    PRINT 'ClaimAI_SaveCount table already exists — skipped.';
END
GO

-- ============================================================
-- Stored Procedure to increment save count for a claim
-- Called alongside USP_ClaimAI_LogEvent on each save click
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

    IF EXISTS (SELECT 1 FROM ClaimAI_SaveCount WHERE ClaimID = @ClaimID AND SlNo = @SlNo)
    BEGIN
        -- Already exists — just increment
        UPDATE ClaimAI_SaveCount
        SET
            SaveCount   = SaveCount + 1,
            LastSavedAt = GETDATE(),
            LastSavedBy = @UserName
        WHERE ClaimID = @ClaimID AND SlNo = @SlNo;
    END
    ELSE
    BEGIN
        -- First save for this claim
        INSERT INTO ClaimAI_SaveCount
            (ClaimID, SlNo, SaveCount, FirstSavedAt, LastSavedAt, ClaimType, LastSavedBy)
        VALUES
            (@ClaimID, @SlNo, 1, GETDATE(), GETDATE(), @ClaimType, @UserName);
    END
END
GO

-- ============================================================
-- Reporting queries
-- ============================================================

-- Per-claim save count (most clicked first)
-- SELECT
--     ClaimID,
--     SlNo,
--     SaveCount,
--     ClaimType,
--     FirstSavedAt,
--     LastSavedAt,
--     LastSavedBy
-- FROM ClaimAI_SaveCount
-- ORDER BY SaveCount DESC;

-- Claims saved more than once (doctors who revised)
-- SELECT *
-- FROM ClaimAI_SaveCount
-- WHERE SaveCount > 1
-- ORDER BY SaveCount DESC;

-- Total saves across all claims
-- SELECT
--     SUM(SaveCount)  AS TotalSaves,
--     ClaimType,
--     COUNT(*)        AS UniqueClaims
-- FROM ClaimAI_SaveCount
-- GROUP BY ClaimType;

PRINT 'USP_ClaimAI_IncrementSaveCount procedure created successfully.';
GO
