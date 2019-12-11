*** Settings ***
Library           DataDriver    my_data_file.csv    dialect=excel    encoding=${None}
Resource          Templates.robot
Resource          Templates.robot

*** Test Cases ***
TC01 - Process WI4 Work Item
    [Template]    TC01 - Process Open WI4 Work Item
