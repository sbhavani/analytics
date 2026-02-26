# Feature Specification: Webhook Notifications

**Feature Branch**: `008-webhook-notifications`
**Created**: 2026-02-26
**Status**: Draft
**Input**: User description: "Add webhook notifications: implement a webhook system that sends HTTP POST events when configured triggers occur (e.g., spike in visitors, goal completions). This is for Plausible Analytics - an Elixir/Phoenix web analytics platform."

## Overview

This feature adds webhook notification capabilities to Plausible Analytics, enabling websites to receive real-time HTTP POST notifications when specific events occur, such as traffic spikes or goal completions. Webhooks allow external systems, automation tools, and custom integrations to react to analytics events in real-time.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Traffic Spike Notifications (Priority: P1)

A website owner wants to be immediately notified when their website experiences a sudden increase in visitors, enabling them to respond quickly to viral content or potential issues.

**Why this priority**: Traffic spike notifications are the primary use case for webhook notifications, directly addressing a known need (as evidenced by the existing email-based TrafficChangeNotification system). This delivers immediate value by replacing manual monitoring.

**Independent Test**: Can be tested by configuring a webhook endpoint, triggering a traffic spike condition, and verifying the HTTP POST is received with correct payload.

**Acceptance Scenarios**:

1. **Given** a site has webhook configured with traffic spike alerts enabled, **When** visitor count exceeds the configured threshold, **Then** an HTTP POST request is sent to the configured webhook URL with spike event payload
2. **Given** a site has webhook configured with traffic spike alerts enabled, **When** visitor count returns to normal levels, **Then** no additional notification is sent (until next threshold breach)
3. **Given** a site owner has enabled traffic spike webhooks, **When** they receive a spike notification, **Then** the payload includes current visitor count, threshold value, and comparison to baseline

---

### User Story 2 - Goal Completion Notifications (Priority: P1)

A website owner wants to be notified immediately when visitors complete defined goals (e.g., form submissions, purchases, sign-ups), enabling real-time response to conversions.

**Why this priority**: Goal completions are a core analytics metric that users want to act on immediately. Real-time notification enables instant follow-up actions in external systems (CRM, marketing automation, support tools).

**Independent Test**: Can be tested by creating a goal, configuring webhook for goal events, triggering a goal conversion, and verifying HTTP POST is received.

**Acceptance Scenarios**:

1. **Given** a site has webhook configured with goal notifications enabled for a specific goal, **When** that goal is completed by a visitor, **Then** an HTTP POST is sent to the webhook URL with goal completion payload
2. **Given** a site has webhook configured with goal notifications for all goals, **When** any goal is completed, **Then** the webhook payload includes the goal name and completion details
3. **Given** a site has webhook configured with goal notifications, **When** multiple goals complete in quick succession, **Then** each completion triggers a separate webhook POST

---

### User Story 3 - Webhook Configuration Management (Priority: P2)

A website owner needs to configure, test, and manage webhook settings through the Plausible interface, similar to how they manage other notification settings.

**Why this priority**: Users need a way to set up and manage webhooks without developer intervention. The configuration experience should be intuitive and similar to existing notification settings.

**Independent Test**: Can be tested by navigating to site settings, adding/editing/deleting webhook configurations, and verifying settings persist correctly.

**Acceptance Scenarios**:

1. **Given** a user is on the site settings page, **When** they navigate to webhook settings, **Then** they can add a new webhook with URL, secret, and event subscriptions
2. **Given** a user has an existing webhook configured, **When** they edit the webhook settings, **Then** changes are saved and take effect for next event
3. **Given** a user has an existing webhook, **When** they delete the webhook, **Then** webhook is removed and no further notifications are sent

---

### User Story 4 - Webhook Testing (Priority: P2)

A website owner wants to verify their webhook endpoint is correctly configured and reachable before relying on it for production events.

**Why this priority**: Debugging webhook configuration issues is difficult without a test mechanism. A test button allows users to verify their endpoint is working without waiting for actual events.

**Independent Test**: Can be tested by configuring a webhook and clicking "Test Webhook" button, then verifying the test payload is received at the endpoint.

**Acceptance Scenarios**:

1. **Given** a user has configured a webhook URL, **When** they click "Send Test Webhook", **Then** a test POST is sent with a sample payload
2. **Given** a webhook URL is unreachable or returns error, **When** user clicks "Send Test Webhook", **Then** user sees an error message indicating the failure

---

### User Story 5 - Traffic Drop Notifications (Priority: P3)

A website owner wants to be notified when their traffic drops below expected levels, helping them identify technical issues or content problems quickly.

**Why this priority**: Complements traffic spike notifications by providing bidirectional alerting. Existing TrafficChangeNotification already supports drops, so this extends that capability to webhooks.

**Independent Test**: Can be tested by configuring a webhook with drop alerts, triggering a traffic drop condition, and verifying the notification is received.

**Acceptance Scenarios**:

1. **Given** a site has webhook configured with traffic drop alerts, **When** visitor count falls below threshold, **Then** an HTTP POST is sent with drop event payload

---

### Edge Cases

- What happens when the webhook endpoint is temporarily unreachable? (System should implement retry logic with exponential backoff)
- How does the system handle invalid or malformed webhook URLs? (Validate URL format on save)
- What happens if the webhook endpoint returns a non-2xx response? (Log failure, provide visibility in UI)
- How does the system handle very high webhook volume? (Implement rate limiting to prevent overwhelming external endpoints)
- What happens if the webhook secret is compromised? (Allow secret rotation without losing configuration)
- How are failed webhook deliveries handled? (Provide delivery logs and retry mechanism)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to configure one or more webhook endpoints per site
- **FR-002**: System MUST support webhook notifications for traffic spike events
- **FR-003**: System MUST support webhook notifications for traffic drop events
- **FR-004**: System MUST support webhook notifications for goal completion events
- **FR-005**: Webhook payloads MUST be sent as HTTP POST requests with JSON body
- **FR-006**: Webhook requests MUST include a signature header for payload verification
- **FR-007**: System MUST allow users to enable/disable specific event types per webhook
- **FR-008**: System MUST validate webhook URL format before saving
- **FR-009**: System MUST provide a test webhook feature that sends a sample payload
- **FR-010**: System MUST retry failed webhook deliveries with exponential backoff
- **FR-011**: System MUST log webhook delivery attempts and outcomes
- **FR-012**: Users MUST be able to edit existing webhook configurations
- **FR-013**: Users MUST be able to delete webhook configurations
- **FR-014**: Webhook configuration MUST be tied to site permissions (only users with access can manage webhooks)

### Key Entities *(include if feature involves data)*

- **Webhook Configuration**: Stores webhook URL, secret, enabled events, and site association
- **Webhook Event**: Represents a triggered notification event (spike, drop, goal) to be delivered
- **Webhook Delivery Log**: Records delivery attempts, responses, and failures for debugging

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can configure and receive webhook notifications for traffic spike events within 5 minutes of configuration
- **SC-002**: Users can configure and receive webhook notifications for goal completions within 5 minutes of configuration
- **SC-003**: 95% of webhook deliveries succeed on first attempt under normal network conditions
- **SC-004**: Users can verify webhook configuration is working via test button without waiting for actual events
- **SC-005**: Webhook delivery latency (from event trigger to POST request) is under 30 seconds
- **SC-006**: Failed webhook deliveries are retried automatically up to 3 times before marking as failed
