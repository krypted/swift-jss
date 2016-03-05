//
//  ViewController.swift
//  JSS Buildings
//

import Cocoa
import Foundation

class ViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        //  talk to registration end point
        
        
        // Do any additional setup after loading the view.
    }
    
    // Alert Functions
    func alertGen(infoText: String, msgText: String) {
        let alert = NSAlert()
        alert.informativeText = msgText
        alert.messageText = infoText
        alert.addButtonWithTitle("Ok")
        alert.runModal()
    }
    
    //
    // UI Fields
    //
    
    @IBOutlet weak var jssUrl: NSTextField!
    @IBOutlet weak var labelfield: NSTextFieldCell!
    
    @IBOutlet weak var jssUserName: NSTextField!
    @IBOutlet weak var jssPass: NSSecureTextField!
    
    @IBOutlet weak var jssGroupName: NSTextField!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var jssSiteSelector: NSPopUpButtonCell!
    @IBOutlet weak var textBox: NSScrollView!
    
    
    @IBOutlet weak var computersButtonOutlet: NSButton!

    @IBOutlet weak var mobileDevicesButtonOutlet: NSButton!
    
    //
    // UI Radio Buttons
    //
    
    @IBAction func computersButton(sender: AnyObject) {
        print("Computers Selected")
        mobileDevicesButtonOutlet.state = 0
    }
    
    @IBAction func mobileDevicesButton(sender: AnyObject) {
        print("Mobile Devices Selected")
        computersButtonOutlet.state = 0
    }
 
    @IBOutlet var textViewOutlet: NSTextView!
    
    //
    //
    // Action for Get Sites Button
    //
    //
    
    @IBAction func jssGetSiteButton(sender: AnyObject) {
        
        func getJSSSites() {
            
            jssSiteSelector.selectItemWithTitle("None")
            // Function Variables
            let sitesUrl = jssUrl.stringValue + "/JSSResource/sites"
            
            let jssSites = Just.get(sitesUrl, headers: ["accept":"application/json"], auth: (jssUserName.stringValue,jssPass.stringValue))
            
            
            if (jssSites.ok) {
                // Success Function
                print("JSS Site Status: \(jssSites.statusCode)")

                if let jssArray = jssSites.json!.valueForKey("sites") {
                    
                    let loopCount: Int = jssArray.count
                    
                    for var index = 0; index < loopCount; ++index {
                        let result = jssArray[index]
                        let resultName: String = String(jssArray[index]!.valueForKey("name")!)
                        jssSiteSelector.insertItemWithTitle(resultName, atIndex: index)
                        print("WTH \(result)")
                    }
                }
                
                // Keeping these here so I remember they exist
                //print(jssSites.json!.valueForKey("sites")!.valueForKey("id"))
                //print(jssSites.json!.valueForKey("sites")!.valueForKey("name"))
                
            }
            else {
                alertGen("Unable to connect to your JSS!", msgText: "Please check that the JSS URL, username and password are correct and then try your request again.")
            } // Close Else
            
            let jssSitesResult = jssSites.text!.dataUsingEncoding(NSUTF8StringEncoding)!

            do {
                // Try parsing some valid JSON
                let parsed: NSDictionary = try NSJSONSerialization.JSONObjectWithData(jssSitesResult, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                print(parsed)
            }
            catch let error as NSError {
                // Catch fires here, with an NSErrro being thrown from the JSONObjectWithData method
                print("A JSON parsing error occurred, here are the details:\n \(error)")
            } // End Catch
        } // End getJSSSites function
        
        getJSSSites()
        jssSiteSelector.selectItemAtIndex(0)
    }
    
    //
    //
    // Action for Process Group button
    //
    //
    
    @IBAction func getInfo(sender: AnyObject) {
        
        // Get the selected Radio Button values
        let computersButton = computersButtonOutlet.integerValue
        print("JSS Computers Button: \(computersButton)")
        let mobileDevicesButton = mobileDevicesButtonOutlet.integerValue
        
        // Deal with list of Serial Numbers. Break apart and new line.
        let serialtextString = textViewOutlet.string!
        let textSeperators = NSCharacterSet.newlineCharacterSet()
        let serialTextArray = serialtextString.componentsSeparatedByCharactersInSet(textSeperators)
        
        // URL Variables
        
        let buildingsUrl = jssUrl.stringValue + "/JSSResource/buildings"
        
        // Get the selected Site from Drop-down
        var jssSelectedSite = String(jssSiteSelector.selectedItem!.title)
        
        func checkSite() -> AnyObject {
            if jssSelectedSite == "None" {
                print("No Site Selected.")
                let parsedSiteID = "-1"
                return parsedSiteID
                
            }
            else {
                print("JSS Selected Site: \(jssSelectedSite)")
                
                let siteUrl = jssUrl.stringValue + "/JSSResource/sites/name/" + jssSelectedSite
                
                // Perform GET on Sites to see what you've got
                
                let siteIDGet = Just.get(siteUrl, headers: ["accept":"application/json"], auth: (jssUserName.stringValue,jssPass.stringValue))
                
                //
                // If Site GET is OK, return the ID, else return "siteCheckFailed"
                //
                
                
                    if siteIDGet.ok {
                        print("Site ID Get URL: \(siteUrl)")
                        let parsedSiteID = siteIDGet.json!.valueForKey("site")!.valueForKey("id")!
                        return String(parsedSiteID)
                    }
                    else {
                        alertGen("Cannot Get Site Info", msgText: "There was an error getting the site ID. Check your network connection and try again.")
                        return "siteCheckFailed"
                    }
            }
        
        }
        
        //
        // Main logic 
        //
        
        func mainLogic() {
            if (computersButton == 0 && mobileDevicesButton == 0) {
                alertGen("Select Group Type", msgText: "Please select if you are creating a static mobile or computer group")
            }
            else if (computersButton == 1 && mobileDevicesButton == 0) {
                let groupUrl = jssUrl.stringValue + "/JSSResource/computergroups/name/"
                print("Computers button selected")
                let check = checkSite()
                print("Check Site Result: \(check)")
                let jssXML: NSXMLDocument = buildJssComputerStaticGroup(check as! String, jssSite: jssSelectedSite as String)!
                let jssGroupExists: String = checkJSSGroup(jssGroupName.stringValue, jssGroupURL: groupUrl)
                jssGroupLogic(jssGroupExists, xml: jssXML, jssReqURL: groupUrl)
                //let jssLogic = jssGroupLogic(jssGroupExists, xml: jssXML!)
            }
            else if (computersButton == 0 && mobileDevicesButton == 1) {
                let groupUrl = jssUrl.stringValue + "/JSSResource/mobiledevicegroups/name/"

                print("Mobile Devices Button Selected")
                let check = checkSite()
                print("Check Site: \(check)")
                let jssXML: NSXMLDocument = buildJssMobileStaticGroup(check as! String, jssSite: jssSelectedSite as String)!
                let jssGroupExists: String = checkJSSGroup(jssGroupName.stringValue, jssGroupURL: groupUrl)
                jssGroupLogic(jssGroupExists, xml: jssXML, jssReqURL: groupUrl)
                //print("jssXML \(jssXML.XMLData)")
                print("Logic Done")
                }
                
            }
        
        
        //
        // Build a Static Mobile Device Group
        //
        
        func buildJssMobileStaticGroup(jssID: String, jssSite: String) -> NSXMLDocument? {
            // Build the Static Group XML. I should probably make this a function
            let xmlRoot = NSXMLElement(name: "mobile_device_group")
            let xmlDoc = NSXMLDocument(rootElement: xmlRoot)
            
            xmlRoot.addChild(NSXMLElement(name: "name", stringValue:jssGroupName.stringValue))
            xmlRoot.addChild(NSXMLElement(name: "is_smart", stringValue:"false"))
            
            let xmlSite = NSXMLElement(name: "site")
            xmlSite.addChild(NSXMLElement(name: "id", stringValue: jssID ))
            xmlSite.addChild(NSXMLElement(name: "name", stringValue: jssSite))
            xmlRoot.addChild(xmlSite)
            
            let xmlDevices = NSXMLElement(name: "mobile_devices")
            
            // Loop through each serial in the text array
            
            for entry in serialTextArray {
                
                let xmlDevice = NSXMLElement(name: "mobile_device")
                xmlDevice.addChild(NSXMLElement(name: "serial_number", stringValue:entry))
                xmlDevices.addChild(xmlDevice)
                
            }
            
            // Finialize it with list of devices
            xmlRoot.addChild(xmlDevices)

            //print("XML String: \(xmlDoc.XMLString)")
            //print("XML Doc: \(xmlDoc.XMLData)")
            
            return xmlDoc
           
        } // Close buildJssMobileStaticGroup
        
        //
        // Build a Static Computer Group
        //
        
        func buildJssComputerStaticGroup(jssID: String, jssSite: String) -> NSXMLDocument? {
            // Build the Static Group XML. I should probably make this a function
            let xmlRoot = NSXMLElement(name: "computer_group")
            let xmlDoc = NSXMLDocument(rootElement: xmlRoot)
            
            xmlRoot.addChild(NSXMLElement(name: "name", stringValue:jssGroupName.stringValue))
            xmlRoot.addChild(NSXMLElement(name: "is_smart", stringValue:"false"))
            
            let xmlSite = NSXMLElement(name: "site")
            xmlSite.addChild(NSXMLElement(name: "id", stringValue: jssID ))
            xmlSite.addChild(NSXMLElement(name: "name", stringValue: jssSite))
            xmlRoot.addChild(xmlSite)
            
            let xmlDevices = NSXMLElement(name: "computers")
            
            // Loop through each serial in the text array
            
            for entry in serialTextArray {
                
                let xmlDevice = NSXMLElement(name: "computer")
                xmlDevice.addChild(NSXMLElement(name: "serial_number", stringValue:entry))
                xmlDevices.addChild(xmlDevice)
                
            }
            
            // Finialize it with list of devices
            xmlRoot.addChild(xmlDevices)
            
            // Print XML Document
            //print("XML String: \(xmlDoc.XMLString)")
            //print("XML Doc: \(xmlDoc.XMLData)")
            
            return xmlDoc
            
        } // Close buildJssComputerStaticGroup

        
        
        
        //
        // Function to check if Group Exists
        //
        
        func checkJSSGroup(groupName: String, jssGroupURL: String) -> String {
            print("GroupName: \(groupName)")
            
            if groupName.isEmpty {
                // Action to take if no group name was entered.
                print("No Group Name Entered. Exiting")
                
                // Generate an Alert to tell them what they've done
                alertGen("Error: No Group Name", msgText: "Please enter a group before getting click-happy!")
                return "nil"
            }
            else {
                
                //let checkUrl = groupUrl + groupName
                let groupCheck = Just.get(jssGroupURL, auth: (jssUserName.stringValue,jssPass.stringValue))
                
                //print("Check URL: \(checkUrl)")
                print("Group Check: \(groupCheck)")
                
                if (groupCheck.statusCode == 200) {
                    print("Group Check - Exists")
                    return "true"
                }
                else {
                    print("Group Check - Does NOT Exist")
                    return "false"
                }
            } // Closing nil else Check
            
        } // Closing checkJssGroup Function
        
        
        //
        // Function to Submit the group successfully
        //
        
        func jssGroupLogic(jssGroupExists: String, xml: NSXMLDocument, jssReqURL: String) {
            
            print("JSS Group Logic XMLData: \(xml.XMLString)")
            
            // Logic if group return exists
            if (jssGroupExists == "true") {
                // Actions to take if group DOES exist. E.g. PUT
                print("Group exists, we will need to put")
                
                let jssGroupNameEscaped = (jssGroupName.stringValue).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                let jssGroupUrl = jssReqURL + jssGroupNameEscaped!
                //print("JSSGroup Exists URL: \(jssGroupUrl)")
                
                let jssGroupPut = Just.put(jssGroupUrl, auth: (jssUserName.stringValue,jssPass.stringValue), requestBody: xml.XMLData)
                
                print("JSSPUT Req: \(jssGroupPut.statusCode)")
                
                // Put Result Logic
                if (jssGroupPut.statusCode == 201) {
                    alertGen("Update Successful", msgText: "Group Updated")
                    labelfield.stringValue = String(jssGroupPut.statusCode!)
                }
                else {
                    alertGen("Hey, this is free software. What did you expect?", msgText: "Something unexpected happend.")
                    labelfield.stringValue = String(jssGroupPut.statusCode!)
                }
            } // Close if
            else if (jssGroupExists == "nil") {
                // Actions to take if Group Name was Empty
                print("No Group name was entered. No actions taken. (Other than this one)")
            }
            else {
                // Actions to take if gropu doesn't Exist. E.g. POST
                print("Group Does NOT exist, we will need to post")
                
                
                if (serialTextArray[0].isEmpty) {
                    alertGen("Serial Number Missing.", msgText: "Please enter at least one serial number")
                }
                else {
                    let jssGroupNameEscaped = (jssGroupName.stringValue).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                    let jssGroupUrl = jssReqURL + jssGroupNameEscaped!
                    //print("JSS Post Group URL: \(jssPostGroupUrl)")
                    let jssGroupPost = Just.post(jssGroupUrl, headers: ["Content-Type":"text/xml"] ,auth: (jssUserName.stringValue,jssPass.stringValue), requestBody: xml.XMLData )
                    
                    print("JSS Post Request: \(jssGroupPost.headers)")
                    
                    print("JSS Post Status Code: \(jssGroupPost.statusCode)")
                    
                    // Put Result Logic
                    if (jssGroupPost.statusCode == 201) {
                        alertGen("Update Successful", msgText: "Group Updated")
                        labelfield.stringValue = String(jssGroupPost.statusCode!)
                    }
                    else {
                        alertGen("Update Failed", msgText: "If using sites, make sure all computers are site enabled for the selected location. Hint: Try 'None'")
                        
                        labelfield.stringValue = String(jssGroupPost.statusCode!)
                        print(jssGroupPost.response)
                    }
                }
            }
        }
        
        mainLogic()
        
    }
    
    @IBOutlet weak var clickedField: NSTextField!
    
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
}

