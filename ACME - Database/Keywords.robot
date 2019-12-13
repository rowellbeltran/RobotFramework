*** Settings ***
Library           SeleniumLibrary
Resource          Utilities.robot
Library           Collections
Resource          Work_Items.robot
Resource          Variables.robot
Library           OperatingSystem
Library           ExcelLibrary
Library           CSVLib
Library           String
Library           DateTime
Library           DatabaseLibrary

*** Keywords ***
Log Into ACME
    [Arguments]    ${url}    ${browser}    ${user}    ${password_enc}
    Log    Logging into ACME
    open browser    ${url}    ${browser}
    maximize browser window
    Wait until Element is Visible    xpath=//div/h1[@class='page-header']
    input text    id=email    ${user}
    set log level    NONE    #hide password
    ${password}=    Decrypt Password    ${password_enc}
    input password    id=password    ${password}
    click button    id=buttonLogin
    set log level    INFO
    #check main page displayed
    Wait until Element is Visible    xpath=//div[@class='main-container']/h1
    ${header}=    get text    xpath=//div[@class='main-container']/h1
    should be equal    ${header}    Welcome, ${ACME_user} to System 1.

Navigate To Work Items
    Log    Navigating to Work Items
    click element    xpath=//a[@href ='/']    #Home
    click element    xpath=//a[@href ='/work-items']    #Work Item Button
    Wait until Element is Visible    xpath=//h1[@class='page-header']
    ${header}=    get text    xpath=//h1[@class='page-header']
    should be equal    ${header}    Work Items

Get Open Items Per Page
    [Arguments]    ${item type}
    Log    Collecting All Open ${item type} Work Items Per Page
    Connect To SQL Server
    ${page row count}=    Get Element Count    xpath=//div[@class='panel panel-default']/table/tbody/tr
    : FOR    ${page row count}    IN RANGE    2    ${page row count}
    \    ${wiid}=    get text    xpath=//div[@class='panel panel-default']/table/tbody/tr[${page row count}]/td[2]
    \    ${type}=    get text    xpath=//div[@class='panel panel-default']/table/tbody/tr[${page row count}]/td[4]
    \    ${status}=    get text    xpath=//div[@class='panel panel-default']/table/tbody/tr[${page row count}]/td[5]
    \    ${item}=    Set Variable    ${wiid},${type},${status}
    \    Run Keyword If    '${type}' == '${item type}' and '${Status}' == 'Open'    Execute SQL String    Insert Into ACME_work_items (WIID,Type,Status) values('${WIID}','${type}','${status}')
    [Teardown]    Disconnect From Database

Navigate To Work Item Details
    [Arguments]    ${wiid}
    Search Work Item    ${wiid}
    Click Element    xpath=//a[@href='/work-items/${wiid}']    #Navigate to Work Item Details
    Page Should Contain Element    //h4[contains(text(),'Vendor Information')]

Search Work Item
    [Arguments]    ${wiid}
    Log    Searching Work Item
    ${page count}=    Get Element Count    //ul[@class='page-numbers']/li
    ${page count}=    Evaluate    ${page count}+1
    : FOR    ${page}    IN RANGE    1    ${page count}
    \    #Click Details If Found
    \    ${wiid count}=    Get Element Count    xpath=//a[@href='/work-items/${wiid}']
    \    Exit For Loop If    '${wiid count}' > '0'
    \    Click Element    xpath=//a[contains(text(),'>')]    #next page
    Should Be True    '${wiid count}' > '0'

Process WI4 Work Item
    [Arguments]    ${wiid}
    Navigate To Work Items
    Navigate To Work Item Details    ${wiid}
    ${tax id}=    Get Vendor Tax ID
    Get Report Year
    Download Monthly Reports    ${tax id}
    Generate Yearly Report    ${tax id}
    ${upload id}=    Upload Yearly Report    ${tax id}
    Update Work Item Status    ${wiid}    Completed    Upload ID: ${upload id}
    [Teardown]    Refresh App

Navigate To Download Monthly Reports
    Log    Navigating to Download Monthly Reports
    click element    xpath=//a[@href ='/']    #Home
    click element    xpath=//i[@class='fa fa-files-o']/ancestor::button    #Reports Button
    click element    xpath=//a[contains(text(), 'Download Monthly Report')]    #Download Monthly Report Button
    Wait until Element is Visible    xpath=//h1[@class='page-header']
    ${header}=    get text    xpath=//h1[@class='page-header']
    should be equal    ${header}    Reports - Download Monthly Report

Download Monthly Reports
    [Arguments]    ${tax id}
    Navigate to Download Monthly Reports
    Input Text    id=vendorTaxID    ${tax id}
    Click Element    xpath=//div[@class='controls']/label[contains(text(),'Year')]/following-sibling::div
    Click Element    xpath=//a/span[contains(text(),'${REPORT YEAR}')]    #Select Year
    : FOR    ${month}    IN    @{MONTHS}
    \    Click Element    xpath=//div[@class='controls']/label[contains(text(),'Month')]/following-sibling::div
    \    Click Element    //a/span[contains(text(),'${month}')]    #Select Month
    \    Click Element    id=buttonDownload
    \    Run Keyword and Ignore Error    Handle Alert    timeout=1 s
    \    sleep    1s
    Close Chrome Download Bar
    Create Directory    ${DIR_MONTHLY REPORTS}/${REPORT YEAR}/${tax id}
    Move Files    C:/Users/%{USERNAME}/Downloads/Report-${tax id}*.csv    ${DIR_MONTHLY REPORTS}/${REPORT YEAR}/${tax id}    #move from Downloads

Generate Yearly Report
    [Arguments]    ${tax id}
    Create Directory    ${DIR_YEARLY REPORTS}/${REPORT YEAR}
    @{files}=    List Directory    ${DIR_MONTHLY REPORTS}/${REPORT YEAR}/${tax id}    Report-${tax id}*.csv
    @{cosolidated}=    Create List
    #Consolidate File Contents
    : FOR    ${file}    IN    @{files}
    \    @{content}=    Read Csv As List    ${DIR_MONTHLY REPORTS}/${REPORT YEAR}/${tax id}/${file}    delimiter=,
    \    ${file header}=    Remove From List    ${content}    0
    \    ${cosolidated}=    Combine Lists    ${cosolidated}    ${content}
    #Create Yearly Report Excel File
    ${report file}=    Create Excel Document    doc_id=doc1
    #Header
    @{header}=    Create List    InvoiceNumber    Item    Amount    Tax    Total
    ...    Currency    Date
    Insert Into List    ${cosolidated}    0    ${header}
    #Data
    Write Excel Rows    ${cosolidated}    rows_offset=0    col_offset=0    sheet_name=Sheet
    Save Excel Document    ${DIR_YEARLY REPORTS}/${REPORT YEAR}/Yearly-Report-${REPORT YEAR}-${tax id}.xlsx
    Close Current Excel Document

Upload Yearly Report
    [Arguments]    ${tax id}
    Navigate To Upload Yearly Reports
    Input Text    id=vendorTaxID    ${tax id}
    Click Element    xpath=//div[@class='controls']/label[contains(text(),'Year')]/following-sibling::div
    Click Element    xpath=//a/span[contains(text(),'${REPORT YEAR}')]    #Select Year
    Choose File    id=my-file-selector    ${DIR_YEARLY REPORTS}/${REPORT YEAR}/Yearly-Report-${REPORT YEAR}-${tax id}.xlsx
    Click Element    id=buttonUpload
    #Get Alert Message
    ${alert}=    Handle Alert
    @{alert split}=    Split String    ${alert}    is
    ${message}=    Strip String    ${alert split[0]}
    ${upload id}=    Strip String    ${alert split[1]}
    #Check Success
    Should Be Equal    ${message}    Report was uploaded - confirmation id
    [Return]    ${upload id}

Navigate To Upload Yearly Reports
    Log    Navigating to Upload Yearly Reports
    click element    xpath=//a[@href ='/']    #Home
    click element    xpath=//i[@class='fa fa-files-o']/ancestor::button    #Reports Button
    click element    xpath=//a[contains(text(), 'Upload Yearly Report')]    #Upload Yearly Report Button
    Wait until Element is Visible    xpath=//h1[@class='page-header']
    ${header}=    get text    xpath=//h1[@class='page-header']
    should be equal    ${header}    Reports - Upload Yearly Report

Get Vendor Tax ID
    ${vendor info}=    Get Text    xpath=//b[contains(text(),'TaxID')]/ancestor::p
    @{info list}=    Split String    ${vendor info}
    ${tax id}=    Set Variable    ${info list[1]}
    [Return]    ${tax id}

Update Work Item Status
    [Arguments]    ${wiid}    ${status}    ${comment}
    Navigate To Work Items
    Navigate To Work Item Details    ${wiid}
    Click Element    xpath=//i[@class='fa fa-pencil']/ancestor::button    #Click Update Button
    #Handle New Window
    @{handles}=    Get Window Handles    ALL
    Switch Window    ${handles[1]}
    Input Text    id=newComment    ${comment}
    Click Element    xpath=//button[@data-id='newStatus']
    Click Element    xpath=//span[contains(text(),'${status}')]/ancestor::a
    Click Element    id=buttonUpdate
    ${alert}=    Handle Alert
    SHould Be Equal    ${alert}    Work Item was updated accordingly
    Close Window
    Switch Window    ${handles[0]}    #main window
    [Teardown]

Refresh App
    [Documentation]    Refresh for next item
    click element    xpath=//a[@href ='/']    #Home
    Close Chrome Download Bar

Check WI4 Work Item
    [Arguments]    ${wiid}
    [Documentation]    Check each processed item. All failed will be appended to the file for reprocessing.
    Navigate To Work Items
    Navigate To Work Item Details    ${wiid}
    Click Element    xpath=//i[@class='fa fa-pencil']/ancestor::button    #Click Update Button
    #Handle New Window
    @{handles}=    Get Window Handles    ALL
    Switch Window    ${handles[1]}
    ${item details}=    Get Text    xpath=//b[contains(text(),'Status')]/ancestor::p
    @{details list}=    Split String    ${item details}    \n
    #Check Status
    ${status}=    Set Variable    ${details list[2]}
    Run Keyword And Continue On Failure    Should Contain    ${status}    Completed
    # Check CommentRlocalhostMonetwo10
    ${comment}=    Set Variable    ${details list[4]}
    Run Keyword And Continue On Failure    Should Contain    ${comment}    Upload ID:
    #Back To Main Window
    Close Window
    Switch Window    ${handles[0]}    #main window
    [Teardown]    Refresh App

Connect To SQL Server
    Log    Connecting DB
    set log level    NONE    #hide password
    ${password}=    Decrypt Password    ${DB PASSWORD_ENCRYPTED}
    Connect To Database    pymssql    Test DB    RF_TEST    ${password}    localhost    1433
    set log level    INFO
