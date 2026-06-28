# Admin Panel Requirements: Cricket Ground Booking

## 1. Overview
The Admin Panel is a secure interface designed for platform administrators to manage the platform's ecosystem. Its primary function is to handle the moderation workflow: reviewing, accepting, or rejecting ground owner registrations and individual ground listings before they go live on the consumer app.

## 2. Design & Theme Specifications
To ensure brand consistency with the main Cricket Booking application, the Admin Panel must adhere to the following design guidelines:

*   **Aesthetic & Colors:** Use a premium, vibrant aesthetic matching the mobile app. Avoid generic, flat colors. Strictly adhere to the following palette:
    *   **Brand Colors:** Primary Dark Green (`#0B8457`), Primary Light Green (`#4CAF50`), Accent Orange (`#FF9800`), Golden Yellow (`#FFD600`).
    *   **Light Theme:** Background (`#F5F7FA`), Surface (`#FFFFFF`), Text Primary (`#212121`), Text Secondary (`#616161`), Border (`#EEEEEE`).
    *   **Dark Theme:** Background (`#121212`), Surface (`#1E1E1E`), Text Primary (`#ECEFF1`), Text Secondary (`#B0BEC5`), Border (`#2C2C2C`).
*   **Typography:** Use the **Outfit** font family (via Google Fonts) exclusively, for both headings and body text, to ensure 100% parity with the mobile app.
*   **Iconography:** Strictly use **HugeIcons** (specifically the `strokeRounded` variants, such as `strokeRoundedLocation01`) for all menu items, actions, and indicators to match the mobile app's iconography.
*   **UI Components:**
    *   **Loading States:** Use professional **skeleton loaders** instead of basic circular loading indicators for all data fetching.
    *   **Interactivity:** Incorporate subtle micro-animations (e.g., hover effects on table rows, dynamic transitions on buttons) to make the interface feel responsive and premium.
    *   **Layout:** Clean, card-based layouts for dashboards and detailed views. Keep the navigation intuitive (likely a persistent left-hand sidebar).

## 3. Core Functionalities

### 3.1 Authentication & Security
*   Secure Admin Login screen (Email/Password).
*   Session management and protected routes (unauthenticated users are redirected to login).

### 3.2 Dashboard (Home)
A high-level overview providing immediate insights into pending tasks.
*   **Quick Stat Cards (Real-time):**
    *   Total Pending Owner Registrations (Needs Action).
    *   Total Pending Ground Listings (Needs Action).
    *   Total Active Grounds.
    *   Total Registered Users/Owners.
*   **Recent Activity Feed:** A quick list of the latest submissions requiring review.

### 3.3 Ground Owner Management
The workflow for verifying individuals or businesses who want to host grounds.
*   **List View (Data Table):** 
    *   Columns: Name, Email, Phone, Date Applied, Status (Pending, Approved, Rejected).
    *   Features: Search bar, filter by Status, pagination.
*   **Detail View (Review Screen):**
    *   Displays all submitted personal and business details.
    *   Displays submitted verification documents (ID proof, business registration) with options to view full-size.
*   **Action Workflow:**
    *   **Approve:** Button to verify the owner. Updates their status in the database to allow them access to the Owner Dashboard.
    *   **Reject:** Button that opens a modal requiring a "Reason for Rejection". This reason is saved and ideally sent to the owner via email/notification.

### 3.4 Ground Listings Management
The workflow for verifying the actual cricket grounds before users can book them.
*   **List View (Data Table):**
    *   Columns: Ground Name, Owner Name, Location, Date Submitted, Status (Pending, Approved, Rejected).
    *   Features: Search bar, filter by Status.
*   **Detail View (Review Screen):** A comprehensive view of everything the end-user will see.
    *   **Media:** Image carousel of the ground.
    *   **Details:** Address, pitch type, boundary length, amenities/facilities (parking, washroom, floodlights).
    *   **Configuration:** Review the pricing structure and generated slot timings to ensure they make sense.
*   **Action Workflow:**
    *   **Approve:** Publishes the ground, making it instantly searchable and bookable on the main consumer app.
    *   **Reject:** Opens a modal for a "Reason for Rejection" (e.g., "Images are unclear", "Address is invalid"). Updates status and notifies the owner to make corrections.

### 3.5 General Management (Secondary Features)
*   **Users List:** A basic table to view all registered end-users, with the ability to suspend/ban abusive accounts.
*   **Bookings/Transactions:** A read-only master list of all bookings across all grounds for auditing and dispute resolution purposes.

## 4. Technical Integration Notes
*   **Real-time Updates:** Similar to the Owner Dashboard, the Admin Panel should ideally utilize Real-Time streams (e.g., Supabase Real-Time) so that when a new owner registers, the admin sees the pending count increment without needing to refresh the page.
*   **Database:** Actions (Approve/Reject) must cleanly update the `status` enums or flags in the respective `owners` and `grounds` database tables.
