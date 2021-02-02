package.path = package.path .. ";" .. [[/usr/local/freeswitch/scripts/?.lua]]

local Log = require "call_logs"

local CallLog = Log.CallLog

dat = env:serialize()            
freeswitch.consoleLog("INFO","Here's everything:\n" .. dat .. "\n")
session = freeswitch.Session(argv[1]) 

-- if cause == "ATTENDED_TRANSFER" or cause == "BLIND_TRANSFER" 
-- then 
    -- api = freeswitch.API() 
    -- freeswitch.consoleLog("INFO",  "NOTICE Transfer detected, last app is " .. session:getVariable("last_app")) 
    -- freeswitch.consoleLog("INFO",  "NOTICE Transfer detected, status is " .. session:getVariable("status")) 
    -- freeswitch.consoleLog("INFO",  "NOTICE Transfer detected, duration is " .. session:getVariable("duration")) 
    -- freeswitch.consoleLog("INFO",  "NOTICE Transfer detected, billsec is " .. session:getVariable("billsec")) 
    -- freeswitch.consoleLog("INFO",  "NOTICE Transfer detected, endpoint disposition is " .. session:getVariable("endpoint_disposition")) 
    -- freeswitch.consoleLog("INFO",  "NOTICE Transfer detected, sip hangup disposition is " .. session:getVariable("sip_hangup_disposition")) 
    -- freeswitch.consoleLog("INFO",  "NOTICE Transfer detected, tenant id is " .. session:getVariable("tenant_id")) 
    -- freeswitch.consoleLog("INFO",  "NOTICE Transfer detected, answer stamp is " .. session:getVariable("answer_stamp")) 
    -- freeswitch.consoleLog("INFO",  session:getVariable("originate_disposition")) 
-- end 

dat = env:getHeader("uuid")      
freeswitch.consoleLog("INFO","Inside hangup hook, uuid is: " .. dat .. "\n")                            
 
local call_type = session:getVariable('log_call_type');
local dest_type = session:getVariable('log_dest_type');

freeswitch.consoleLog("INFO","Inside hangup is: " .. call_type .. "\n")                            


if call_type == 'sipcall' and session:getVariable('tenant_id') ~= nil then

	local call = CallLog:new{session=session, 
        caller=session:getVariable('effective_caller_id_number'), 
        uuid=session:getVariable('uuid'), 
        tenant_id=session:getVariable('tenant_id'), 
        callee=session:getVariable('callee'), 
        start_time=session:getVariable('start_stamp'),
        end_time=session:getVariable('end_stamp')};
    
    if dest_type == 'UNKNOWN' then

        call:failedLocal();
    else 

        call:sipCall()

    end

elseif call_type == 'mobile' then


elseif call_type == 'inbound' and session:getVariable('log_tenant_id') ~= nil  then

    local call = CallLog:new{session=session, 
        caller=session:getVariable('log_call_from'), 
        uuid=session:getVariable('uuid'), 
        source=session:getVariable('log_source'), 
        tenant_id=session:getVariable('log_tenant_id'), 
        callee=session:getVariable('log_call_to'), 
        start_time=session:getVariable('start_stamp'),
        end_time=session:getVariable('end_stamp')};
    

    call:inbound();

end