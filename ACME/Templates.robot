*** Settings ***
Resource          Keywords.robot
Resource          Gherkin Keywords.robot

*** Keywords ***
TC01 - Process Open WI4 Work Item
    [Arguments]    ${wiid}
    Given Work Item Is Found    ${wiid}
    When Monthly Reports Are Downloaded and Yearly Report Generated
    Then Upload Yearly Report And Close Work Item
