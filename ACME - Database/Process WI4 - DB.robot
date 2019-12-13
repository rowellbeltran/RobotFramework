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
Process Open WI4 Work Items
    [Documentation]    To Process WI4 Work Items (Generate Yearly Report).
    [Setup]    Log Into ACME    ${ACME URL}    chrome    ${ACME_USER}    ${ACME PASSWORD_ENCRYPTED}
    #Keywords    Item Type
    Given All Open Work Items Retrieved    WI4
    When All Open Work Items Processed    WI4
    Then Items Should Be Completed    WI4
    [Teardown]    Close Browser
