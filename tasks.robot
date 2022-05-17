*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Dialogs
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault
Library             RPA.Excel.Application
Library             RPA.Email.Exchange


*** Variables ***
#${URL}=    https://robotsparebinindustries.com/#/robot-order

#${orders_url}=    https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get the URL using the Get Secret keyword

    ${URL}=    Get the URL using the Get Secret keyword

    Open the robot order website    ${URL}

    ${orders_url}=    Ask URL of the orders CSV

    ${orders}=    Get orders    ${orders_url}

    FOR    ${row}    IN    @{orders}
        Close the popup
        Fill the form    ${row}
        Preview the robot
        Take a screenshot of the robot    ${row}
        Submit the order
        Store the receipt as a PDF file    ${row}
        Embed the robot screenshot to the receipt PDF file    ${row}
        Go to order another robot
    END

    Create a ZIP file of the receipts


*** Keywords ***
Get the URL using the Get Secret keyword
    ${secret}=    Get Secret    robot_order_url
    RETURN    ${secret}[url]

Open the robot order website
    [Arguments]    ${URL}
    Open Available Browser    ${URL}

Ask URL of the orders CSV
    Add icon    Success
    Add heading    The URL of the orders CSV?
    Add text input    url    label=URL    placeholder=Enter URL here
    Add submit buttons    buttons=Submit
    ${result}=    Run dialog    height=400    width=800
    RETURN    ${result.url}

Get orders
    [Arguments]    ${orders_url}
    Download    ${orders_url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the popup
    Click Element If Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div

Fill the form
    [Arguments]    ${row}
    Select From List By Value    css:#head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    css:#address    ${row}[Address]

Preview the robot
    Click Button    preview
    Sleep    1s

Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot
    ...    xpath://*[@id="robot-preview-image"]
    ...    ${OUTPUT_DIR}${/}screenshots${/}screenshot_${row}[Order number].png

Submit the order
    Wait Until Keyword Succeeds    5x    1s    Click order and check if ok

Click order and check if ok
    Click Element When Visible    xpath://*[@id="order"]
    Wait Until Element Is Visible    id:order-completion    1s

Store the receipt as a PDF file
    [Arguments]    ${row}
    ${order_receipt}=    Get Element Attribute    xpath://*[@id="receipt"]    outerHTML
    Html To Pdf    ${order_receipt}    ${OUTPUT_DIR}${/}receipts${/}order_receipt_${row}[Order number].pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${row}
    ${order_receipt}=    Open Pdf    ${OUTPUT_DIR}${/}receipts${/}order_receipt_${row}[Order number].pdf
    ${screenshotPNG}=    Create List
    ...    ${OUTPUT_DIR}${/}receipts${/}order_receipt_${row}[Order number].pdf
    ...    ${OUTPUT_DIR}${/}screenshots${/}screenshot_${row}[Order number].png
    Add Files To Pdf    ${screenshotPNG}    ${OUTPUT_DIR}${/}receipts${/}order_receipt_${row}[Order number].pdf
    Close Pdf    ${order_receipt}

Go to order another robot
    Click Element When Visible    xpath://*[@id="order-another"]

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts${/}    ${OUTPUT_DIR}${/}Receipts.zip
