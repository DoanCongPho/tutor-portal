# Product Requirements Document (PRD)
# Tutor Matching Platform

**Version:** 1.0
**Status:** Draft
**Last Updated:** 2026-05-28

---

## 1. Product Overview

A mobile-first platform (iOS + Android) that solves three problems in one app:

- **Parents** cannot reliably find and vet qualified tutors — current channels
  are Zalo groups and word-of-mouth with no credential verification
- **Tutors** have no tool to manage students, schedule, materials, and income
  in one place — everything lives across Zalo, paper notebooks, and cash
- **Students** have no structured place to access lesson materials or submit
  assignments — files get lost in chat threads

The platform connects parents with verified tutors, handles scheduling and
safe payment via escrow, and gives students a learning portal to access
materials and submit assignments.

**Tech stack:** Flutter (iOS + Android) — Golang backend
**Architecture:** model → repository → handler → service

---

## 2. Users

### Roles

| Role | Description |
|---|---|
| Parent | Finds and books tutors for their child; manages payment |
| Tutor | Manages profile, schedule, materials, and income |
| Student | Accesses learning portal; submits assignments |
| Admin | Verifies tutor credentials; resolves disputes; operates platform |

### Student accounts
Students do not self-register. A parent creates a student profile (name,
grade, subjects) under their own account. One parent account can have
multiple student profiles.

---

## 3. Goals

### Launch goals (Month 1–3)
- Parents can find a verified tutor and complete a booking end-to-end
- Tutors can manage schedule, upload materials, and receive payment entirely
  within the app — no need for Zalo or cash
- Students can access materials and submit assignments without friction
- Admin can verify tutor credentials and resolve disputes

### Growth goals (Month 3–6)
- 500 registered tutors, 300 verified
- 1,000 registered parents
- 400 successful bookings per month
- Platform GMV: 200,000,000 VND / month
- Parent 30-day retention ≥ 60%
- Tutor 30-day retention ≥ 70%

### Quality targets
- Average tutor rating ≥ 4.2 / 5
- Dispute rate < 3% of completed sessions
- Tutor cancellation rate < 5%

---

## 4. Non-Goals (v1)

- In-app video or live tutoring sessions — tutors and students use Zoom or
  Google Meet externally
- AI-generated lesson plans or content recommendations
- School or institution accounts
- Web interface — mobile only
- International markets or multi-currency
- Group sessions (one tutor, multiple students from different families)

---

## 5. Features

### 5.1 Authentication & Accounts

**Registration**
- Register via phone number + password (min 8 chars, stored as a bcrypt hash)
- Login via phone number + password
- Role selected at registration: Tutor or Parent
- Student profiles created by parent, not self-registered

**Session management**
- JWT + refresh token; access token expires in 15 minutes
- Single device session per account (v1)

---

### 5.2 Tutor Onboarding & Verification

Tutors go through a one-time onboarding before they can appear in search
results or accept bookings.

**Onboarding steps**
1. Personal info: full name, avatar, phone number
2. Teaching subjects and levels — stored as separate rows in `tutor_subjects`
   (not a text field); a tutor can teach multiple subject/level combinations
3. Hourly rate — single rate applied to all subjects in v1
4. Credential upload: degree, teaching certificate, national ID (PDF or image,
   max 20MB per file)
5. Available schedule slots
6. Submit for review → profile status: `PENDING_REVIEW`

**Admin review**
- Admin views credential files and approves or rejects
- Approve → status: `VERIFIED`; tutor notified
- Reject → admin enters reason → status: `REJECTED`; tutor notified with reason
- Request more documents → status: `REQUIRES_DOCUMENTS`; tutor notified

**Verification badge**
- Profile displays one of three states: `Unverified` / `Under Review` / `Verified`
- Only `VERIFIED` tutors appear in parent search results

---

### 5.3 Tutor Profile Management

- Update avatar, bio, subjects, hourly rate at any time
- Re-upload credentials (triggers re-review only if previously rejected)
- Toggle **Accepting students** on/off
  - OFF: tutor hidden from search results; existing bookings unaffected
  - ON: tutor visible in search immediately

---

### 5.4 Schedule Management

- Tutor enters available slots by day of week, start time, end time
- Slots are visible to parents when browsing a tutor's profile
- On booking confirmation, slot is automatically blocked
- Tutor can edit or delete slots that have no confirmed booking
- Slots with confirmed bookings cannot be deleted — tutor must cancel the
  booking instead

---

### 5.5 Parent: Search & Discovery

Parents search for tutors by subject and level (required fields). Additional
filters:

| Filter | Type |
|---|---|
| Subject | Required |
| Level | Required |
| Hourly rate | Range (min / max) |
| Available day / time | Slot picker |
| Verified only | Toggle |
| Minimum rating | 1–5 stars |
| Gender | Optional |

Search results show: avatar, name, subjects, hourly rate, rating, verified
badge. Tapping a result opens the full tutor profile: bio, credential status,
available slots, and past reviews.

Tutors with `is_accepting = false` or verification status other than
`VERIFIED` are excluded from all search results.

---

### 5.6 Booking

**Creating a booking**
1. Parent selects an available slot from the tutor's schedule
2. Selects which student (child) the session is for
3. Reviews summary: tutor, subject, date/time, cost
4. Confirms → system locks the session amount in escrow from parent wallet
5. Booking created with status `PENDING`
6. Tutor notified of new request

**Concurrent requests**
A parent may send requests to up to 3 tutors for the same time slot
simultaneously. When the first tutor confirms:
- All other `PENDING` requests for that slot are automatically cancelled
  with status `CANCELLED_BY_MATCH`
- Escrow funds for cancelled requests are returned to parent wallet immediately
- Affected tutors are notified: "This request was cancelled because the parent
  matched with another tutor"
- `CANCELLED_BY_MATCH` does not affect the tutor's reliability score

Tutors are shown a notice when receiving a request: "The parent may have sent
requests to other tutors for this slot."

**Tutor response**
- Tutor must confirm or decline within 24 hours
- Confirm → status: `CONFIRMED`; slot blocked; parent notified
- Decline → status: `CANCELLED_BY_TUTOR`; escrow returned; parent notified
  with reason
- No response in 24h → status: `CANCELLED_BY_TIMEOUT`; escrow returned;
  parent notified

**Booking status flow**

```
PENDING ──► CONFIRMED ──► IN_PROGRESS ──► COMPLETED ──► PAID
   │                                           │
   ├──► CANCELLED_BY_MATCH                     └──► DISPUTED
   ├──► CANCELLED_BY_TUTOR
   ├──► CANCELLED_BY_PARENT
   └──► CANCELLED_BY_TIMEOUT
```

---

### 5.7 Cancellation Policy

| Who cancels | When | Refund to parent | To tutor |
|---|---|---|---|
| Parent | 24h+ before session | 100% | 0% |
| Parent | Within 24h | 50% | 50% |
| Tutor | Any time | 100% | 0% + reliability penalty |
| System (timeout) | After 24h no response | 100% | 0% |
| System (match) | Another tutor confirmed first | 100% | 0% |

---

### 5.8 Learning Portal

**Tutor uploads**
- Upload materials per class: PDF slides, notes, any file (max 20MB)
- Create assignments: title, description, deadline, file attachment (optional)
- Material types: `slide` / `note` / `assignment`
- On upload: student and parent receive push notification

**Student access**
- Login with account created by parent
- View materials organized by subject and session date
- Download or view files inline
- View assignments: title, description, deadline, current status
- Submit assignment by uploading a file (PDF, image, DOCX)
- Assignment statuses: `Not Submitted` / `Submitted` / `Overdue`
- Overdue submissions are still accepted but flagged

**Tutor views submissions**
- List of submissions per assignment
- Submission timestamp and status visible
- Receives notification when student submits

---

### 5.9 Payments & Wallet

**Parent wallet**
- Top up via VNPay, MoMo, or ZaloPay
- Balance visible on home screen
- On booking: session amount locked in escrow
- On cancellation: escrow returned per cancellation policy
- Transaction history: top-ups, escrow locks, refunds

**Escrow release**
- Session datetime passes → booking status: `COMPLETED`
- 24-hour dispute window starts
- No dispute after 24h → platform deducts commission (10–15%) → remainder
  released to tutor wallet → booking status: `PAID`
- Dispute raised → booking status: `DISPUTED` → funds held → Admin resolves

**Tutor wallet**
- Receives net amount after platform commission on release
- Requests withdrawal to bank account or e-wallet
- Withdrawal processed same day or next business day
- Transaction history: releases, withdrawals

**Platform commission**
- Deducted automatically at escrow release
- Rate: 10–15% of session amount (exact rate TBD before launch)

---

### 5.10 Disputes

- Parent can raise a dispute within 24h of session completion
- Dispute reasons: session did not happen / quality issue / other
- On dispute: booking status → `DISPUTED`; escrow held
- Admin reviews: booking history, both parties' accounts, transaction records
- Admin decides: full refund / partial refund / release to tutor
- Both parties notified of decision

---

### 5.11 Reviews & Ratings

- Review unlocked only when booking status = `PAID`
- Parent rates tutor: 1–5 stars + optional written comment
- One review per booking
- Tutor's `rating_avg` in `TutorProfile` recalculated after each new review
- Reviews displayed chronologically on tutor profile page

---

### 5.12 Notifications

All notifications delivered via Firebase Cloud Messaging (FCM).

| Event | Recipient |
|---|---|
| Tutor confirms booking | Parent |
| Tutor declines booking | Parent |
| Booking auto-cancelled (timeout) | Parent |
| Request cancelled by match | Tutor |
| Session reminder — 1 day before | Tutor + Student + Parent |
| Session reminder — 1 hour before | Tutor + Student + Parent |
| Tutor uploads material | Student + Parent |
| Assignment deadline in 24h | Student + Parent |
| Student submits assignment | Tutor + Parent |
| Payment released | Tutor |
| Dispute resolved | Parent + Tutor |
| Profile approved / rejected | Tutor |

---

### 5.13 Admin

**Tutor verification queue**
- List of profiles with status `PENDING_REVIEW` or `REQUIRES_DOCUMENTS`
- View uploaded credential files
- Approve, reject (with reason), or request additional documents

**User management**
- Search any user by name, phone, or email
- View profile, booking history, transaction history
- Suspend or unsuspend account

**Dispute resolution**
- Dispute queue with booking details and both parties' accounts
- View full transaction trail
- Issue full refund, partial refund, or release to tutor
- Decision recorded with admin note

**Operations dashboard**
- Total registered users by role
- Verified tutors count
- Bookings this month: total, confirmed, cancelled, disputed
- GMV and platform revenue this month
- Pending escrow transactions

---

## 6. Data Models

### Core tables

**users**
```
id, role, name, phone, email, avatar_url, status, created_at
```


**tutor_profiles**
```
id, user_id, hourly_rate, bio, is_accepting,
verification_status, rating_avg, rating_count
```

**tutor_subjects** *(one-to-many with tutor_profiles)*
```
id, tutor_id, subject, level
```
A tutor teaching Math at both high_school and university level has two rows.
Subject and level use a controlled vocabulary defined in the codebase — not
free text — to ensure consistent filtering.

**tutor_documents**
```
id, tutor_id, doc_type, file_url, uploaded_at, verified_at, admin_note
```

**schedules**
```
id, tutor_id, day_of_week, start_time, end_time, is_available
```

**students**
```
id, parent_id, name, grade
```

**bookings**
```
id, tutor_id, student_id, parent_id, subject, level,
slot_datetime, status, amount, platform_fee, created_at
```

**materials**
```
id, tutor_id, student_id, booking_id,
type, file_url, title, deadline, created_at
```

**submissions**
```
id, assignment_id (→ materials.id), student_id,
file_url, submitted_at, status
```

**transactions**
```
id, user_id, type, amount, ref_booking_id, created_at
```
Types: `topup` `escrow_lock` `escrow_release` `refund` `withdrawal`

**reviews**
```
id, booking_id, parent_id, tutor_id, rating, comment, created_at
```

---

## 7. Technical Constraints

| Area | Constraint |
|---|---|
| Platforms | iOS and Android only (v1) |
| Frontend | Flutter |
| Backend | Golang, REST, `/api/v1/` |
| Auth | JWT + refresh token, 15-min access token expiry |
| File storage | S3-compatible; 20MB per file; PDF, JPG, PNG, DOCX |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Payment gateways | VNPay, MoMo, ZaloPay |
| Timezone | Stored UTC; displayed Asia/Ho_Chi_Minh |
| Concurrency | Pessimistic lock on schedule slot at booking confirmation |

---

## 8. Monetization

| Stream | Mechanism |
|---|---|
| Session commission | 10–15% deducted at escrow release — primary revenue |
| Tutor Pro subscription | Monthly fee: unlimited students + featured in search |

Commission is deducted automatically. No manual invoicing.

---

## 9. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Tutors collect payment outside app | High | Escrow + portal access creates strong incentive to stay in-app |
| Slot race condition (two parents book same slot) | Medium | Pessimistic lock at booking confirmation |
| Fake credentials | High | Admin manual review before any tutor goes live |
| Tutor no-show | High | Dispute mechanism + reliability score + cancellation penalty |
| Low parent retention after first match | High | Notification loop via assignment and material uploads keeps parents engaged |
| Payment gateway downtime | Medium | Three gateways supported; failover to another if one is down |

---

## 10. Open Questions

- [ ] Should tutors be able to set different hourly rates per subject or level?
- [ ] Minimum wallet top-up amount?
- [ ] What happens to uploaded materials after a tutor-student relationship ends
      — are they still accessible to the student?
- [ ] Should there be an in-app messaging feature between parent and tutor, or
      is directing users to Zalo acceptable for v1?
- [ ] Recurring / subscription-style bookings (same slot every week)?
- [ ] How should the Pro subscription interact with the commission rate —
      should Pro tutors get a reduced commission?