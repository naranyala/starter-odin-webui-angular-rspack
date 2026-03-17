# Backend-Frontend Communication Approaches

## Overview

This project provides multiple communication patterns between the Odin backend and Angular frontend through the WebUI bridge. Each approach has specific use cases, advantages, and trade-offs.

## Architecture

```
Angular Frontend
       │
       │ WebUI JavaScript Bridge
       ▼
┌──────────────────────────────────────────────────────────────┐
│                    WebUI Core (C)                           │
│  - Window Management  - Event Routing  - Protocol Encoding  │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               │ FFI
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                      Odin Backend                             │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐              │
│  │    RPC     │  │  Events   │  │ Channels  │              │
│  └────────────┘  └────────────┘  └────────────┘              │
│  ┌────────────┐  ┌────────────┐                              │
│  │  Message   │  │  Binary   │                              │
│  └────────────┘  └────────────┘                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Available Approaches

### 1. RPC (Remote Procedure Call)

**Pattern**: Request-Response  
**File**: `src/lib/comms/comms.odin` - RPC section

Frontend calls backend function and waits for response:

```typescript
// Frontend (Angular)
const result = await webui.call('user.login', { 
    username: 'john', 
    password: 'pass123' 
});
console.log(result); // { token: 'abc123', user: {...} }
```

```odin
// Backend (Odin)
handle_login :: proc "c" (e: ^webui.Event) {
    params := webui.event_get_string(e)
    
    // Parse and validate
    username := extract_field(params, "username")
    password := extract_field(params, "password")
    
    // Process
    if validate_user(username, password) {
        token := generate_token(username)
        response := fmt.Sprintf(`{"token":"%s","user":{"name":"%s"}}`, token, username)
        webui.event_return_string(e, response)
    } else {
        webui.event_return_string(e, `{"error":"Invalid credentials"}`)
    }
}
```

**When to Use**:
- User authentication
- Data fetching
- Form submissions
- Any operation requiring immediate response

**Advantages**:
- Simple to understand
- Type-safe with proper definitions
- Request-response guarantees

**Disadvantages**:
- Not suitable for real-time updates
- Blocking (waits for response)

---

### 2. Event Bus (Publish-Subscribe)

**Pattern**: Fire-and-forget, one-to-many  
**File**: `src/lib/events/event_bus.odin`

Publish events to multiple subscribers:

```typescript
// Frontend - Subscribe to events
webui.on('notification.new', (data) => {
    console.log('New notification:', data);
});

webui.on('user.status', (data) => {
    console.log('User status changed:', data);
});
```

```odin
// Backend - Emit events
// Using events package (type-safe)
User_Event :: struct {
    user_id: int,
    status:  string,
}

event := User_Event{user_id = 123, status = "online"}
events.emit_typed(&bus, User_Event, .User_Status_Changed, event)

// Or using comms package
event_bus_emit("notification.new", `{"title":"Hello","message":"World"}`)
```

**When to Use**:
- Notifications
- State synchronization
- System events
- Broadcasting to multiple components

**Advantages**:
- Decoupled architecture
- One-to-many communication
- Real-time updates

**Disadvantages**:
- No delivery guarantee
- Can lead to complex event flows

---

### 3. Direct Binding

**Pattern**: Element-to-handler  
**File**: `src/lib/webui_lib/webui.odin`

Bind HTML elements directly to Odin handlers:

```html
<!-- Frontend HTML -->
<button id="btnLogin">Login</button>
<input id="txtUsername" />
<input id="txtPassword" type="password" />
<div id="divResult"></div>
```

```odin
// Backend - Bind handlers
webui.bind(window, "btnLogin", handle_login_click)
webui.bind(window, "txtUsername", handle_username_input)
```

```odin
handle_login_click :: proc "c" (e: ^webui.Event) {
    username := webui.get_string_by_id(e.window, "txtUsername")
    password := webui.get_string_by_id(e.window, "txtPassword")
    
    // Process login...
    result := process_login(username, password)
    
    // Update UI
    webui.set_inner_html(e.window, "divResult", result)
}
```

**When to Use**:
- Button clicks
- Form submissions
- UI interactions

**Advantages**:
- Simple mapping
- No manual event handling
- Tight integration with UI

**Disadvantages**:
- Tightly coupled to UI structure
- Not suitable for complex logic

---

### 4. Channels (Full-Duplex)

**Pattern**: Bidirectional streaming  
**File**: `src/lib/comms/comms.odin` - Channel section

Create persistent channels for real-time communication:

```typescript
// Frontend - Create channel
const chatChannel = webui.channel('chat');

chatChannel.on('message', (msg) => {
    console.log('Received:', msg);
});

chatChannel.send({ text: 'Hello everyone!' });
```

```odin
// Backend - Manage channels
channel_create("chat")

channel_on("chat", proc(win: webui.Window, data: string) {
    fmt.printf("Chat message: %s\n", data)
})

// Broadcast to channel
channel_send("chat", `{"sender":"user","text":"Hello!"}`)
```

**When to Use**:
- Chat applications
- Live dashboards
- Real-time collaboration
- Gaming

**Advantages**:
- Real-time bidirectional
- Persistent connections
- Low latency

**Disadvantages**:
- More complex state management
- Connection lifecycle handling

---

### 5. Message Queue

**Pattern**: Asynchronous processing  
**File**: `src/lib/comms/comms.odin` - Queue section

Queue messages for background processing:

```odin
// Define message
Task_Message :: struct {
    id:       string,
    type:     string,
    payload:  string,
    priority: int,
}

// Enqueue
msg := Task_Message{
    id:       generate_id(),
    type:     "export",
    payload:  data,
    priority: 1,
}
queue_push(msg)

// Worker processes queue
task_worker :: proc() {
    for {
        msg := queue_pop()
        if msg.id != "" {
            process_task(msg)
        }
        time.sleep(100 * time.Millisecond)
    }
}
```

**When to Use**:
- Background tasks
- Batch processing
- Long-running operations
- Rate limiting

**Advantages**:
- Load leveling
- Async processing
- Retry support

**Disadvantages**:
- More complex
- No immediate feedback

---

### 6. Binary Protocol

**Pattern**: Compact binary format  
**File**: `src/lib/comms/comms.odin` - Binary section

Use binary encoding for performance:

```odin
// Encode
Msg_Type :: enum {
    Ping = 1,
    Pong = 2,
    Data = 3,
}

binary_encode :: proc(msg_type: Msg_Type, payload: []u8) -> []u8 {
    buffer := make([]u8, 8 + len(payload))
    
    // Header
    buffer[0] = 0xAB  // Magic byte 1
    buffer[1] = 0xCD  // Magic byte 2
    buffer[2] = 1     // Version
    buffer[3] = cast(u8)msg_type
    
    // Length
    *cast(^u32)&buffer[4] = cast(u32)len(payload)
    
    // Payload
    copy(buffer[8..], payload)
    
    return buffer
}

// Decode
binary_decode :: proc(data: []u8) -> (Msg_Type, []u8) {
    if len(data) < 8 || data[0] != 0xAB || data[1] != 0xCD {
        return 0, nil
    }
    
    msg_type := cast(Msg_Type)data[3]
    length := *cast(^u32)&data[4]
    payload := data[8:8+length]
    
    return msg_type, payload
}
```

**When to Use**:
- High-frequency updates
- Large data transfers
- Performance-critical paths

**Advantages**:
- Smaller payload (~30-60% of JSON)
- Faster parsing
- Type-safe with schema

**Disadvantages**:
- Not human-readable
- Requires schema definition

---

## Comparison Matrix

| Approach | Latency | Complexity | Real-time | Delivery | Best For |
|----------|---------|------------|-----------|----------|----------|
| **RPC** | Low | Low | No | Guaranteed | User actions |
| **Event Bus** | Low | Medium | Yes | Fire-and-forget | Notifications |
| **Direct Binding** | Lowest | Low | No | Guaranteed | UI clicks |
| **Channels** | Very Low | Medium | Yes | Guaranteed | Chat, live apps |
| **Message Queue** | Medium | High | No | Best-effort | Background tasks |
| **Binary** | Very Low | Medium | Yes | Guaranteed | High-perf data |

---

## Recommended Architecture

For most applications, use a hybrid approach:

```
┌─────────────────────────────────────────────────────────────┐
│                    Communication Stack                       │
├─────────────────────────────────────────────────────────────┤
│  RPC Layer     │  User actions requiring response          │
│  Event Layer   │  Notifications, live updates              │
│  Binding       │  UI interactions                          │
│  Channel Layer │  Real-time features (chat, etc.)           │
│  Binary Layer  │  Large transfers (optional)               │
└─────────────────────────────────────────────────────────────┘
```

### Typical Usage:

1. **RPC** - Login, form submissions, data fetch
2. **Events** - System notifications, user status changes
3. **Binding** - Button clicks, form inputs
4. **Channels** - Chat, live notifications
5. **Queue** - File exports, bulk operations

---

## Implementation Files

| File | Description |
|------|-------------|
| `src/lib/webui_lib/webui.odin` | WebUI FFI bindings |
| `src/lib/events/event_bus.odin` | Type-safe event system |
| `src/lib/events/handlers.odin` | Typed event helpers |
| `src/lib/comms/comms.odin` | Unified communication |

---

## See Also

- [05_COMMUNICATION_EXAMPLES.md](05_COMMUNICATION_EXAMPLES.md) - Working examples
- [src/lib/comms/comms.odin](../src/lib/comms/comms.odin) - Implementation
- [src/lib/events/event_bus.odin](../src/lib/events/event_bus.odin) - Events
