<img width="1333" height="644" alt="image" src="https://github.com/user-attachments/assets/141ab82c-d918-40e2-80f8-b6de0ed2fe2a" />

An explicit value for the identity column in table 'McarePlus_Audit..Mst_Users' can only be specified when a column list is used and IDENTITY_INSERT is ON.

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
