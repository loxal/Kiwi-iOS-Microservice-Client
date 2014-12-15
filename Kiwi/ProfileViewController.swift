//  Copyright 2014 Alexander Orlov <alexander.orlov@loxal.net>. All rights reserved.

import UIKit

class ProfileViewController: UIViewController, FBLoginViewDelegate {
    
    
    var uuu: String = "test"
    let customerServiceBaseUrl: String = "https://yaas-test.apigee.net/test/customer/v4/"
    var perimeter: String {
        get {
            return "oha"
        }
        set {
            uuu = ""
        }
    }
    
    override    func viewDidAppear(animated: Bool){
        super.viewDidAppear(true)
        NSLog("INIT once")
        
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("LOAD once!")
    }
    
    @IBAction
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
        NSLog("Log out pressed.")
        let session: FBSession? = FBSession.activeSession()
        session?.closeAndClearTokenInformation()
        
        self.tabBarController?.selectedIndex = 0
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