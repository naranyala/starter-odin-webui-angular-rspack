# Communication Examples

## Overview

This document provides complete working examples for backend-frontend communication patterns in Odin + Angular applications.

## Table of Contents

1. [RPC Pattern Examples](#rpc-pattern-examples)
2. [Event Bus Examples](#event-bus-examples)
3. [Channel Examples](#channel-examples)
4. [Message Queue Examples](#message-queue-examples)
5. [Backend Handler Examples](#backend-handler-examples)

---

## RPC Pattern Examples

### User Service

**Backend (Odin)**

```odin
package main

import "core:fmt"
import "core:c"
import webui "./webui_lib"

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

// User login handler
handle_login :: proc "c" (e : ^webui.Event) {
    params_json := webui.webui_get_string(e)
    
    // Parse username and password from JSON
    username := parse_username(params_json)
    password := parse_password(params_json)
    
    // Validate credentials
    if validate_credentials(username, password) {
        token := generate_token(username)
        response := fmt.Sprintf(`{"token":"%s","user":{"name":"%s"}}`, token, username)
        webui.webui_return_string(e, response)
    } else {
        webui.webui_return_string(e, `{"error":"Invalid credentials"}`)
    }
}

// Get user profile handler
handle_get_profile :: proc "c" (e : ^webui.Event) {
    user_id := webui.webui_get_string(e)
    
    // Fetch user from database
    user_data := fetch_user(user_id)
    
    if user_data != nil {
        webui.webui_return_string(e, user_data)
    } else {
        webui.webui_return_string(e, `{"error":"User not found"}`)
    }
}

main :: proc() {
    window := webui.new_window()
    
    // Bind RPC handlers
    webui.bind(window, "user.login", handle_login)
    webui.bind(window, "user.getProfile", handle_get_profile)
    
    webui.show(window, html_content)
    webui.wait()
}
```

**Frontend (Angular)**

```typescript
// user.service.ts
@Injectable({ providedIn: 'root' })
export class UserService {
  constructor(private rpc: RpcClientService) {}

  async login(username: string, password: string): Promise<LoginResult> {
    return this.rpc.call<LoginResult>('user.login', [username, password]);
  }

  async getProfile(userId: string): Promise<User> {
    return this.rpc.call<User>('user.getProfile', [userId]);
  }
}

// login.component.ts
@Component({
  selector: 'app-login',
  template: `
    <form (ngSubmit)="onLogin()">
      <input [(ngModel)]="username" name="username" placeholder="Username">
      <input [(ngModel)]="password" name="password" type="password">
      <button type="submit">Login</button>
    </form>
    <div *ngIf="error">{{ error }}</div>
  `
})
export class LoginComponent {
  username = '';
  password = '';
  error = '';

  constructor(
    private userService: UserService,
    private router: Router
  ) {}

  async onLogin() {
    try {
      const result = await this.userService.login(this.username, this.password);
      localStorage.setItem('token', result.token);
      this.router.navigate(['/dashboard']);
    } catch (err) {
      this.error = err.message;
    }
  }
}
```

---

## Event Bus Examples

### Notification System

**Backend (Odin)**

```odin
package main

import "core:fmt"
import "core:c"
import comms "./comms"

// Send notification to all subscribers
send_notification :: proc(title : string, message : string) {
    data := fmt.Sprintf(`{"title":"%s","message":"%s"}`, title, message)
    comms.event_bus_emit("notification.new", data)
}

// Handle user action that triggers notification
on_user_registered :: proc "c" (win : webui.Window, data : string) {
    fmt.printf("New user registered: %s\n", data)
    
    // Send welcome notification
    send_notification("Welcome", "Your account has been created!")
    
    // Send admin notification
    admin_data := fmt.Sprintf(`{"type":"admin","userId":"%s"}`, data)
    comms.event_bus_emit("admin.userRegistered", admin_data)
}

main :: proc() {
    comms.comms_init()
    
    // Register event handlers
    comms.comms_on("user.registered", on_user_registered)
    comms.comms_on("order.completed", on_order_completed)
    
    webui.wait()
}
```

**Frontend (Angular)**

```typescript
// notification.service.ts
@Injectable({ providedIn: 'root' })
export class NotificationService {
  private notifications: Notification[] = [];
  private notificationSubject = new Subject<Notification>();

  public notifications$ = this.notificationSubject.asObservable();

  constructor(private eventBus: EventBusService) {
    // Subscribe to notification events
    this.eventBus.subscribe('notification.new', (data) => {
      this.addNotification(data);
    });
  }

  private addNotification(data: any) {
    const notification: Notification = {
      id: Date.now().toString(),
      title: data.title,
      message: data.message,
      timestamp: new Date(),
      read: false
    };
    
    this.notifications.push(notification);
    this.notificationSubject.next(notification);
  }

  markAsRead(id: string) {
    const notification = this.notifications.find(n => n.id === id);
    if (notification) {
      notification.read = true;
    }
  }
}

// notification.component.ts
@Component({
  selector: 'app-notifications',
  template: `
    <div class="notifications">
      <div *ngFor="let notification of notifications" 
           [class.read]="notification.read"
           class="notification-item">
        <h4>{{ notification.title }}</h4>
        <p>{{ notification.message }}</p>
        <small>{{ notification.timestamp | date:'short' }}</small>
      </div>
    </div>
  `,
  styles: [`
    .notification-item {
      padding: 10px;
      border-left: 3px solid #2196F3;
      margin-bottom: 10px;
    }
    .notification-item.read {
      opacity: 0.6;
      border-left-color: #9E9E9E;
    }
  `]
})
export class NotificationsComponent implements OnInit, OnDestroy {
  notifications: Notification[] = [];
  private subscription: Subscription;

  constructor(private notificationService: NotificationService) {}

  ngOnInit() {
    this.subscription = this.notificationService.notifications$
      .subscribe(notification => {
        this.notifications.unshift(notification);
      });
  }

  ngOnDestroy() {
    this.subscription.unsubscribe();
  }
}
```

---

## Channel Examples

### Real-Time Chat

**Backend (Odin)**

```odin
package main

import "core:fmt"
import "core:c"
import comms "./comms"

Chat_Message :: struct {
    sender : string,
    text : string,
    timestamp : i64,
}

// Handle incoming chat message
on_chat_message :: proc "c" (win : webui.Window, data : string) {
    fmt.printf("Chat message received: %s\n", data)
    
    // Parse message
    msg := parse_chat_message(data)
    
    // Add timestamp
    msg.timestamp = time.now()
    
    // Broadcast to all chat participants
    formatted := fmt.Sprintf(`{"sender":"%s","text":"%s","timestamp":%d}`,
        msg.sender, msg.text, msg.timestamp)
    
    comms.channel_send("chat.general", formatted)
    
    // Store in database
    store_chat_message(msg)
}

// Handle user joining chat
on_user_join :: proc "c" (win : webui.Window, data : string) {
    username := data
    
    // Notify others
    join_msg := fmt.Sprintf(`{"type":"join","username":"%s"}`, username)
    comms.channel_send("chat.general", join_msg)
    
    fmt.printf("%s joined the chat\n", username)
}

main :: proc() {
    comms.comms_init()
    
    // Create chat channel
    comms.comms_channel("chat.general")
    
    // Register handlers
    comms.comms_on("chat.message", on_chat_message)
    comms.comms_on("chat.join", on_user_join)
    
    webui.wait()
}
```

**Frontend (Angular)**

```typescript
// chat.service.ts
export interface ChatMessage {
  sender: string;
  text: string;
  timestamp: number;
}

@Injectable({ providedIn: 'root' })
export class ChatService {
  private messages: ChatMessage[] = [];
  private messageSubject = new Subject<ChatMessage>();

  public messages$ = this.messageSubject.asObservable();

  constructor(private channelService: ChannelService) {}

  joinChannel(username: string) {
    const channel = this.channelService.join<ChatMessage>('chat.general');
    
    // Subscribe to messages
    channel.messages$.subscribe(msg => {
      this.messages.push(msg.data);
      this.messageSubject.next(msg.data);
    });
    
    // Send join notification
    channel.send({ sender: 'system', text: `${username} joined`, timestamp: Date.now() });
    
    return channel;
  }

  sendMessage(username: string, text: string) {
    const message: ChatMessage = {
      sender: username,
      text: text,
      timestamp: Date.now()
    };
    
    // Send through channel
    // Implementation depends on channel service
  }

  getHistory(): ChatMessage[] {
    return this.messages;
  }
}

// chat.component.ts
@Component({
  selector: 'app-chat',
  template: `
    <div class="chat-container">
      <div class="messages" #messagesContainer>
        <div *ngFor="let msg of messages" 
             [class.own]="msg.sender === currentUsername"
             class="message">
          <strong>{{ msg.sender }}:</strong>
          <span>{{ msg.text }}</span>
          <small>{{ msg.timestamp | date:'HH:mm' }}</small>
        </div>
      </div>
      <div class="input-area">
        <input [(ngModel)]="newMessage" 
               (keyup.enter)="sendMessage()"
               placeholder="Type a message...">
        <button (click)="sendMessage()">Send</button>
      </div>
    </div>
  `,
  styles: [`
    .chat-container {
      display: flex;
      flex-direction: column;
      height: 400px;
    }
    .messages {
      flex: 1;
      overflow-y: auto;
      padding: 10px;
    }
    .message {
      margin-bottom: 10px;
      padding: 5px 10px;
      border-radius: 5px;
    }
    .message.own {
      background: #E3F2FD;
      text-align: right;
    }
    .input-area {
      display: flex;
      padding: 10px;
      border-top: 1px solid #eee;
    }
    .input-area input {
      flex: 1;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 5px;
    }
    .input-area button {
      margin-left: 10px;
      padding: 10px 20px;
      background: #2196F3;
      color: white;
      border: none;
      border-radius: 5px;
    }
  `]
})
export class ChatComponent implements OnInit, OnDestroy {
  messages: ChatMessage[] = [];
  newMessage = '';
  currentUsername = 'User';
  private channel: any;
  private subscription: Subscription;

  constructor(private chatService: ChatService) {}

  ngOnInit() {
    this.channel = this.chatService.joinChannel(this.currentUsername);
    
    this.subscription = this.chatService.messages$
      .subscribe(msg => {
        this.messages.push(msg);
        this.scrollToBottom();
      });
  }

  sendMessage() {
    if (this.newMessage.trim()) {
      this.chatService.sendMessage(this.currentUsername, this.newMessage);
      this.newMessage = '';
    }
  }

  scrollToBottom() {
    setTimeout(() => {
      const container = document.querySelector('#messagesContainer');
      if (container) {
        container.scrollTop = container.scrollHeight;
      }
    });
  }

  ngOnDestroy() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
    if (this.channel) {
      this.channel.leave();
    }
  }
}
```

---

## Message Queue Examples

### Background Task Processing

**Backend (Odin)**

```odin
package main

import "core:fmt"
import "core:c"
import comms "./comms"

Task :: struct {
    id : string,
    type : string,
    status : string,
    progress : i32,
    result : string,
}

task_queue : comms.Message_Queue
task_status : map[string]Task

// Process export task
process_export :: proc(task : Task) {
    fmt.printf("Processing export task: %s\n", task.id)
    
    // Update status to processing
    task.status = "processing"
    task_status[task.id] = task
    notify_task_update(task)
    
    // Simulate work
    for i in 0..100 {
        task.progress = i
        if i % 10 == 0 {
            notify_task_update(task)
        }
        time.sleep(100 * time.Millisecond)
    }
    
    // Complete task
    task.status = "completed"
    task.result = "export.csv"
    task_status[task.id] = task
    notify_task_update(task)
}

notify_task_update :: proc(task : Task) {
    data := fmt.Sprintf(`{"id":"%s","status":"%s","progress":%d}`,
        task.id, task.status, task.progress)
    comms.event_bus_emit("task.update", data)
}

// Handle task creation from frontend
on_create_task :: proc "c" (win : webui.Window, data : string) {
    task_type := parse_task_type(data)
    
    task := Task{
        id = generate_task_id(),
        type = task_type,
        status = "pending",
        progress = 0,
    }
    
    task_status[task.id] = task
    
    // Add to queue
    msg := comms.Message{
        id = task.id,
        type = task_type,
        payload = data,
    }
    comms.queue_push(&task_queue, msg)
    
    // Return task ID to frontend
    response := fmt.Sprintf(`{"taskId":"%s"}`, task.id)
    webui.webui_return_string(win, response)
}

// Task worker
task_worker :: proc "c" () {
    for {
        msg := comms.queue_pop(&task_queue)
        if msg.id != "" {
            task := task_status[msg.id]
            switch msg.type {
            case "export":
                process_export(task)
            case "import":
                process_import(task)
            }
        }
        time.sleep(100 * time.Millisecond)
    }
}

main :: proc() {
    comms.comms_init()
    comms.queue_init(&task_queue)
    
    // Start worker thread
    go task_worker()
    
    // Register handlers
    comms.comms_on("task.create", on_create_task)
    
    webui.wait()
}
```

**Frontend (Angular)**

```typescript
// task.service.ts
export interface Task {
  id: string;
  type: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  progress: number;
  result?: string;
}

@Injectable({ providedIn: 'root' })
export class TaskService {
  private tasks = new Map<string, Task>();
  private taskSubject = new Subject<Task>();

  public tasks$ = this.taskSubject.asObservable();

  constructor(private eventBus: EventBusService, private rpc: RpcClientService) {
    // Listen for task updates
    this.eventBus.subscribe('task.update', (data) => {
      this.updateTask(data);
    });
  }

  async createExportTask(): Promise<string> {
    const result = await this.rpc.call<{ taskId: string }>('task.create', {
      type: 'export',
      format: 'csv'
    });
    return result.taskId;
  }

  private updateTask(data: any) {
    const task: Task = {
      id: data.id,
      type: data.type || 'unknown',
      status: data.status,
      progress: data.progress,
      result: data.result
    };
    
    this.tasks.set(task.id, task);
    this.taskSubject.next(task);
  }

  getTask(taskId: string): Task | undefined {
    return this.tasks.get(taskId);
  }

  getAllTasks(): Task[] {
    return Array.from(this.tasks.values());
  }
}

// tasks.component.ts
@Component({
  selector: 'app-tasks',
  template: `
    <div class="tasks">
      <button (click)="startExport()">Export Data</button>
      <button (click)="startImport()">Import Data</button>
      
      <div class="task-list">
        <div *ngFor="let task of tasks" class="task-item">
          <div class="task-header">
            <span class="task-type">{{ task.type }}</span>
            <span class="task-status">{{ task.status }}</span>
          </div>
          <div class="task-progress">
            <div class="progress-bar" [style.width.%]="task.progress"></div>
            <span>{{ task.progress }}%</span>
          </div>
          <div *ngIf="task.result" class="task-result">
            Result: {{ task.result }}
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .task-item {
      padding: 15px;
      border: 1px solid #ddd;
      border-radius: 5px;
      margin-bottom: 10px;
    }
    .task-header {
      display: flex;
      justify-content: space-between;
      margin-bottom: 10px;
    }
    .task-status {
      padding: 2px 8px;
      border-radius: 3px;
      font-size: 12px;
    }
    .task-status.pending { background: #FFF3E0; }
    .task-status.processing { background: #E3F2FD; }
    .task-status.completed { background: #E8F5E9; }
    .task-progress {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .progress-bar {
      height: 8px;
      background: #2196F3;
      border-radius: 4px;
      flex: 1;
    }
  `]
})
export class TasksComponent implements OnInit, OnDestroy {
  tasks: Task[] = [];
  private subscription: Subscription;

  constructor(private taskService: TaskService) {}

  ngOnInit() {
    this.subscription = this.taskService.tasks$
      .subscribe(task => {
        const index = this.tasks.findIndex(t => t.id === task.id);
        if (index >= 0) {
          this.tasks[index] = task;
        } else {
          this.tasks.push(task);
        }
      });
  }

  async startExport() {
    const taskId = await this.taskService.createExportTask();
    console.log('Export task created:', taskId);
  }

  startImport() {
    // Similar implementation for import
  }

  ngOnDestroy() {
    this.subscription.unsubscribe();
  }
}
```

---

## Backend Handler Examples

### Complete Handler Setup

```odin
package main

import "core:fmt"
import "core:c"
import comms "./comms"
import webui "./webui_lib"

my_window : webui.Window

// =============================================================================
// Initialize Communication Handlers
// =============================================================================

init_communication :: proc() {
    comms.comms_init()

    // Register RPC methods
    comms.comms_rpc("user.login", handle_user_login)
    comms.comms_rpc("user.register", handle_user_register)
    comms.comms_rpc("data.fetch", handle_data_fetch)
    comms.comms_rpc("data.save", handle_data_save)

    // Register Event handlers
    comms.comms_on("user.loggedin", on_user_loggedin)
    comms.comms_on("user.logout", on_user_logout)
    comms.comms_on("notification.clearAll", on_clear_notifications)

    // Create channels
    comms.comms_channel("chat.general")
    comms.comms_channel("commands")
    comms.comms_channel("notifications")
}

// =============================================================================
// RPC Handlers
// =============================================================================

handle_user_login :: proc "c" (e : ^webui.Event) -> string {
    params := webui.webui_get_string(e)
    
    // Parse credentials
    username := extract_field(params, "username")
    password := extract_field(params, "password")
    
    // Validate
    if validate_user(username, password) {
        token := generate_session_token(username)
        return fmt.Sprintf(`{"token":"%s","user":{"name":"%s"}}`, token, username)
    }
    
    return `{"error":"Invalid credentials"}`
}

handle_user_register :: proc "c" (e : ^webui.Event) -> string {
    params := webui.webui_get_string(e)
    
    username := extract_field(params, "username")
    email := extract_field(params, "email")
    
    if create_user(username, email) {
        // Emit event
        comms.event_bus_emit("user.registered", username)
        return `{"success":true}`
    }
    
    return `{"error":"Registration failed"}`
}

handle_data_fetch :: proc "c" (e : ^webui.Event) -> string {
    entity := webui.webui_get_string(e)
    
    data := fetch_from_database(entity)
    if data != nil {
        return data
    }
    
    return `{"error":"Data not found"}`
}

handle_data_save :: proc "c" (e : ^webui.Event) -> string {
    params := webui.webui_get_string(e)
    
    if save_to_database(params) {
        return `{"success":true}`
    }
    
    return `{"error":"Save failed"}`
}

// =============================================================================
// Event Handlers
// =============================================================================

on_user_loggedin :: proc "c" (win : webui.Window, data : string) {
    fmt.printf("User logged in: %s\n", data)
    
    // Send welcome notification
    notification := fmt.Sprintf(`{"message":"Welcome back!","type":"success"}`)
    comms.event_bus_emit("notification.new", notification)
    
    // Log activity
    log_activity("login", data)
}

on_user_logout :: proc "c" (win : webui.Window, data : string) {
    fmt.printf("User logged out: %s\n", data)
    log_activity("logout", data)
}

on_clear_notifications :: proc "c" (win : webui.Window, data : string) {
    fmt.println("Clearing all notifications")
    clear_notifications_database()
}

// =============================================================================
// Channel Handlers
// =============================================================================

on_chat_message :: proc "c" (win : webui.Window, data : string) {
    fmt.printf("Chat message: %s\n", data)
    
    // Parse and validate
    msg := parse_chat_message(data)
    if is_valid_message(msg) {
        // Store
        store_chat_message(msg)
        
        // Broadcast
        comms.channel_send("chat.general", data)
    }
}

on_command :: proc "c" (win : webui.Window, data : string) {
    fmt.printf("Command received: %s\n", data)
    
    command := parse_command(data)
    switch command.action {
    case "refresh":
        comms.event_bus_emit("dashboard.refresh", `{"timestamp":0}`)
    case "clearCache":
        clear_application_cache()
        comms.event_bus_emit("system.cacheCleared", `{}`)
    case "export":
        start_export_task(command.params)
    }
}

// =============================================================================
// Message Queue Processor
// =============================================================================

task_processor :: proc "c" () {
    for {
        msg := comms.queue_pop()
        if msg.id != "" {
            process_task(msg)
        }
        time.sleep(100 * time.Millisecond)
    }
}

process_task :: proc(msg : comms.Message) {
    fmt.printf("Processing task: %s\n", msg.type)
    
    // Update status
    update := fmt.Sprintf(`{"id":"%s","status":"processing"}`, msg.id)
    comms.event_bus_emit("task.update", update)
    
    // Process based on type
    switch msg.type {
    case "export":
        result := perform_export(msg.payload)
        complete_task(msg.id, result)
    case "import":
        result := perform_import(msg.payload)
        complete_task(msg.id, result)
    case "report":
        result := generate_report(msg.payload)
        complete_task(msg.id, result)
    }
    
    // Complete
    complete_update := fmt.Sprintf(`{"id":"%s","status":"completed"}`, msg.id)
    comms.event_bus_emit("task.update", complete_update)
}

// =============================================================================
// Main
// =============================================================================

main :: proc() {
    fmt.println("Starting application...")
    
    // Initialize
    init_communication()
    
    // Start background workers
    go task_processor()
    
    // Create window
    my_window = webui.new_window()
    webui.set_size(my_window, 1200, 800)
    
    // Show application
    if !webui.show(my_window, html_content) {
        fmt.println("Failed to show window!")
        return
    }
    
    fmt.println("Application running. Press Ctrl+C to exit.")
    webui.wait()
    
    fmt.println("Application closed.")
}
```

---

## See Also

- `docs/COMMUNICATION_APPROACHES.md` - Communication pattern comparison
- `comms/comms.odin` - Communication layer implementation
- `frontend/src/app/services/communication.service.ts` - Angular services
