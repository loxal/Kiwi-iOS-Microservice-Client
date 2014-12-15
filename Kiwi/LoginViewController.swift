//  Copyright 2014 Alexander Orlov <alexander.orlov@loxal.net>. All rights reserved.

import UIKit
import LocalAuthentication

class LoginViewController: UIViewController, FBLoginViewDelegate {
    
    @IBOutlet var fbLoginView : FBLoginView!
    @IBOutlet var email: UITextField?
    @IBOutlet var password: UITextField?
    @IBOutlet var signupStatus: UILabel?
    @IBOutlet var loginChoiceHint: UILabel?
    @IBOutlet var yLogo: UIImageView?
    @IBOutlet var customer: UIImageView?
    @IBOutlet var signupDescription: UITextView?
    @IBOutlet var logout: UIButton?
    @IBOutlet var yLogin: UIButton?
    
    var projectId = "kiwi"
    var customerServiceBaseUrl: String = "https://api.yaas.io/customer/v6/kiwi/"
    
    @IBAction
    func authenticate(sender : AnyObject) {
        let touchIDContext = LAContext()
        let reasonString = "Login"
        var touchIDError : NSError?
        
        if touchIDContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &touchIDError) {
            touchIDContext.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: {
                (success: Bool, error: NSError?) -> Void in
                if success {
                    self.shop()
                } else {
                    NSLog("Failure")
                    self.signupDescription!.text = "Finger print is invalid."
                }
            })
        } else {
            self.shop()
            NSLog("Touch ID Failure")
            self.signupDescription!.text = "Finger print is invalid!"
        }
    }
    
    func shop() {
        NSLog("Success")
        if let hat = Auth.accessToken {
            let url = NSURL(string: "\(self.customerServiceBaseUrl)login")
            let request = NSMutableURLRequest(URL: url!)
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(hat)", forHTTPHeaderField: "Authorization")
            request.HTTPMethod = "POST"
            
            let payload = "{\"email\": \"\(self.email!.text)\", \"password\": \"\(self.password!.text)\"}"
            NSLog(payload)
            let payloadData = (payload as String).dataUsingEncoding(NSUTF8StringEncoding)
            request.HTTPBody = payloadData
            
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                (response, data, error) in
                NSLog(NSString(data: data, encoding: NSUTF8StringEncoding)!)
                var errror: NSError?
                let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &errror) as Dictionary<String, AnyObject>
                
                let response = json as Dictionary<String, AnyObject>
                if response.keys.array.count == 1 {
                    if let yAccessToken:String = json["accessToken"] as String? {
                        self.switchToLoggedInView(yAccessToken)
                    }
                    else {
                        NSLog("No access token could be obtained")
                    }

                } else {
                    NSLog("Wrong password")
                    var alert = UIAlertController(title: "Login Failed", message: "Invalid credentials have been provided.", preferredStyle: UIAlertControllerStyle.Alert)
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
                        switch action.style{
                        case .Default:
                            println("default")
                            
                        case .Cancel:
                            println("cancel")
                            
                        case .Destructive:
                            println("destructive")
                        }
                    }))
                }
                
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("Do any additional setup after loading the view, typically from a nib.")
        
        logoutOfFacebook()
        
        getAnonymousAccessToken()
        self.signupDescription!.text = ""
        
        self.fbLoginView.delegate = self
    }
    
    func loginViewShowingLoggedInUser(loginView : FBLoginView!) {
        println("User Logged In")
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
        if let yAccessToken = Auth.accessToken {
            
            let session: FBSession? = FBSession.activeSession()
            NSLog("\(session?.accessTokenData)")
            NSLog("Apigee access token: \(Auth.accessToken)")
            
            
            println("User: \(user)")
            println("User ID: \(user.objectID)")
            println("User Name: \(user.name)")
            
            let url = NSURL(string: "\(self.customerServiceBaseUrl)login/facebook")
            let request = NSMutableURLRequest(URL: url!)
            
            NSLog("hybris access token \(Auth.accessToken!)")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(Auth.accessToken!)", forHTTPHeaderField: "Authorization")
            request.HTTPMethod = "POST"
            
            let accessToken = session?.accessTokenData
            
            let payload = "{\"accessToken\": \"\(accessToken!)\"}"
            let payloadData = (payload as String).dataUsingEncoding(NSUTF8StringEncoding)
            request.HTTPBody = payloadData
            
            
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                (response, data, error) in
                NSLog(NSString(data: data, encoding: NSUTF8StringEncoding)!)
                var errror: NSError?
                let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &errror) as Dictionary<String, AnyObject>
                
                let hybrisAccessToken: String = json["accessToken"] as String
                
                self.switchToLoggedInView(hybrisAccessToken)
            }
        } else {
            getAnonymousAccessToken()
        }
    }
    
    func switchToLoggedInView(yAccessToken: String){
        email?.hidden = true
        password?.hidden = true
        
        logout?.setTitle("Log out", forState: UIControlState.Normal)
        logout?.hidden = false
        self.fbLoginView?.hidden = true
        self.yLogin?.hidden = true
        
        yLogo?.hidden = true
        loginChoiceHint?.hidden = true
        
        signupDescription?.hidden = false
        customer?.hidden = false
        
        showProfile(yAccessToken)
    }
    
    @IBAction
    func switchToLoggedOutView(){
        logoutOfFacebook()
        
        email?.hidden = false
        password?.hidden = false
        
        logout?.hidden = true
        self.fbLoginView?.hidden = false
        self.yLogin?.hidden = false
        
        yLogo?.hidden = false
        loginChoiceHint?.hidden = false
        
        signupDescription?.hidden = true
        signupDescription?.text = ""
        customer?.hidden = true
    }
    
    func logoutOfFacebook(){
        let session: FBSession? = FBSession.activeSession()
        session?.closeAndClearTokenInformation()
    }
    
    
    func getAnonymousAccessToken(){
        let url = NSURL(string: "https://api.yaas.io/account/v1/auth/anonymous/login?hybris-tenant=\(projectId)")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
            (response, data, error) in
            NSLog(NSString(data: data, encoding: NSUTF8StringEncoding)!)
            var errror: NSError?
            if let httpResponse = response as? NSHTTPURLResponse {
                if (httpResponse.statusCode == 200) {
                    let responseLocation = httpResponse.allHeaderFields["location"] as NSString
                    let authtoken: AnyObject = responseLocation.componentsSeparatedByString("&access_token=").reverse()[0].componentsSeparatedByString("&")[0]
                    
                    Auth.accessToken = authtoken as? String
                    NSLog("yAccessToken: \(Auth.accessToken!)")
                }
                else {
                    self.signupDescription!.text = "Error retrieving authentication token: \(httpResponse.statusCode)"
                }
            }
            
        }
    }
    
    func showProfile(yAccessToken: String?) {
        if let hat = yAccessToken {
            let url = NSURL(string: "\(self.customerServiceBaseUrl)me")
            let request = NSMutableURLRequest(URL: url!)
            
            request.addValue("Bearer \(hat)", forHTTPHeaderField: "Authorization")
            request.HTTPMethod = "GET"
            
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                (response, data, error) in
                NSLog(NSString(data: data, encoding: NSUTF8StringEncoding)!)
                var errror: NSError?
                let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &errror) as Dictionary<String, AnyObject>
                
                let customerNumber: String = json["customerNumber"] as String
                if let temp = customerNumber.rangeOfString("C00000000") {
                    self.signupDescription!.text = "Not logged in yet."
                } else {
                    let preferredLanguage: String = json["preferredLanguage"] as String
                    let preferredCurrency: String = json["preferredCurrency"] as String
                    self.signupDescription!.text = "ID: \(customerNumber)\nPreferred Language: \(preferredLanguage)\nPreferred Currency: \(preferredCurrency)\n\n\nUsed hybris Access Token:\n\t\(hat)"
                }
            }
        }
    }
    
    
    struct Auth {
        static var accessToken : NSString?
        static var yAccessToken : NSString?
    }
    
    func loginViewShowingLoggedOutUser(loginView : FBLoginView!) {
        println("User Logged Out")
    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError) {
        println("Error: \(handleError.localizedDescription)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        NSLog("Dispose of any resources that can be recreated.")
    }
}