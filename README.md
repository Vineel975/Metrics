-- Check table exists
SELECT * FROM ClaimAI_EventLog;

-- Check SP exists
EXEC USP_ClaimAI_LogEvent 
    @ClaimID = 1, 
    @SlNo = 1, 
    @EventType = 'TEST',
    @UserName = 'test';

SELECT * FROM ClaimAI_EventLog; -- should show 1 row
DELETE FROM ClaimAI_EventLog;   -- clean up test row
