# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

**Dealer sales staff** (primary in volume of use) — a salesperson on a YMSLI
dealership floor, phone in hand, often with a walk-in customer standing in front
of them. Their job: capture an enquiry before the customer leaves, keep follow-ups
from slipping, work the test-ride queue, answer service tickets, and see what they
have earned.

**Bike owners (customers)** — a Yamaha two-wheeler owner, onboarded by a dealer.
Their job: know the health of their bike, know when service is due, raise and
track a service request, and get answers without phoning the showroom.

**Guests (no login)** — someone browsing the bike catalogue, checking an exchange
value, or booking a test ride. A booking becomes a real lead for a dealer.

Both signed-in roles use one login; the role comes from the backend profile
(`GET /me`), not from a choice on the login screen.

## Product Purpose

Entry for **YMSLI Hackathon PS-06** ("Smart Dealer Enquiry App"). It closes the
loop from a stranger's first interest to a delivered bike and an owner who keeps
coming back to the dealer: enquiries are captured and triaged, follow-ups are
scheduled, test rides turn into assigned leads, and owners get vehicle health,
service threads, and an assistant.

Success is a judged live demo: the whole loop visibly working on real data, with
the AI doing something a rules engine could not.

## Positioning

Three things a neighbouring "dealer CRM" could not truthfully claim:

- **AI that is actually running, and says so.** Lead intent (HOT/WARM/COLD),
  service-ticket triage (category + priority + desk summary), OBD explanations and
  the owner assistant all call Claude Sonnet 5 on Bedrock. Every AI surface reports
  its provenance and falls back to a deterministic heuristic rather than failing.
- **A public booking becomes assigned work, atomically.** A guest test-ride booking
  creates the booking, creates the lead, round-robin assigns a salesperson under a
  row lock, and notifies them — in one transaction. A booking never exists without
  its lead.
- **The bike itself is an input.** A real ELM327 over Bluetooth feeds live
  telemetry; the owner gets a plain-language summary of the last minute of readings
  and can turn a fault into a service ticket the dealer answers in the same thread.

## Operating Context

- **Showroom floor:** bright light, one hand, seconds of attention, a customer
  waiting. Capture speed and follow-up discipline matter more than depth.
- **Roadside / garage:** the owner has an ELM327 dongle plugged into the bike and
  is looking at live readings on a phone.
- **The judging table:** a short live demo on an Android phone, with a tablet also
  in play. Both screen sizes must look deliberate, not stretched.
- **Two dealer branches** in the seeded world (Mumbai Andheri, Bengaluru
  Whitefield), so dealer-scoped data is genuinely scoped.

## Capabilities and Constraints

- **Flutter / Dart**, Riverpod, go_router, dio. Feature-first layout; every screen
  reaches the backend through a typed repository behind a Riverpod provider.
- **The app is ~90% implemented and fully wired to the live backend.** Remaining
  work is UI redesign only. Behaviour, data flow, repositories, providers, routes
  and copy semantics must be preserved exactly; structural change is acceptable
  only where the UI requires it.
- **Android only.** Must be responsive across every Android form factor — phone
  and tablet — with **no overflow anywhere**.
- **English only.** No localisation.
- Backend: FastAPI + SQLAlchemy on Postgres (Aurora/RDS, ap-northeast-2), Cognito
  passwordless **email OTP (8 digits)**, S3, SNS/SES, Bedrock (Sonnet 5, `us.`
  cross-region inference profile, us-east-1 only).
- **Two sign-in paths coexist in one build:** real Cognito OTP for provisioned
  accounts, and a dev shortcut for the seeded `@ymsli-demo.example` accounts.
- **AI never blocks a flow.** Ticket triage is instant (heuristic) and refined in
  the background; every AI call degrades to a deterministic fallback. The UI must
  be able to say which one it is showing.
- **No invented telemetry.** Readings come from a connected ELM327 or not at all;
  with no device the app asks for one instead of showing numbers.
- **DPDP:** seeded and masked demo data only. No real customer PII.
- In-app notifications are polled from the backend (no Firebase); unread counts
  drive badges.

## Brand Commitments

- A **Yamaha (YMSLI)** product. The existing theme is Yamaha deep blue with red
  accents (`lib/core/config/theme.dart`) — the brand colours are binding, the
  current visual treatment of them is not.
- In-app product name today: **"Smart Dealer Enquiry App"**.

## Evidence on Hand

- `PS-06_DealerApp.pdf` — the problem statement.
- `PLAN_backend.md`, `PLAN_frontend.md` — the build plans both sides were built to.
- `INTEGRATION.md` (backend repo) — how the app and API are wired, and the
  contract mismatches that were fixed.
- Seeded demo data on the live database: 2 dealers, 6 staff, 10 Yamaha models,
  ~25 leads across statuses with AI intents, test-ride bookings, service tickets
  carrying AI category/priority, 2 customers with vehicles and service history.
- Real OTP accounts for the demo: a dealer and a customer whose codes arrive by
  email.
- **Absent, and must not be fabricated:** customer testimonials, adoption or
  accuracy numbers, pricing, dealer names beyond the two seeded, and any claim
  about being deployed.

## Product Principles

1. **Never break a working path.** Every screen is already connected and
   functioning; a redesign that regresses behaviour is a failure regardless of how
   it looks.
2. **Show the real thing.** Real records from the live database, real model output,
   real device readings — never a mock dressed up as data.
3. **Be honest about the machine.** Where AI produced something, say so; where a
   fallback produced it, say that instead.
4. **Survive every screen.** A phone and a tablet must both look intentional, and
   nothing may overflow.
5. **Legible in seconds.** A judge or a salesperson should understand what a screen
   is for, and what to do next, without being told.

## Accessibility & Inclusion

English only. Practical needs of the setting rather than a formal standard:
comfortable one-handed touch targets, and text and status colour that survive
bright showroom light. No specific conformance level has been established.
