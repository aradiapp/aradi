# Fix Admin User Issue

## Current Problem
- `6@gmail.com` and `admin@aradi.com` share the same UID: `rwxZSw0JM0hyN0zmIAJJIxipBR13`
- This causes `6@gmail.com` to get admin privileges

## Solution Steps

### 1. Delete Current Admin
**Firebase Console → Authentication → Users**
- Find `admin@aradi.com` (UID: `rwxZSw0JM0hyN0zmIAJJIxipBR13`)
- Delete it

**Firebase Console → Firestore Database → Data**
- Go to `users` collection
- Delete document with ID `rwxZSw0JM0hyN0zmIAJJIxipBR13`

### 2. Delete 6@gmail.com
**Firebase Console → Authentication → Users**
- Find `6@gmail.com` (UID: `rwxZSw0JM0hyN0zmIAJJIxipBR13`)
- Delete it

### 3. Create New Admin
**Use the app:**
- Email: `admin@aradi.com`
- Password: `Aradi1992`
- The app will automatically create the admin user

### 4. Create New 6@gmail.com
**Firebase Console → Authentication → Users**
- Click "Add user"
- Email: `6@gmail.com`
- Password: `123456` (or whatever you want)
- Note the new UID

**Firebase Console → Firestore Database → Data**
- Go to `users` collection
- Create new document with the new UID
- Set role to `developer`

## Admin Credentials
- Email: `admin@aradi.com`
- Password: `Aradi1992`
- Name: `Admin`
