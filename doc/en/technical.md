# Core.Form.Znuny4OTRSInput

The purpose of this Javascript library is to make the handling of fields in the frontend much easier. It aims to make development

- easier
- faster
- robust
- tested
- normalized
- centralized

The issue with the OTRS HTML frontend is that a lot of views have their own quirks. Here are some examples:

- Different IDs for the same fields in different views, like "NewStateID" and "StateID" etc.
- Sometimes mixed values and IDs in Queue selection like "1||Postmaster"
- Different ways of setting values, like RichText with CKEditor enabled or not
- DynamicFields

and so on.

## Module()

Returns the module for an action or view.

Example:
```
var Module = Core.Form.Znuny4OTRSInput.Module("AgentTicketNote");
// Module = "AgentTicketActionCommon"

// or

var Module = Core.Form.Znuny4OTRSInput.Module("AgentTicketPhone");
// Module = "AgentTicketPhone"
```

## FieldID()

Returns the ID of the field for the given attribute.

Example:
```
// in AgentTicketPhone
var FieldID = Core.Form.Znuny4OTRSInput.FieldID("QueueID");
// FieldID = "Dest"

// or

// in AgentTicketMove
var FieldID = Core.Form.Znuny4OTRSInput.FieldID("QueueID");
// FieldID = "DestQueueID"
```

## Type()

Returns the field type for the given attribute.

Example:
```
var Type = Core.Form.Znuny4OTRSInput.Type("QueueID");
// Type = "select"

// or
var Type = Core.Form.Znuny4OTRSInput.Type("RichText");
// Type = "textarea"

// or
var Type = Core.Form.Znuny4OTRSInput.Type("Subject");
// Type = "input"
```

## Get()

Returns the key (default) or value of a given attribute.

Example:
```
var Key = Core.Form.Znuny4OTRSInput.Get("QueueID");
// Key = "1"

// or

var Value = Core.Form.Znuny4OTRSInput.Get("QueueID", { KeyOrValue: 'Value' });
// Value = "Postmaster"
```

## Set()

Sets the key (default) or value of a given attribute. Additional option defines if a change event should be triggered (default) or not.

Example:
```
var Success = Core.Form.Znuny4OTRSInput.Set("QueueID", "1");
var Success = Core.Form.Znuny4OTRSInput.Set("QueueID", "Postmaster", { KeyOrValue: 'Value' });

// or
var Success = Core.Form.Znuny4OTRSInput.Set("QueueID", "1", { TriggerChange: false });
var Success = Core.Form.Znuny4OTRSInput.Set("QueueID", "Postmaster", { KeyOrValue: 'Value', TriggerChange: false });

// or
var Success = Core.Form.Znuny4OTRSInput.Set("QueueID");
var Success = Core.Form.Znuny4OTRSInput.Set("QueueID", undefined, { TriggerChange: false });
```
