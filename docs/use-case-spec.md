# Use Case Specification — Tutor Matching Platform

---

## UC-01: Tutor Registration & Onboarding

**Actor:** Tutor
**Precondition:** User has not registered

**Main Flow:**
1. Tutor downloads app and selects "Register as Tutor"
2. Enters phone number → receives OTP → verifies
3. Fills in personal info: full name, avatar, bio
4. Adds teaching subjects and levels (can add multiple via TutorSubject)
5. Sets hourly rate
6. Uploads credential documents (degree, certificate, national ID)
7. Enters available schedule slots
8. Submits profile → status set to `PENDING_REVIEW`
9. System sends notification to Admin

**Alternate Flow:**
- 2a. OTP expired → resend OTP (max 3 times)
- 6a. File exceeds 20MB → system rejects, shows error

**Postcondition:** Tutor profile created with status `PENDING_REVIEW`

---

## UC-02: Admin Verifies Tutor Profile

**Actor:** Admin
**Precondition:** Tutor profile exists with status `PENDING_REVIEW`

**Main Flow:**
1. Admin opens verification queue
2. Reviews submitted documents (degree, ID)
3. Approves profile → status set to `VERIFIED`
4. System notifies tutor: "Your profile has been verified"

**Alternate Flow:**
- 3a. Admin rejects → enters reason → status set to `REJECTED` → tutor notified
- 3b. Admin requests more documents → status set to `REQUIRES_DOCUMENTS` → tutor notified

**Postcondition:** Tutor profile status updated; tutor notified

---

## UC-03: Parent Searches for a Tutor

**Actor:** Parent
**Precondition:** Parent is logged in

**Main Flow:**
1. Parent navigates to Search screen
2. Selects subject and level (required)
3. Optionally sets filters: hourly rate range, schedule, minimum rating, verified only
4. System queries tutors matching all criteria via `tutor_subjects` join
5. Results displayed: avatar, name, subject/level, hourly rate, rating, verified badge
6. Parent taps a tutor to view full profile: bio, credentials, available slots, reviews

**Alternate Flow:**
- 5a. No results found → system suggests broadening filters

**Postcondition:** Parent views list of matching tutors

---

## UC-04: Parent Books a Session

**Actor:** Parent
**Precondition:** Parent is logged in; has selected a tutor; wallet balance ≥ session cost

**Main Flow:**
1. Parent selects an available slot from tutor's schedule
2. Selects which student (child) this session is for
3. Reviews booking summary: tutor, subject, date/time, cost
4. Confirms booking → system locks funds in escrow
5. Booking created with status `PENDING`
6. Tutor receives push notification: new booking request

**Alternate Flow:**
- 4a. Insufficient wallet balance → redirect to top-up screen
- 4b. Slot was just taken by another parent → show error, return to schedule

**Postcondition:** Booking created with status `PENDING`; funds locked in escrow

---

## UC-05: Tutor Confirms or Declines Booking

**Actor:** Tutor
**Precondition:** Booking exists with status `PENDING`

**Main Flow:**
1. Tutor receives notification of new booking request
2. Reviews booking details: student, subject, date/time
3. Confirms booking → status set to `CONFIRMED`
4. Schedule slot marked as unavailable
5. Parent notified: "Your booking has been confirmed"

**Alternate Flow:**
- 3a. Tutor declines → enters reason → status set to `CANCELLED`
- 3b. Escrow funds returned to parent wallet
- 3c. Parent notified of decline with reason
- 3d. No response within 24h → booking auto-cancelled, funds returned

**Postcondition:** Booking confirmed and slot blocked, or cancelled and funds returned

---

## UC-06: Tutor Uploads Learning Materials

**Actor:** Tutor
**Precondition:** Booking exists with status `CONFIRMED` or `COMPLETED`

**Main Flow:**
1. Tutor opens class for a specific student
2. Selects "Upload Material"
3. Chooses type: `slide` / `note` / `assignment`
4. If assignment: enters title, description, deadline
5. Uploads file (PDF, DOCX, JPG — max 20MB)
6. System stores file in S3, creates `Material` record
7. Student and parent receive push notification

**Alternate Flow:**
- 5a. File too large → system rejects with error message

**Postcondition:** Material uploaded and accessible to student; notifications sent

---

## UC-07: Student Views Materials & Submits Assignment

**Actor:** Student
**Precondition:** Student is logged in; material has been uploaded by tutor

**Main Flow:**
1. Student opens portal and selects subject
2. Views list of materials organized by session date
3. Downloads or views slide / note files
4. Opens assignment: views title, description, deadline
5. Taps "Submit" → uploads file (PDF, image, Word)
6. Submission status updated to `submitted`
7. Tutor and parent receive notification: "Student has submitted assignment"

**Alternate Flow:**
- 5a. Deadline has passed → status shown as `overdue`; student can still submit but system flags it

**Postcondition:** Submission recorded; tutor and parent notified

---

## UC-08: Session Completion & Payment Release

**Actor:** System (automated)
**Precondition:** Booking status is `CONFIRMED`; session datetime has passed

**Main Flow:**
1. System detects session datetime has passed
2. Booking status updated to `COMPLETED`
3. 24-hour dispute window begins
4. If no dispute raised after 24h:
   - Platform deducts commission (10–15%)
   - Remaining amount released to tutor wallet
   - Booking status updated to `PAID`
   - Tutor notified: "Payment has been released"

**Alternate Flow:**
- 4a. Parent raises dispute within 24h → booking status set to `DISPUTED` → Admin reviews

**Postcondition:** Tutor paid and booking closed, or dispute opened for Admin review

---

## UC-09: Parent Raises a Dispute

**Actor:** Parent
**Precondition:** Booking status is `COMPLETED`; within 24h dispute window

**Main Flow:**
1. Parent navigates to booking history
2. Selects completed session and taps "Raise Dispute"
3. Selects reason (session did not happen / quality issue / other)
4. Adds description
5. Dispute submitted → booking status set to `DISPUTED`
6. Escrow funds remain locked
7. Admin notified of new dispute

**Postcondition:** Dispute created; funds held; Admin notified

---

## UC-10: Admin Resolves Dispute

**Actor:** Admin
**Precondition:** Booking exists with status `DISPUTED`

**Main Flow:**
1. Admin opens dispute queue
2. Reviews booking details, transaction history, both parties' claims
3. Decides outcome:
   - Full refund to parent → 100% returned, tutor receives nothing
   - Partial refund → split defined by Admin
   - Reject dispute → full amount released to tutor
4. System executes fund transfer per decision
5. Both parties notified of outcome and amount

**Postcondition:** Dispute resolved; funds distributed; booking closed

---

## UC-11: Parent Reviews a Tutor

**Actor:** Parent
**Precondition:** Booking status is `PAID`; parent has not yet reviewed this booking

**Main Flow:**
1. Parent receives prompt: "How was the session?"
2. Selects star rating (1–5)
3. Optionally enters written comment
4. Submits review
5. System updates tutor's `rating_avg` in `TutorProfile`

**Alternate Flow:**
- 1a. Parent dismisses prompt → can review later from booking history

**Postcondition:** Review saved; tutor rating recalculated

---

## UC-12: Tutor Manages Availability

**Actor:** Tutor
**Precondition:** Tutor is logged in and verified

**Main Flow:**
1. Tutor opens Schedule screen
2. Views weekly calendar of current slots
3. Adds new available slots: selects day, start time, end time
4. Saves → slots appear as available for parents to book
5. To remove a slot: selects unbooked slot → taps Delete

**Alternate Flow:**
- 5a. Slot already has a confirmed booking → cannot delete; tutor must cancel the booking instead

**Postcondition:** Schedule updated; available slots visible to parents in search

---

## UC-13: Tutor Toggles Accepting Students

**Actor:** Tutor
**Precondition:** Tutor is logged in and verified

**Main Flow:**
1. Tutor goes to Profile screen
2. Toggles "Accepting students" switch OFF
3. System sets `is_accepting = false` on `TutorProfile`
4. Tutor no longer appears in search results
5. Existing bookings and classes are unaffected

**Alternate Flow:**
- 2a. Toggle back ON → tutor reappears in search results immediately

**Postcondition:** Tutor visibility in search updated; existing classes unchanged

---

## UC-14: Parent Tops Up Wallet

**Actor:** Parent
**Precondition:** Parent is logged in

**Main Flow:**
1. Parent navigates to Wallet screen
2. Selects "Top Up"
3. Enters amount
4. Selects payment method: VNPay / MoMo / ZaloPay
5. Redirected to payment gateway
6. Completes payment externally
7. System receives callback → creates `Transaction` record (type: `topup`)
8. Wallet balance updated
9. Parent notified: "Top-up successful"

**Alternate Flow:**
- 6a. Payment fails or times out → balance unchanged; parent notified of failure

**Postcondition:** Parent wallet balance increased; transaction recorded

---

## UC-15: Tutor Withdraws Earnings

**Actor:** Tutor
**Precondition:** Tutor wallet balance > 0

**Main Flow:**
1. Tutor navigates to Wallet screen
2. Views available balance
3. Taps "Withdraw"
4. Enters amount and selects destination: bank account / e-wallet
5. Confirms withdrawal request
6. System processes transfer (same day or next business day)
7. Creates `Transaction` record (type: `withdrawal`)
8. Tutor notified when transfer is complete

**Alternate Flow:**
- 4a. Amount exceeds available balance → system shows error

**Postcondition:** Funds transferred to tutor's external account; balance reduced