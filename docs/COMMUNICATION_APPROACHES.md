# Backend-Frontend Communication Approaches

## Overview

This document explores various communication patterns, protocols, and data formats for Odin backend and Angular frontend applications without relying on HTTP/HTTPS.

## Architecture

```
+----------------------------------------------------------+
|                   Communication Layers                    |
+----------------------------------------------------------+
|  Application Layer  |  RPC  |  Events  |  Stream  | Msg  |
|  Data Format Layer  | JSON  |  Binary  |  MsgPack |      |
|  Transport Layer    |  WebUI Bridge (JavaScript <-> Odin) |
+----------------------------------------------------------+
```

## Communication Patterns

### 1. Remote Procedure Call (RPC)

#### Description

Frontend calls backend functions directly, similar to local function calls. This pattern follows a request-response model.

#### Architecture

```
+-------------+         +--------------+         +-------------+
|   Angular   | ------->|  WebUI RPC   | ------->|  Odin       |
|  Frontend   |  call   |   Proxy      |  bind   |  Handlers   |
+-------------+         +--------------+         +-------------+
      |                       |                        |
      |  Promise/Callback     |                        |
      +-----------------------+------------------------+
                              |     Response
```

#### Implementation

**Frontend (Angular Service)**

```typescript
export interface RpcRequest {
  id: number;
  method: string;
  params: any[];
}

export interface RpcResponse<T = any> {
  id: number;
  result?: T;
  error?: string;
}

@Injectable({ providedIn: 'root' })
export class RpcClientService {
  private requestId = 0;
  private pendingCalls = new Map<number, {
    resolve: (value: any) => void;
    reject: (reason: any) => void;
  }>();

  async call<T>(method: string, params: any[]): Promise<T> {
    const id = ++this.requestId;
    const request: RpcRequest = { id, method, params };
    
    return new Promise((resolve, reject) => {
      this.pendingCalls.set(id, { resolve, reject });
      (window as any).webui.rpcCall(JSON.stringify(request));
    });
  }

  handleResponse(responseStr: string): void {
    const response: RpcResponse = JSON.parse(responseStr);
    const pending = this.pendingCalls.get(response.id);
    if (pending) {
      if (response.error) {
        pending.reject(new Error(response.error));
      } else {
        pending.resolve(response.result);
      }
      this.pendingCalls.delete(response.id);
    }
  }
}
```

**Backend (Odin)**

```odin
Rpc_Request :: struct {
    id     : i64,
    method : string,
    params : string,
}

Rpc_Response :: struct {
    id     : i64,
    result : string,
    error  : string,
}

rpc_handle_call :: proc "c" (e : ^webui.Event) {
    request_json := webui.webui_get_string(e)
    request := parse_request(request_json)
    
    result := ""
    error := ""
    
    switch request.method {
    case "greet":
        result = handle_greet_rpc(request.params)
    case "getData":
        result = handle_get_data(request.params)
    default:
        error = "Method not found"
    }
    
    response := Rpc_Response{
        id = request.id,
        result = result,
        error = error,
    }
    
    response_json := format_response(response)
    script := fmt.Sprintf("window.rpcClient.handleResponse(%s)", response_json)
    webui.webui_run(my_window, script)
}
```

#### Advantages

- Simple, intuitive API
- Type-safe with proper definitions
- Easy to debug
- Familiar pattern for developers

#### Disadvantages

- Synchronous request/response
- Not suitable for real-time updates
- Requires method registration

#### Best For

- User authentication
- Data fetching
- Form submissions
- Configuration updates

---

### 2. Event-Driven (Publish-Subscribe)

#### Description

Components publish and subscribe to events asynchronously. This pattern enables loose coupling between components.

#### Architecture

```
+-------------+      +---------------------------------+
|   Angular   |----->|         Event Bus               |
|  Frontend   | pub  |  (Topic-based Message Broker)   |
+-------------+      +---------------------------------+
                            |         |         |
                            v         v         v
                      +--------+ +--------+ +--------+
                      | Odin   | | Odin   | | Angular|
                      |Handler | |Handler | |Subscriber|
                      +--------+ +--------+ +--------+
                         sub       sub       sub
```

#### Implementation

**Frontend (Event Bus Service)**

```typescript
type EventHandler = (data: any) => void;

@Injectable({ providedIn: 'root' })
export class EventBusService {
  private subscribers = new Map<string, Set<EventHandler>>();

  subscribe(topic: string, handler: EventHandler): Subscription {
    if (!this.subscribers.has(topic)) {
      this.subscribers.set(topic, new Set());
    }
    this.subscribers.get(topic)!.add(handler);
    (window as any).webui.subscribe(topic);
    
    return {
      unsubscribe: () => {
        this.subscribers.get(topic)?.delete(handler);
        (window as any).webui.unsubscribe(topic);
      }
    };
  }

  publish(topic: string, data: any): void {
    (window as any).webui.publishEvent(topic, JSON.stringify(data));
  }

  onEvent(topic: string, data: any): void {
    this.subscribers.get(topic)?.forEach(handler => handler(data));
  }
}
```

**Backend (Odin Event Bus)**

```odin
Event_Handler :: proc "c" (win : webui.Window, data : string)

Event_Bus :: struct {
    topics : map[string][]Event_Handler,
}

event_bus : Event_Bus

event_bus_init :: proc() {
    event_bus.topics = make(map[string][]Event_Handler)
}

event_bus_subscribe :: proc(topic : string, handler : Event_Handler) {
    handlers := event_bus.topics[topic]
    append(&handlers, handler)
    event_bus.topics[topic] = handlers
}

event_bus_publish :: proc(topic : string, data : string) {
    handlers := event_bus.topics[topic]
    for handler in handlers {
        handler(my_window, data)
    }
    
    // Also publish to frontend
    script := fmt.Sprintf("eventBus.onEvent('%s', %s)", topic, data)
    webui.webui_run(my_window, script)
}

// Usage
on_user_login :: proc "c" (win : webui.Window, data : string) {
    fmt.printf("User logged in: %s\n", data)
}

event_bus_subscribe("user.login", on_user_login)
```

#### Advantages

- Decoupled architecture
- Real-time updates
- Multiple subscribers
- Scalable

#### Disadvantages

- More complex to debug
- Event ordering can be tricky
- Need to manage subscriptions

#### Best For

- Notifications
- State synchronization
- User activity tracking
- System events

---

### 3. Message Queue

#### Description

Messages are queued and processed asynchronously with guaranteed delivery.

#### Architecture

```
+-------------+      +--------------+      +-------------+
|   Frontend  |----->|  Message     |----->|   Backend   |
|             | send |  Queue       | recv |  Processor  |
+-------------+      +--------------+      +-------------+
                            |
                            v
                     +--------------+
                     |  Ack/Nack    |
                     +--------------+
```

#### Implementation

**Message Format**

```odin
Message :: struct {
    id          : string,
    type        : string,
    payload     : string,
    timestamp   : i64,
    priority    : i32,
    reply_to    : string,
    correlation : string,
}
```

**Backend Queue**

```odin
Message_Queue :: struct {
    messages : []Message,
    mutex    : sync.Mutex,
}

queue : Message_Queue

queue_push :: proc(msg : Message) {
    sync.lock(&queue.mutex)
    append(&queue.messages, msg)
    sync.unlock(&queue.mutex)
}

queue_pop :: proc() -> Message {
    sync.lock(&queue.mutex)
    defer sync.unlock(&queue.mutex)
    if len(queue.messages) == 0 {
        return Message{}
    }
    msg := queue.messages[0]
    queue.messages = queue.messages[1..]
    return msg
}

queue_worker :: proc "c" () {
    for {
        msg := queue_pop()
        if msg.id != "" {
            process_message(msg)
        }
        time.sleep(10 * time.Millisecond)
    }
}
```

#### Advantages

- Load leveling
- Guaranteed delivery
- Retry support
- Backpressure handling

#### Disadvantages

- More complex
- Requires queue management
- Potential message duplication

#### Best For

- Background tasks
- Batch processing
- File exports/imports
- Email sending

---

### 4. Binary Protocol

#### Description

Use binary format instead of JSON for improved efficiency and smaller payload size.

#### Data Format Comparison

| Format | Size | Speed | Readability |
|--------|------|-------|-------------|
| JSON | 100% | 1x | Human-readable |
| MessagePack | ~60% | 3x | Binary |
| Protocol Buffers | ~40% | 5x | Binary |
| Custom Binary | ~30% | 10x | Binary |

#### Binary Message Format

```
+---------+---------+----------+---------+----------+
|  Magic  | Version | Msg Type | Length  | Payload  |
|  0xABCD |  u8     |   u8     |  u32    |  [...]   |
+---------+---------+----------+---------+----------+
```

#### Implementation

```odin
BINARY_MAGIC : u16 = 0xABCD

Binary_Message :: struct {
    version : u8,
    msg_type : u8,
    length : u32,
    payload : []u8,
}

// Encode
binary_encode :: proc(msg : Binary_Message) -> []u8 {
    buffer := make([]u8, 8 + len(msg.payload))
    
    // Write magic
    buffer[0] = 0xAB
    buffer[1] = 0xCD
    
    // Write header
    buffer[2] = msg.version
    buffer[3] = msg.msg_type
    endian.native_to_little(&buffer[4..8], msg.length)
    
    // Write payload
    copy(buffer[8..], msg.payload)
    
    return buffer
}

// Decode
binary_decode :: proc(data : []u8) -> Binary_Message {
    if len(data) < 8 || data[0] != 0xAB || data[1] != 0xCD {
        return Binary_Message{}
    }
    
    msg := Binary_Message{
        version = data[2],
        msg_type = data[3],
        length = endian.little_to_native(u32, data[4..8]),
        payload = data[8..],
    }
    return msg
}
```

#### Advantages

- Smaller payload size
- Faster parsing
- Type safety
- Version support

#### Disadvantages

- Not human-readable
- Requires schema definition
- More complex debugging

#### Best For

- Large data transfers
- High-frequency updates
- Performance-critical paths
- Binary file transfers

---

### 5. Full-Duplex Channels

#### Description

Emulate WebSocket-like bidirectional communication over the WebUI bridge.

#### Architecture

```
+-------------+         +--------------+         +-------------+
|   Angular   | <-----> |  WebUI       | <-----> |   Odin      |
|  Frontend   |  full   |  Channel     |  full   |   Backend   |
|             |  duplex |              |  duplex |             |
+-------------+         +--------------+         +-------------+
```

#### Implementation

**Frontend (Channel Service)**

```typescript
@Injectable({ providedIn: 'root' })
export class ChannelService {
  private channels = new Map<string, Subject<any>>();

  createChannel<T>(name: string): Observable<ChannelMessage<T>> {
    if (!this.channels.has(name)) {
      this.channels.set(name, new Subject<ChannelMessage<T>>());
      (window as any).webui.createChannel(name);
    }
    return this.channels.get(name)!.asObservable();
  }

  send<T>(channel: string, data: T): void {
    (window as any).webui.sendToChannel(channel, JSON.stringify(data));
  }

  onMessage(channel: string, data: any): void {
    this.channels.get(channel)?.next(data);
  }
}
```

**Backend (Channel Manager)**

```odin
Channel_Handler :: proc "c" (win : webui.Window, data : string)

Channel :: struct {
    name : string,
    handlers : []Channel_Handler,
}

Channel_Manager :: struct {
    channels : map[string]Channel,
}

channel_manager : Channel_Manager

channel_create :: proc(name : string) {
    channel := Channel{
        name = name,
        handlers = make([]Channel_Handler, 0),
    }
    channel_manager.channels[name] = channel
}

channel_send :: proc(name : string, data : string) {
    channel := channel_manager.channels[name]
    for handler in channel.handlers {
        handler(my_window, data)
    }
    
    // Forward to frontend
    script := fmt.Sprintf("channelManager.onMessage('%s', %s)", name, data)
    webui.webui_run(my_window, script)
}

channel_subscribe :: proc(name : string, handler : Channel_Handler) {
    channel := channel_manager.channels[name]
    append(&channel.handlers, handler)
    channel_manager.channels[name] = channel
}
```

#### Advantages

- Real-time bidirectional
- Multiple channels
- Event streaming
- Low latency

#### Disadvantages

- More complex state management
- Connection lifecycle management
- Need to handle disconnections

#### Best For

- Chat applications
- Collaborative editing
- Live dashboards
- Gaming

---

## Comparison Matrix

| Approach | Latency | Complexity | Real-time | Best For |
|----------|---------|------------|-----------|----------|
| RPC | Low | Low | No | Simple calls |
| Event-Driven | Low | Medium | Yes | Decoupled systems |
| Message Queue | Medium | High | No | Background tasks |
| Binary Protocol | Very Low | Medium | Yes | High performance |
| Full-Duplex | Very Low | Medium | Yes | Real-time apps |

## Recommendation

For Odin + Angular WebUI applications, use a hybrid approach:

1. **Start with RPC** - Simple, easy to implement for user actions
2. **Add Event-Driven** - For real-time notifications and updates
3. **Consider Binary** - If performance becomes an issue

### Hybrid Architecture

```
+----------------------------------------------------------+
|                  Communication Stack                      |
+----------------------------------------------------------+
|  RPC Layer     |  User actions, data fetch              |
|  Event Layer   |  Notifications, live updates           |
|  Binary Layer  |  Large data transfers (optional)       |
+----------------------------------------------------------+
```

## Implementation Guide

### Step 1: Setup Communication Module

```odin
import comms "./comms"

main :: proc() {
    // Initialize all communication systems
    comms.comms_init()
    
    // Register RPC methods
    comms.comms_rpc("user.login", handle_login)
    comms.comms_rpc("data.fetch", handle_fetch)
    
    // Register event handlers
    comms.comms_on("notification.new", on_notification)
    
    // Create channels
    comms.comms_channel("chat")
    
    // Start application
    webui.wait()
}
```

### Step 2: Frontend Services

```typescript
// app.module.ts
@NgModule({
  providers: [
    RpcClientService,
    EventBusService,
    ChannelService,
    CommunicationService
  ]
})
export class AppModule {}

// Usage in component
constructor(
  private rpc: RpcClientService,
  private events: EventBusService,
  private comms: CommunicationService
) {}
```

### Step 3: Unified Communication

```typescript
// communication.service.ts
export enum CommProtocol {
  RPC = 'rpc',
  EVENTS = 'events',
  CHANNELS = 'channels'
}

@Injectable({ providedIn: 'root' })
export class CommunicationService {
  constructor(
    private rpc: RpcClientService,
    private events: EventBusService,
    private channel: ChannelService
  ) {}

  call<T>(method: string, params?: any[]): Promise<T> {
    return this.rpc.call(method, params);
  }

  on<T>(topic: string, handler: (data: T) => void): Subscription {
    return this.events.subscribe(topic, handler);
  }

  emit(topic: string, data: any): void {
    this.events.publish(topic, data);
  }
}
```

## See Also

- `docs/COMMUNICATION_EXAMPLES.md` - Complete usage examples
- `comms/comms.odin` - Communication layer implementation
- `frontend/src/app/services/communication.service.ts` - Angular services
