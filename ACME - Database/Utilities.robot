*** Settings ***
Library           ../Common/Modules/decrypt.py
Library           SeleniumLibrary

*** Keywords ***
Get Report Year
    ${date} =    Get Current Date    result_format=datetime
    ${year}=    Evaluate    ${date.year}-1
    Set Global Variable    ${REPORT YEAR}    ${year}
    [Return]    ${report year}

Decrypt Password
    [Arguments]    ${enc}
    ${dec}=    decode    ${enc}
    [Return]    ${dec}

Close Chrome Download Bar
    Press Keys    None    CONTROL+J    CONTROL+W
