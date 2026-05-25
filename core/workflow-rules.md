# Diary Assistant — Workflow Rules (Platform Agnostic)

This document defines the core workflow logic for a diary assistant.
It is designed to be implemented on any AI agent platform (CherryClaw, Claude Code, Cursor, custom scripts, etc.).

---

## Data Flow

```
User sends message → Capture send timestamp
  ├─ Message contains time reference? → Use that time (for backfilling)
  └─ Otherwise → Use the send timestamp
↓
Append to raw/YYYY-MM-DD.md  (format: "HH:MM message content")
↓
Reply briefly: "已记下 ✅"
↓
[At 06:00 daily / or user says "收工/睡了"]
↓
Read raw/YYYY-MM-DD.md
↓
Compose diary in first-person "I" voice, chronologically
↓
Write to YYYY/MM/YYYY-MM-DD.md
↓
Delete raw/YYYY-MM-DD.md
↓
Send notification: "昨天的日记已写好 📖"
```

## File Structure

```
{diary_root}/
├── raw/
│   └── YYYY-MM-DD.md        # Raw entries during the day
├── YYYY/
│   └── MM/
│       └── YYYY-MM-DD.md    # Final diary
```

## Raw Entry Format

Each line in `raw/YYYY-MM-DD.md`:
```
HH:MM  content description here
```

Example:
```
07:30  woke up
12:15  had lunch - noodles
14:00  went out for a walk
22:30  damn, can't sleep again
```

## Final Diary Format

```markdown
# YYYY-MM-DD Diary

**07:30** Woke up, didn't linger in bed today.

**12:15** Had some noodles for lunch, nothing fancy.

**14:00** Took a walk outside, weather was decent.

**22:30** Fuck, can't sleep again. Should've worked out.
```

## Trigger Conditions

| Trigger | Timing | Action |
|---------|--------|--------|
| Scheduled | Daily at 06:00 | Auto-summarize previous day |
| Manual: "收工/睡了/下班" | On user command | Immediate summary |

## Time Priority Rule

When recording an entry:
1. If the message **content** mentions a time → use that time
2. Otherwise → use the message's send timestamp

This allows the user to backfill events they forgot to report in real-time.

Example:
- User sends at 20:00: "中午吃的面条" → Record as **12:00**, not 20:00
- User sends at 15:30: "出门溜达" → Record as **15:30**

## Implementation Notes by Platform

### CherryClaw
- Uses `mcp__claw__cron` for scheduled tasks
- Uses `mcp__claw__notify` for notifications
- Uses `mcp__claw__config` for channel management
- SOUL.md and USER.md are auto-loaded by the agent

### Claude Code
- Uses `CLAUDE.md` for agent rules
- Uses `claude_code.md` hooks or cron for scheduling
- No built-in notification system (use system notifications)
- File operations via Bash/Read/Write tools

### Cursor
- Uses `.cursorrules` for agent rules
- Manual scheduling or external cron
- File operations via Cursor's built-in tools

### Custom Implementation
- Any AI agent with file read/write + scheduling capabilities
- Adapt the cron/notification parts to your platform
