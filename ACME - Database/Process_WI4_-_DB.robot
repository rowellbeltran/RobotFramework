*** Settings ***
Suite Teardown
Resource          Variables.robot
Resource          Utilities.robot
Resource          Keywords.robot
Resource          Work_Items.robot
Resource          Templates.robot
Resource          Gherkin Keywords.robot
Resource          Templates.robot

*** Test Cases ***
test
    [Setup]
    Connect To SQL Server
    ${open count}    Query    Select count(WIID) From ACME_work_items where Status = 'Open'
    Should Be Equal as Integers    ${open count[0][0]}    0
