# ARADI Cloud Functions

## Deploy

From project root:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions --force
```

Use `--force` so Firebase can set the artifact cleanup policy automatically (avoids the "could not set up cleanup policy" message).

To set the cleanup policy manually instead:

```bash
firebase functions:artifacts:setpolicy
```

## Timezone

- The function **sendPushOnNotificationEvent** runs in Google Cloud (UTC) as soon as a notification document is created. There is no schedule or timezone to configure for the function itself.
- For the **app** (e.g. notification "time ago" or absolute times), use **Asia/Dubai** (UAE) when formatting dates if you want times shown in UAE.
