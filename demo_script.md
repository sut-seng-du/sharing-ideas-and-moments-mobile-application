# SIM (Sharing Ideas and Moments) - 5 Minute Demo Script

**Estimated Time:** ~5 minutes
**Pacing:** Speak at a normal, steady pace. Allow time to demonstrate the actions on screen.

---

## 1. Greeting & Introduction

**(Visual: Open the app. Show the Home Screen.)**

**Speaker:** 
"Hello! My name is Sut Seng Du and today I am going to present for Module Code 7CC012, Mobile Application Development. I developed an application called SIM, which stands for Sharing Ideas and Moments. This is a personal diary app that lets you easily share your favorite moments. I built this app using Flutter, a technology that lets us create really smooth and beautiful screens."

---

## 2. Open App & UI Design

**(Visual: Show the home screen, point to the buttons and search bar.)**

**Speaker:** 
"Let's look at the user interface. I deliberately chose not to use standard flat buttons. Instead, I built a custom **Claymorphism** design. 
The best part is that this app is built to work completely offline. You don't need the internet to save your thoughts, meaning it's super fast and your data stays safe on your phone."

---

## 3. Create a Post

**(Visual: Turn off Wi-Fi on the device. Tap the '+' button to create a new post.)**

**Speaker:** 
"Let’s create a new post. I am turning off my Wi-Fi right now, which is perfect for when you are traveling or have a bad connection. 
Using the Image Picker package, you can grab multiple photos from your gallery at once, but my app only supports a maximum of 4 photos due to X's policy, which only allows 4 media items per post."

**(Visual: Select photos, type a title, and tap 'Save'.)**

**Speaker:** 
"When I tap Save, it saves instantly. Under the hood, we use a database technology called 'sqflite'. It acts like a secure filing cabinet built right into your phone, keeping all your text and photos safe without needing an internet connection."

---

## 4. Search & Details

**(Visual: Tap the search bar and type a word to filter posts.)**

**Speaker:** 
"As you add more memories, it's easy to find them. Because our sqflite database lives right on your phone, searching through your posts is incredibly fast and completely private."

**(Visual: Tap on a post to open the Details Screen.)**

**Speaker:** 
"From here, you can also share, edit, and delete."

---

## 5. Feedback Implementation & Delete

**(Visual: Go back to Home Screen. Rotate the phone to Landscape mode.)**

**Speaker:** 
"During development, I got some feedback. When you rotate the phone to landscape mode, the navigation space takes up a lot of room and you can't see the posts. To fix this, I hid the SIM title.

**(Visual: Rotate back to Portrait. Long-press to select multiple posts. Tap Delete, then tap Undo.)**

**Speaker:** 
"Another piece of feedback: at first, my app didn't include an undo button after deleting. After receiving feedback, I added it to prevent accidentally misclicking the delete button. 
If you need to clean up, you can long-press to select multiple posts and tell the database to delete them all at once. The app also cleans up empty categories automatically so your menus don't get cluttered."

---

## 6. Challenge: Share to X

**(Visual: Open a post and tap the 'Upload on X' rocket button. Make sure Wi-Fi is back on.)**

**Speaker:** 
"One of my biggest challenges while developing this app was uploading to the X API. At first I couldn't figure out the problem. Due to the new policy of the X API, they no longer provide a free basic API service, and I needed to buy at least $5 of credit to use it. After I bought it, it uploaded smoothly.

To make this happen securely, we used the Twitter API and a secure login method called OAuth. This creates a safe bridge between your private app and your public profile. If your internet is slow, our code chops large images into smaller pieces and sends them carefully so the upload doesn't break."

**(Visual: Wait for the success message.)**

**Speaker:** 
"When it’s done, a green checkmark appears, letting you know for sure that your memory is now safely shared online."

---

## 7. Conclusion

**Speaker:** 
"SIM gives you a beautiful, private space to write down your thoughts. By combining Flutter for a smooth design, sqflite for offline storage, and secure APIs for sharing, we’ve built an app that is fast, safe, and reliable. Thank you for your time!"
