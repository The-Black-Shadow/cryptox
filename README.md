# 🪙 CryptoX: A Secure Digital Wallet with a Traceable Ledger

**CryptoX** is a mobile financial platform built with **Flutter** and **Firebase** that redefines digital asset security through a unique, traceable **"Digital Note"** system.

This project addresses the core challenges of trust and security in digital finance. While providing users with a modern and intuitive multi-currency wallet, its main innovation is a **UTXO-style ledger** for a specific digital currency, allowing for unprecedented traceability and administrative oversight to combat fraud.

---

## ✨ Key Features

### 👤 For Users

- 🔐 **Secure Authentication**: Sign up and log in using **Email/Password** or **Google Sign-In**.
- 💼 **Multi-Currency Wallet**: Manage balances for standard cryptocurrencies (like BTC, ETH) and the new traceable **Digital Notes**.
- 💳 **Deposit Funds**: Easily add funds to the wallet via a secure **Stripe payment gateway**.
- 💸 **Send Traceable Currency**: Send Digital Notes to other users with the confidence that every transaction is recorded on an immutable ledger.
- 🔄 **Convert Assets**: Seamlessly convert between standard assets and traceable Digital Notes.
- 📜 **Transaction History**: View a complete history of all incoming and outgoing Digital Note transactions.
- ✏️ **Profile Management**: Edit personal information like username and phone number.

### 👑 For Administrators

- 🛡️ **Role-Based Access**: A separate, secure dashboard is accessible only to users with an `"admin"` role.

#### 🕵️ Forensic Tracing:

- Search for any transaction by its ID to view its complete details.
- Trace the flow of funds by clicking on a note's output to find the next transaction where it was used as an input.

#### 📊 User Financial Oversight:

- Search for any user by their email to view their complete profile and a detailed list of every Digital Note they currently own.

#### 💵 Currency Management:

- Deposit new, unique Digital Notes into any user's account.
- Block individual notes or all notes associated with a specific transaction to instantly freeze funds in response to fraud reports.

---

## ⚙️ How It Works: The Technology

**CryptoX** uses a hybrid model to provide both efficiency and security.

### 1. Hybrid Balance System

- **Account-Based Model**:  
  For standard cryptocurrencies, the system uses a simple account model where the user has a single balance field. This is efficient for non-traceable assets.

- **UTXO-Style "Parcel" Model**:  
  For our unique Digital Notes (simulating Taka), the system uses a **UTXO (Unspent Transaction Output)** model.  
  Instead of a single balance, a user's wallet contains a collection of individual "notes," each with a unique serial number and its own history.

### 2. The "Digital Central Bank" Send Logic

When a user sends Digital Notes, the system uses an intelligent, atomic transaction:

- **Exact Match**:  
  If a user sends 7 Taka and has a 5tk and two 1tk notes, the system performs a direct ownership transfer, and the notes' unique serial numbers are preserved.

- **Making Change**:  
  If a user sends 120 Taka but only has a 500tk note, the system "spends" the 500tk note and issues brand new notes totaling 120 Taka to the recipient and 380 Taka back to the sender as change.  
  The transaction ledger links the old note to the new ones, ensuring the trail is never broken.

---
## 📦 Key Packages Used

- **`flutter_bloc`**:  
  For implementing the **BLoC pattern** and managing application state.

- **`go_router`**:  
  For declarative, URL-based **navigation and routing**.

- **`firebase_core`, `firebase_auth`, `cloud_firestore`**:  
  For all **backend services**, including **authentication** and **database**.

- **`google_sign_in`**:  
  To handle the native **Google Sign-In** flow.

- **`flutter_stripe`**:  
  For secure and compliant **payment processing** for deposits.

- **`equatable`**:  
  To compare Dart objects, essential for **BLoC state management**.

- **`rxdart`**:  
  Used in the **repository layer** to combine multiple data streams.

- **`lottie`**:  
  For displaying high-quality **animations** on the splash screen.

- **`intl`**:  
  For formatting **numbers and dates** into currency and readable formats.

- **`flutter_dotenv`**:  
  For managing **secret API keys** securely.

---
## 🚀 Installation and Setup Guide

Follow these steps to set up and run the project locally.

### 🔧 Prerequisites

- Flutter SDK (version 3.0 or higher)
- A configured code editor (like VS Code or Android Studio)
- A Firebase project

### 1. Set Up Firebase 🔥

1. Create a new project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Firebase Authentication** and add the **"Email/Password"** and **"Google"** sign-in methods.
3. Enable the **Cloud Firestore** database.

#### 📑 Create Firestore Indexes

Go to **Firestore Database > Indexes > Composite** and create the following two indexes:

- **Index 1 (For Admin User Search):**  
  - Collection ID: `digital_notes`  
  - Fields: `ownerUserId (Ascending)`, `denomination (Descending)`

- **Index 2 (For User Wallet View):**  
  - Collection ID: `digital_notes`  
  - Fields: `ownerUserId (Ascending)`, `status (Ascending)`, `denomination (Descending)`

### 2 🔐 Environment Configuration

Create a `.env` file in the **root directory** of your project and add the following keys:

```env
COINGECKO_API_KEY=your api key
STRIPE_PUBLISHABLE_KEY=your api key
STRIPE_SECRET_KEY=your api key
```

### 3. Configure the Project 📂

```bash
# Clone the Repository
git clone https://github.com/The-Black-Shadow/cryptox
cd cryptox

# Get Dependencies
flutter pub get
```


