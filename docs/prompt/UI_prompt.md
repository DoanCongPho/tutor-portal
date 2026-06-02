# Mobile UI/UX Design Prompt — Tutor Matching Platform

Design a complete mobile-first UI/UX system for a Tutor Matching Platform.

The platform serves four user roles:

1. Parent
2. Tutor
3. Student
4. Admin (internal only, not part of mobile app v1)

The goal is to help parents discover and book verified tutors, allow tutors to manage schedules and learning materials, and provide students with a learning portal for assignments and educational content.

---

## Design Style

Create a modern, premium, friendly, trustworthy educational marketplace.

Visual personality:

* Warm
* Human-centered
* Bright
* Professional
* Not corporate
* Not childish

The visual design should feel similar in quality to:

* Airbnb
* Headway
* Duolingo (without playful illustrations)
* Notion Calendar
* Stripe mobile interfaces

Use generous spacing and clean layouts.

---

## Brand System

Primary Color:
#FF6F3C (Coral Orange)

Background:
#FFFAF6 (Warm Cream)

Dark Mode:
#1A1410

Typography:

* Large bold headings
* Clean modern sans-serif
* Strong readability
* Vietnamese language friendly

Corner Radius:

* Inputs: 12px
* Buttons: 14px
* Cards: 16px
* Bottom Sheets: 24px

Spacing Scale:
4, 8, 12, 16, 20, 24, 32, 40, 48, 64

Important Rule:
Use the coral primary color only for the main CTA on each screen.

---

# Responsive Requirements

Design for:

* iPhone 15 Pro
* iPhone 15 Pro Max
* Android 6.5" phones
* Tablets

All screens must be fully responsive.

For tablet:

* Center content
* Maximum content width 480px
* Use adaptive layouts

---

# Navigation Structure

## Parent App

Bottom Navigation

Home
Search
Bookings
Wallet
Profile

---

## Tutor App

Bottom Navigation

Home
Schedule
Students
Wallet
Profile

---

## Student App

Bottom Navigation

Home
Materials
Assignments
Profile

---

# Authentication Flow

Design:

1. Welcome Screen
2. Login
3. Registration
4. Role Selection
5. Forgot Password

Requirements:

* Large hero headline
* Brand mark at top
* Friendly onboarding experience
* Full-screen mobile layout

---

# Parent Experience

## Parent Home Dashboard

Show:

* Greeting
* Wallet Balance
* Children Summary
* Upcoming Sessions
* Notifications
* Recommended Tutors

Include:

* Quick Top Up
* Quick Search Tutor
* View Learning Progress

---

## Tutor Search

This is the core business screen.

Design:

Search bar

Required filters:

* Subject
* Education Level

Advanced filters:

* Hourly Rate
* Availability
* Minimum Rating
* Gender
* Verified Only

Search Results Card:

* Avatar
* Name
* Verification Badge
* Subjects
* Hourly Rate
* Rating
* Short Bio
* CTA

Use marketplace best practices.

---

## Tutor Profile

Create a premium profile page.

Sections:

Hero

* Large Avatar
* Name
* Rating
* Verification Badge
* Hourly Rate

Tabs:

* About
* Schedule
* Reviews

Schedule Tab:
Display bookable slots using modern calendar UX.

Reviews:
Show rating summary and review cards.

Sticky booking CTA.

---

## Booking Flow

Design complete flow:

1. Select Slot
2. Select Student
3. Booking Summary
4. Escrow Information
5. Confirmation
6. Success State

Show trust indicators explaining escrow protection.

---

## Booking Management

Statuses:

* Pending
* Confirmed
* In Progress
* Completed
* Paid
* Disputed
* Cancelled

Create visually distinct status badges.

Include timeline view.

---

## Wallet

Features:

* Current Balance
* Top Up
* Transaction History
* Escrow Locked Funds
* Refunds

Support:

* VNPay
* MoMo
* ZaloPay

Design modern fintech-style wallet UI.

---

## Student Management

Parents can manage multiple children.

Features:

* Add Student
* Edit Student
* Remove Student
* View Learning Progress
* View Assignments

---

# Tutor Experience

## Tutor Dashboard

Show:

* Verification Status
* Earnings
* Upcoming Sessions
* Active Students
* Recent Activity

Metrics Cards:

* Monthly Income
* Student Count
* Rating
* Completion Rate

---

## Tutor Onboarding

Multi-step onboarding flow.

Steps:

1. Personal Information
2. Subjects and Levels
3. Hourly Rate
4. Credential Upload
5. Schedule Setup
6. Review and Submit

Show progress indicator.

Support:

* Degree Upload
* Certificate Upload
* National ID Upload

Include upload states:

* Uploading
* Success
* Error

---

## Schedule Management

Design calendar management UI.

Features:

* Weekly View
* Daily View
* Add Availability
* Edit Availability
* Delete Availability

Booked slots must appear locked.

---

## Students Management

Tutor can:

* View Students
* Search Students
* View Student History
* Upload Materials
* Create Assignments

---

## Learning Portal

Design educational workspace.

Tabs:

Materials
Assignments
History

Material Types:

* Slides
* Notes
* Assignments

Assignment Features:

* Create Assignment
* Attach Files
* Set Deadline
* Track Submission Status

---

## Tutor Wallet

Features:

* Available Balance
* Pending Earnings
* Withdraw Funds
* Withdrawal History

Withdrawal Destinations:

* Bank Account
* E-Wallet

---

# Student Experience

## Student Home

Show:

* Upcoming Lesson
* Pending Assignments
* Recent Materials
* Notifications

---

## Materials

Features:

* Browse Materials
* Filter by Subject
* View PDFs
* Download Files

Design similar to Google Classroom.

---

## Assignments

Features:

* Assignment List
* Due Dates
* Submission Status

Statuses:

* Not Submitted
* Submitted
* Overdue

---

## Assignment Detail

Show:

* Description
* Attachments
* Deadline
* Upload Submission CTA

Support:

* PDF
* DOCX
* Images

---

# Notifications

Create notification center.

Categories:

* Bookings
* Payments
* Materials
* Assignments
* Verification

Include:

* Empty State
* Read/Unread States

---

# Profile

Features:

* Avatar
* Personal Information
* Security
* Notifications
* Dark Mode
* Help Center
* Logout

Tutor-only settings:

* Accepting Students Toggle

---

# Empty States

Design polished empty states for:

* No Tutors Found
* No Bookings
* No Students
* No Materials
* No Assignments
* No Transactions

Use modern illustrations and friendly messaging.

---

# Error States

Design:

* Network Error
* Payment Failed
* Upload Failed
* Booking Conflict
* Session Expired

Provide recovery actions.

---

# Loading States

Create:

* Skeleton Screens
* Card Placeholders
* Progressive Loading

For:

* Search Results
* Profile Pages
* Materials
* Wallet Transactions

---

# Dark Mode

Design every screen in:

* Light Mode
* Dark Mode

Maintain warm coral branding.

---

# Deliverables

Generate:

1. Full design system
2. Component library
3. Mobile UI kit
4. Parent user flow
5. Tutor user flow
6. Student user flow
7. Responsive layouts
8. Light and dark themes
9. High-fidelity mobile screens
10. Interactive prototype-ready layouts

Output should be production-level, modern, developer-ready mobile UI designs suitable for Flutter implementation.
