//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


/* Documentation:
 step 1 to 5configure server, connect app to the server, sende message , and read message, displaying them in the tableview
 
 step 6 and 7 are authentication with mail
 
 step 8 add google to authenticate go to Googleservices info plist and copy the REVERSE_CLIENT_ID , go to info of the app and copy it in the URL Types, then go to app delegate and continue
 
 step 9
 */



//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

// Your Google app's client ID, which can be found in the GoogleService-Info.plist file
// and is stored in the `clientID` property of your FIRApp options.
// Firebase Google auth is built on top of Google sign-in, so you'll have to add a URL
// scheme to your project as outlined at the bottom of this reference:
// https://developers.google.com/identity/sign-in/ios/start-integrating
let kGoogleAppClientID = (FIRApp.defaultApp()?.options.clientID)!

// MARK: - FCViewController

class FCViewController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: Properties
    
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 1000
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    let imageCache = NSCache<NSString, UIImage>()
    var keyboardOnScreen = false
    var placeholderImage = UIImage(named: "ic_account_circle")
    
    //Authentication variables
    fileprivate var _refHandle: FIRDatabaseHandle!
    fileprivate var _authHandle: FIRAuthStateDidChangeListenerHandle!
    var user: FIRUser?
    var displayName = "Anonymous"
    
    // MARK: Outlets
    
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var imageMessage: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var messagesTable: UITableView!
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var imageDisplay: UIImageView!
    @IBOutlet var dismissImageRecognizer: UITapGestureRecognizer!
    @IBOutlet var dismissKeyboardRecognizer: UITapGestureRecognizer!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        
        //STEP 1 check if user signed in succesfully
       // self.signedInStatus(isSignedIn: true)
        
        // TODO: Handle what users see when view loads
        //STEP 6 change the signedI method for this, because we dont want to the user signed in automatically
        //configure authentication
        configureAuth()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // MARK: Config
    
    func configureAuth() {
        // TODO: configure firebase authentication
        
        //add other authentication methods, this is an array of providers in this case we pass google
        FIRAuthUI.default()?.providers = [FIRGoogleAuthUI()]
        
        //listen for changes in authorization state
        _authHandle = FIRAuth.auth()?.addStateDidChangeListener({ (auth: FIRAuth, user: FIRUser?) in
            //refresh table data
            self.messages.removeAll(keepingCapacity: false)
            self.messagesTable.reloadData()
            
            //check if there is a current user
            if let activeUser = user {
                //check if the current app user is the current FIRuser
                if self.user != activeUser {
                    self.user = activeUser
                    self.signedInStatus(isSignedIn: true)
                    let name = user!.email!.components(separatedBy: "@")[0]
                    self.displayName = name
                }
            } else {
                //user must sigin in
                self.signedInStatus(isSignedIn: false)
                self.loginSession()
            }
        })
    }
    
    func configureDatabase() {
        // TODO: configure database to sync messages
        //connecting the app to the database
        ref = FIRDatabase.database().reference()
        //STEP 4 
        _refHandle = ref.child("messages").observe(.childAdded) { (snapshot: FIRDataSnapshot) in
            self.messages.append(snapshot)
            self.messagesTable.insertRows(at: [IndexPath(row: self.messages.count - 1, section:0)], with: .automatic)
            self.scrollToBottomMessage()
        }
    }
    
    func configureStorage() {
        // TODO: configure storage using your firebase storage
        //creating a reference of the location of the storage
        storageRef = FIRStorage.storage().reference()
    }
    
    deinit {
        // TODO: set up what needs to be deinitialized when view is no longer being used
        //STEP 8 : stop the listener for authentication changes
        ref.child("messages").removeObserver(withHandle: _refHandle)
        FIRAuth.auth()?.removeStateDidChangeListener(_authHandle)
    }
    
    // MARK: Remote Config
    
    func configureRemoteConfig() {
        // TODO: configure remote configuration settings
    }
    
    func fetchConfig() {
        // TODO: update to the current coniguratation
    }
    
    // MARK: Sign In and Out
    
    func signedInStatus(isSignedIn: Bool) {
        signInButton.isHidden = isSignedIn
        signOutButton.isHidden = !isSignedIn
        messagesTable.isHidden = !isSignedIn
        messageTextField.isHidden = !isSignedIn
        sendButton.isHidden = !isSignedIn
        imageMessage.isHidden = !isSignedIn
        
        if (isSignedIn) {
            
            // remove background blur (will use when showing image messages)
            messagesTable.rowHeight = UITableViewAutomaticDimension
            messagesTable.estimatedRowHeight = 122.0
            backgroundBlur.effect = nil
            messageTextField.delegate = self
            
            // TODO: Set up app to send and receive messages when signed in
            //STEP 2 Configure the database
            configureDatabase()
            //step 9 Configure Storage
            configureStorage()
        }
    }
    
    func loginSession() {
        //step 7 : presnet the view controller for authentication this is provided by Firebase UI framework
        let authViewController = FIRAuthUI.default()!.authViewController()
        self.present(authViewController, animated: true, completion: nil)
    }
    
    // MARK: Send Message
    
    func sendMessage(data: [String:String]) {
        // TODO: create method that pushes message to the firebase database
        //STEP 3: SEND A MESSAGE
        var mData = data
        mData[Constants.MessageFields.name] = displayName
        ref.child("messages").childByAutoId().setValue(mData)

    }
    
    func sendPhotoMessage(photoData: Data) {
        // TODO: create method that pushes message w/ photo to the firebase database
        //first we need to build a path using the user's ID and a timestamp
        let imagePath = "chat_photos/" + FIRAuth.auth()!.currentUser!.uid + "/\(Double(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        //second set content type to "image/jpeg" in forebase storage meta data
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        //third create a child node at imagePath whith photoData and metadate
        //this is what sends the data to the storage
        storageRef!.child(imagePath).put(photoData, metadata:metadata) { (metadata, error) in
            
            if let error = error {
                print("error uploading: \(error)")
                return
            }
            //finally send the mesage url to the database to display the photo in the tableview
            self.sendMessage(data: [Constants.MessageFields.imageUrl: self.storageRef!.child((metadata?.path)!).description])
            
        }
    }
    
    // MARK: Alert
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Scroll Messages
    
    func scrollToBottomMessage() {
        if messages.count == 0 { return }
        let bottomMessageIndex = IndexPath(row: messagesTable.numberOfRows(inSection: 0) - 1, section: 0)
        messagesTable.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
    }
    
    // MARK: Actions
    
    @IBAction func showLoginView(_ sender: AnyObject) {
        loginSession()
    }
    
    @IBAction func didTapAddPhoto(_ sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func signOut(_ sender: UIButton) {
        do {
            try FIRAuth.auth()?.signOut()
        } catch {
            print("unable to sign out: \(error)")
        }
    }
    
    @IBAction func didSendMessage(_ sender: UIButton) {
        let _ = textFieldShouldReturn(messageTextField)
        messageTextField.text = ""
    }
    
    @IBAction func dismissImageDisplay(_ sender: AnyObject) {
        // if touch detected when image is displayed
        if imageDisplay.alpha == 1.0 {
            UIView.animate(withDuration: 0.25) {
                self.backgroundBlur.effect = nil
                self.imageDisplay.alpha = 0.0
            }
            dismissImageRecognizer.isEnabled = false
            messageTextField.isEnabled = true
        }
    }
    
    @IBAction func tappedView(_ sender: AnyObject) {
        resignTextfield()
    }
}

// MARK: - FCViewController: UITableViewDelegate, UITableViewDataSource

extension FCViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeue cell
        let cell: UITableViewCell! = messagesTable.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
        //STEP 5: TODO: update cell to display message data
        //unpack message from firebase data snapshot
        let messageSnapshot : FIRDataSnapshot! = messages[indexPath.row]
        let message = messageSnapshot.value as! [String:String]
        let name = message[Constants.MessageFields.name] ?? "[username]"
        
        //STEP 11 SETUP TABLEVIEW T DISPLAY IMAGE
        //if photo Message, then grab image and display it
        if let imageUrl = message[Constants.MessageFields.imageUrl] {
            cell!.textLabel?.text = "sent by: \(name)"
            //download and display image, with the url we create a reference to a particular image
            FIRStorage.storage().reference(forURL: imageUrl).data(withMaxSize: INT64_MAX, completion: { (data, error) in
                
                guard error == nil else {
                    print("error downloading: \(error!)")
                    return
                }
                //display image creating an image with the data
                let messagImage = UIImage.init(data: data! , scale:50)
                if cell == tableView.cellForRow(at: indexPath) {
                    DispatchQueue.main.async {
                        cell.imageView?.image = messagImage
                        cell.setNeedsLayout()
                    }
                }
            })
            
        } else {//if not message URL so its just a message
            let text = message[Constants.MessageFields.text] ?? "[message]"
            cell!.textLabel?.text = name + ": " + text
            cell!.imageView?.image = self.placeholderImage
        }

        return cell!

    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // skip if keyboard is shown
        guard !messageTextField.isFirstResponder else { return }
        // unpack message from firebase data snapshot
        let messageSnapshot: FIRDataSnapshot! = messages[(indexPath as NSIndexPath).row]
        let message = messageSnapshot.value as! [String: String]
        // if tapped row with image message, then display image
        if let imageUrl = message[Constants.MessageFields.imageUrl] {
            if let cachedImage = imageCache.object(forKey: imageUrl as NSString) {
                showImageDisplay(cachedImage)
            } else {
                FIRStorage.storage().reference(forURL: imageUrl).data(withMaxSize: INT64_MAX){ (data, error) in
                    guard error == nil else {
                        print("Error downloading: \(error!)")
                        return
                    }
                    self.showImageDisplay(UIImage.init(data: data!)!)
                }
            }
        }
    }
    
    // MARK: Show Image Display
    
    func showImageDisplay(_ image: UIImage) {
        dismissImageRecognizer.isEnabled = true
        dismissKeyboardRecognizer.isEnabled = false
        messageTextField.isEnabled = false
        UIView.animate(withDuration: 0.25) {
            self.backgroundBlur.effect = UIBlurEffect(style: .light)
            self.imageDisplay.alpha = 1.0
            self.imageDisplay.image = image
        }
    }
    
    // MARK: Show Image Display
    
    func showImageDisplay(image: UIImage) {
        dismissImageRecognizer.isEnabled = true
        dismissKeyboardRecognizer.isEnabled = false
        messageTextField.isEnabled = false
        UIView.animate(withDuration: 0.25) {
            self.backgroundBlur.effect = UIBlurEffect(style: .light)
            self.imageDisplay.alpha = 1.0
            self.imageDisplay.image = image
        }
    }
}

// MARK: - FCViewController: UIImagePickerControllerDelegate

extension FCViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:Any]) {
        // constant to hold the information about the photo
        if let photo = info[UIImagePickerControllerOriginalImage] as? UIImage, let photoData = UIImageJPEGRepresentation(photo, 0.8) {
            //STEP 10  call function to upload photo message
            sendPhotoMessage(photoData: photoData)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - FCViewController: UITextFieldDelegate

extension FCViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // set the maximum length of the message
        guard let text = textField.text else { return true }
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= msglength.intValue
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !textField.text!.isEmpty {
            let data = [Constants.MessageFields.text: textField.text! as String]
            sendMessage(data: data)
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: Show/Hide Keyboard
    
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen {
            self.view.frame.origin.y -= self.keyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            self.view.frame.origin.y += self.keyboardHeight(notification)
        }
    }
    
    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
        dismissKeyboardRecognizer.isEnabled = true
        scrollToBottomMessage()
    }
    
    func keyboardDidHide(_ notification: Notification) {
        dismissKeyboardRecognizer.isEnabled = false
        keyboardOnScreen = false
    }
    
    func keyboardHeight(_ notification: Notification) -> CGFloat {
        return ((notification as NSNotification).userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.height
    }
    
    func resignTextfield() {
        if messageTextField.isFirstResponder {
            messageTextField.resignFirstResponder()
        }
    }
}

// MARK: - FCViewController (Notifications)

extension FCViewController {
    
    func subscribeToKeyboardNotifications() {
        subscribeToNotification(.UIKeyboardWillShow, selector: #selector(keyboardWillShow))
        subscribeToNotification(.UIKeyboardWillHide, selector: #selector(keyboardWillHide))
        subscribeToNotification(.UIKeyboardDidShow, selector: #selector(keyboardDidShow))
        subscribeToNotification(.UIKeyboardDidHide, selector: #selector(keyboardDidHide))
    }
    
    func subscribeToNotification(_ name: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
