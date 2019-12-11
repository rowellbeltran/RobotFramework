*** Settings ***
Library           SeleniumLibrary
Resource          Utilities.robot
Library           Collections
Resource          Work_Items.robot
Resource          Variables.robot
Library           OperatingSystem
Library           CSVLib
Library           String
Library           DateTime
Resource          Keywords.robot

*** Keywords ***
All Open Work Items Retrieved
    [Arguments]    ${item type}
    [Documentation]    Gets all open work item type and save in a file.
    Log    Collecting All Open ${item type} Work Items
    #There should be no pending file
    File Should Not Exist    ./Files/${item type} Work Items.csv
    #Create Data File
    Append To File    ./Files/${item type} Work Items.csv    WIID,Type, Status
    ${page count}=    Get Element Count    //ul[@class='page-numbers']/li
    ${page count}=    Evaluate    ${page count}+1
    : FOR    ${page index}    IN RANGE    1    ${page count}
    \    log    ${page index}
    \    Run Keyword If    '${page index}' == '3'    Continue For Loop    #prev page button element added
    \    Run Keyword If    '${page index}' == '1'    Click Element    xpath=//ul[@class='page-numbers']/li[${page index}]/span
    \    ...    ELSE    Click Element    xpath=//ul[@class='page-numbers']/li[${page index}]/a
    \    Get Open Items Per Page    ${item type}

All Open Work Items Processed
    [Arguments]    ${item type}
    [Documentation]    Process the work items listed in the file and move it to Processed folder.
    #Read Work Item File
    @{work items}=    Read CSV as List    ./Files/${item type} Work Items.csv    ,
    : FOR    ${item}    IN    @{work items}
    \    Continue For Loop If    '${item[0]}' == 'WIID'
    \    Run Keyword And Continue On Failure    Process ${item type} Work Item    ${item[0]}
    \    Comment    Return From Keyword if    '${item[0]}' == '345634'    #test
    Move Files    ./Files/${item type} Work Items.csv    ${DIR_PROCESSED}/${item type} Work Items.csv    #move file to Processed Folder

Items Should Be Completed
    [Arguments]    ${item type}
    [Documentation]    Check that the work items in the files were all processed successfully. Moves the file to Verified. Any failed work items will be added to a file fore reprocessing.
    Log    Checking All Processed ${item type} Work Items
    ${reprocess flag}=    Set Variable    False
    Append To File    ./Files/${item type} Work Items.csv    WIID,Type,Status    SYSTEM
    @{work items}=    Read CSV as List    ${DIR_PROCESSED}/${item type} Work Items.csv    ,
    : FOR    ${item}    IN    @{work items}
    \    Continue For Loop If    '${item[0]}' == 'WIID'
    \    ${passed}=    Run Keyword And Return Status    Check ${item type} Work Item    ${item[0]}
    \    #Failed for reprocessing
    \    Run Keyword If    '${passed}' == 'False'    Run Keywords    Append To File    ./Files/${item type} Work Items.csv    \n${item[0]},${item[1]},${item[2]}
    \    ...    SYSTEM
    \    ...    AND    Log    Item sent for reprocessing: ${item}    WARN
    \    ${reprocess flag}=    Set Variable If    '${passed}' == 'False'    True
    Run Keyword If    '${reprocess flag}' == 'False'    Remove File    ./Files/${item type} Work Items.csv
    Move Files    ${DIR_PROCESSED}/${item type} Work Items.csv    ${DIR_VERIFIED}/    #move file to Verified Folder

Work Item Is Found
    [Arguments]    ${wiid}
    Navigate To Work Items
    Navigate To Work Item Details    ${wiid}

Monthly Reports Are Downloaded and Yearly Report Generated
    ${tax id}=    Get Vendor Tax ID
    Get Report Year
    Download Monthly Reports    ${tax id}
    Generate Yearly Report    ${tax id}

Upload Yearly Report And Close Work Item
    ${upload id}=    Upload Yearly Report    ${tax id}
    Update Work Item Status    ${wiid}    Completed    Upload ID: ${upload id}
