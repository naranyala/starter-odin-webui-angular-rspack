# Communication Examples

## Overview

Working examples of backend-frontend communication patterns in Odin + Angular.

---

## 1. RPC Example

### Backend (Odin)

```odin
package main

import "core:fmt"
import webui "src/lib/webui_lib"

handle_login :: proc "c" (e: ^webui.Event) {
    params := webui.event_get_string(e)
    fmt.printf("Login request: %s\n", params)
    
    // Process login
    // Return response
    webui.event_return_string(e, `{"token":"abc123","user":{"name":"John"}}`)
}

handle_get_data :: proc "c" (e: ^webui.Event) {
    data := webui.event_get_string(e)
    fmt.printf("Get data: %s\n", data)
    
    // Fetch data
    response := `{"items":[{"id":1,"name":"Item 1"}]}`
    webui.event_return_string(e, response)
}

main :: proc() {
    window := webui.new_window()
    
    // Bind RPC handlers
    webui.bind(window, "login", handle_login)
    webui.bind(window, "getData", handle_get_data)
    
    webui.show(window, html_content)
    webui.wait()
}
```

### Frontend (Angular)

```typescript
// service
@Injectable({ providedIn: 'root' })
export class ApiService {
    async login(username: string, password: string): Promise<LoginResult> {
        return webui.call('login', { username, password });
    }
    
    async getData(id: string): Promise<Data> {
        return webui.call('getData', { id });
    }
}

// component
@Component({...})
export class LoginComponent {
    async onSubmit() {
        const result = await this.api.login(this.username, this.password);
        if (result.token) {
            this.router.navigate(['/dashboard']);
        }
    }
}
```

---

## 2. Event Bus Example

### Backend (Odin)

```odin
package main

import "core:fmt"
import "src/lib/events"
import "src/lib/errors"

User_Event :: struct {
    user_id: int,
    name:    string,
    action:  string,
}

on_user_joined :: proc(data: rawptr) {
    event := cast(^User_Event)data
    fmt.printf("User joined: %s (id=%d)\n", event.name, event.user_id)
}

on_user_left :: proc(data: rawptr) {
    event := cast(^User_Event)data
    fmt.printf("User left: %s (id=%d)\n", event.name, event.user_id)
}

main :: proc() {
    bus, err := events.create_event_bus()
    if err.code != errors.Error_Code.None {
        return
    }
    defer events.destroy_event_bus(&bus)

    // Subscribe to events
    events.on(&bus, User_Event, .User_Joined, on_user_joined)
    events.on(&bus, User_Event, .User_Left, on_user_left)

    // Emit events
    event := User_Event{user_id = 1, name = "John", action = "joined"}
    events.emit_typed(&bus, User_Event, .User_Joined, event)

    // Process queued events
    events.process_events(&bus)
}
```

### Frontend (Angular)

```typescript
@Injectable({ providedIn: 'root' })
export class EventBusService {
    private listeners = new Map<string, Function[]>();
    
    on(event: string, callback: Function) {
        if (!this.listeners.has(event)) {
            this.listeners.set(event, []);
            webui.on(event, (data: any) => this.emit(event, data));
        }
        this.listeners.get(event)!.push(callback);
    }
    
    private emit(event: string, data: any) {
        this.listeners.get(event)?.forEach(cb => cb(data));
    }
}

// Usage
constructor(private events: EventBusService) {
    this.events.on('user.joined', (data) => {
        console.log('User joined:', data);
    });
}
```

---

## 3. Channels Example

### Backend (Odin)

```odin
package main

import "core:fmt"
import "src/lib/comms"

Chat_Message :: struct {
    sender: string,
    text:   string,
    time:   i64,
}

on_chat_message :: proc(win: webui.Window, data: string) {
    fmt.Printf("Chat message: %s\n", data)
    
    // Broadcast to all subscribers
    comms.channel_send("chat", data)
}

on_user_join :: proc(win: webui.Window, data: string) {
    join_msg := fmt.Sprintf(`{"type":"join","user":"%s"}`, data)
    comms.channel_send("chat", join_msg)
}

main :: proc() {
    comms.comms_init()
    
    // Create channel
    comms.channel_create("chat")
    
    // Subscribe handlers
    comms.channel_on("chat", on_chat_message)
    comms.channel_on("chat", on_user_join)
    
    // Application runs...
}
```

### Frontend (Angular)

```typescript
@Injectable({ providedIn: 'root' })
export class ChatService {
    private messages$ = new Subject<ChatMessage>();
    
    constructor() {
        // Listen to channel
        webui.channel('chat').on('message', (msg) => {
            this.messages$.next(msg);
        });
    }
    
    sendMessage(text: string) {
        webui.channel('chat').send({ text, sender: this.currentUser });
    }
    
    getMessages(): Observable<ChatMessage> {
        return this.messages$.asObservable();
    }
}

@Component({
    template: `
        <div *ngFor="let msg of messages$ | async">
            {{ msg.sender }}: {{ msg.text }}
        </div>
        <input [(ngModel)]="newMessage" (keyup.enter)="send()"/>
    `
})
export class ChatComponent {
    messages$ = this.chatService.getMessages();
    
    send() {
        this.chatService.sendMessage(this.newMessage);
    }
}
```

---

## 4. Message Queue Example

### Backend (Odin)

```odin
package main

import "core:fmt"
import "src/lib/comms"

Task :: struct {
    id:       string,
    type:     string,
    payload:  string,
    status:   string,
}

task_queue: []comms.Message

process_export :: proc(task: Task) {
    fmt.printf("Processing export: %s\n", task.id)
    // ... export logic ...
    
    // Notify completion
    comms.event_bus_emit("task.completed", 
        fmt.Sprintf(`{"id":"%s","status":"completed"}`, task.id))
}

task_worker :: proc() {
    for {
        if len(task_queue) > 0 {
            msg := task_queue[0]
            task_queue = task_queue[1:]
            
            task := Task{
                id = msg.id,
                type = msg.type,
            }
            
            switch task.type {
            case "export":
                process_export(task)
            case "import":
                process_import(task)
            }
        }
        time.sleep(100 * time.Millisecond)
    }
}

on_create_task :: proc "c" (e: ^webui.Event) {
    params := webui.event_get_string(e)
    
    msg := comms.Message{
        id = generate_id(),
        type = extract_type(params),
        payload = params,
    }
    
    append(&task_queue, msg)
    
    webui.event_return_string(e, `{"taskId":"`+msg.id+`"}`)
}
```

### Frontend (Angular)

```typescript
@Injectable({ providedIn: 'root' })
export class TaskService {
    private tasks$ = new Subject<TaskUpdate>();
    
    createTask(type: string, data: any): Promise<string> {
        return webui.call('createTask', { type, data });
    }
    
    constructor(private events: EventBusService) {
        this.events.on('task.completed', (data) => {
            this.tasks$.next(data);
        });
    }
    
    getUpdates(): Observable<TaskUpdate> {
        return this.tasks$.asObservable();
    }
}

@Component({
    template: `
        <button (click)="export()">Export Data</button>
        <div *ngFor="let task of tasks$ | async">
            {{ task.id }}: {{ task.status }}
        </div>
    `
})
export class TaskComponent {
    tasks$ = this.taskService.getUpdates();
    
    async export() {
        const taskId = await this.taskService.createTask('export', { 
            format: 'csv' 
        });
    }
}
```

---

## 5. Complete Application Example

```odin
package main

import "core:fmt"
import "src/lib/di"
import "src/lib/errors"
import "src/lib/events"
import "src/services"
import "src/lib/comms"

main :: proc() {
    // Initialize DI
    inj, err := di.create_injector()
    if err.code != errors.Error_Code.None {
        fmt.printf("DI init failed: %s\n", err.message)
        return
    }
    defer di.destroy_injector(&inj)

    // Initialize event bus
    bus, err := events.create_event_bus()
    if err.code != errors.Error_Code.None {
        return
    }
    defer events.destroy_event_bus(&bus)

    // Register in DI
    di.register_value(&inj, "Event_Bus", &bus)

    // Create logger
    logger := services.logger_create()
    di.register_value(&inj, "Logger", logger)

    // Create services
    user_svc, err := services.user_service_create(&inj)
    if err.code != errors.Error_Code.None {
        return
    }

    // Initialize comms
    comms.comms_init()
    
    // Register RPC handlers
    comms.comms_rpc("user.add", handle_user_add)
    comms.comms_rpc("user.list", handle_user_list)
    
    // Subscribe to events
    comms.comms_on("user.created", on_user_created)

    // Create window
    window := webui.new_window()
    webui.bind(window, "appReady", handle_app_ready)
    
    webui.show(window, html_content)
    webui.wait()
}

handle_user_add :: proc "c" (e: ^webui.Event) -> string {
    params := webui.event_get_string(e)
    name := extract_field(params, "name")
    
    user_svc, _ := services.registry_get(services.User_Service)
    id, err := services.user_service_add(user_svc, name)
    
    if err.code == errors.Error_Code.None {
        return fmt.Sprintf(`{"id":%d,"name":"%s"}`, id, name)
    }
    return `{"error":"Failed to add user"}`
}
```

---

## See Also

- [04_COMMUNICATION_APPROACHES.md](04_COMMUNICATION_APPROACHES.md) - Communication patterns
- [01_DI_SYSTEM.md](01_DI_SYSTEM.md) - DI system
- [02_ERROR_HANDLING_GUIDE.md](02_ERROR_HANDLING_GUIDE.md) - Error handling
