# How to Use Supabase: Quick Start Examples

This guide shows you how to build applications using your Supabase instance with practical, copy-paste examples.

## Table of Contents

1. [Setup: Get Your Credentials](#setup-get-your-credentials)
2. [Example 1: Todo List with Row Level Security](#example-1-todo-list-with-row-level-security)
3. [Example 2: User Authentication](#example-2-user-authentication)
4. [Example 3: File Upload and Storage](#example-3-file-upload-and-storage)
5. [Example 4: Real-time Subscriptions](#example-4-real-time-subscriptions-coming-soon)
6. [Example 5: Building a Notes App (Complete)](#example-5-building-a-notes-app-complete)

---

## Setup: Get Your Credentials

Before starting, grab your API credentials from the Studio dashboard:

1. Open your Supabase Studio: `https://your-app.ondigitalocean.app`
2. Or use environment variables you set during deployment:
   - `SUPABASE_ANON_KEY` - For client-side requests
   - App URL - Your deployment URL

```javascript
// config.js
const SUPABASE_URL = 'https://your-app.ondigitalocean.app';
const SUPABASE_ANON_KEY = 'your-anon-key-here';
```

---

## Example 1: Todo List with Row Level Security

**What you'll learn**: Create a table, enable RLS, and perform CRUD operations

### Step 1: Create the Table (in Studio)

Go to Studio → SQL Editor → New Query:

```sql
-- Create todos table
CREATE TABLE todos (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  task TEXT NOT NULL,
  is_complete BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own todos
CREATE POLICY "Users can view own todos"
  ON todos FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own todos
CREATE POLICY "Users can insert own todos"
  ON todos FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own todos
CREATE POLICY "Users can update own todos"
  ON todos FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own todos
CREATE POLICY "Users can delete own todos"
  ON todos FOR DELETE
  USING (auth.uid() = user_id);
```

### Step 2: Client Code (JavaScript)

```html
<!DOCTYPE html>
<html>
<head>
  <title>Todo List</title>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
</head>
<body>
  <h1>My Todos</h1>
  <input type="text" id="newTodo" placeholder="New todo...">
  <button onclick="addTodo()">Add</button>
  <ul id="todoList"></ul>

  <script>
    const SUPABASE_URL = 'https://your-app.ondigitalocean.app';
    const SUPABASE_ANON_KEY = 'your-anon-key';
    const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Fetch and display todos
    async function loadTodos() {
      const { data, error } = await supabase
        .from('todos')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) return console.error('Error loading todos:', error);

      const list = document.getElementById('todoList');
      list.innerHTML = data.map(todo => `
        <li>
          <input type="checkbox" ${todo.is_complete ? 'checked' : ''}
                 onchange="toggleTodo(${todo.id}, this.checked)">
          <span style="${todo.is_complete ? 'text-decoration: line-through' : ''}">
            ${todo.task}
          </span>
          <button onclick="deleteTodo(${todo.id})">Delete</button>
        </li>
      `).join('');
    }

    // Add new todo
    async function addTodo() {
      const task = document.getElementById('newTodo').value;
      if (!task) return;

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return alert('Please log in first!');

      const { error } = await supabase
        .from('todos')
        .insert({ task, user_id: user.id });

      if (error) return console.error('Error adding todo:', error);

      document.getElementById('newTodo').value = '';
      loadTodos();
    }

    // Toggle todo completion
    async function toggleTodo(id, is_complete) {
      const { error } = await supabase
        .from('todos')
        .update({ is_complete })
        .eq('id', id);

      if (error) return console.error('Error updating todo:', error);
      loadTodos();
    }

    // Delete todo
    async function deleteTodo(id) {
      const { error } = await supabase
        .from('todos')
        .delete()
        .eq('id', id);

      if (error) return console.error('Error deleting todo:', error);
      loadTodos();
    }

    // Load todos on page load
    loadTodos();
  </script>
</body>
</html>
```

**Try it**: Users can only see/modify their own todos thanks to RLS!

---

## Example 2: User Authentication

**What you'll learn**: Sign up, log in, and manage user sessions

```html
<!DOCTYPE html>
<html>
<head>
  <title>Auth Example</title>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
</head>
<body>
  <div id="authUI">
    <h2>Sign Up / Log In</h2>
    <input type="email" id="email" placeholder="Email">
    <input type="password" id="password" placeholder="Password">
    <button onclick="signUp()">Sign Up</button>
    <button onclick="signIn()">Log In</button>
  </div>

  <div id="userInfo" style="display:none">
    <h2>Welcome!</h2>
    <p>Email: <span id="userEmail"></span></p>
    <button onclick="signOut()">Sign Out</button>
  </div>

  <script>
    const supabase = window.supabase.createClient(
      'https://your-app.ondigitalocean.app',
      'your-anon-key'
    );

    // Check if user is already logged in
    async function checkUser() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        showUserInfo(user);
      }
    }

    // Sign up new user
    async function signUp() {
      const email = document.getElementById('email').value;
      const password = document.getElementById('password').value;

      const { data, error } = await supabase.auth.signUp({
        email,
        password
      });

      if (error) return alert('Error: ' + error.message);
      alert('Check your email for confirmation link!');
    }

    // Sign in existing user
    async function signIn() {
      const email = document.getElementById('email').value;
      const password = document.getElementById('password').value;

      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      });

      if (error) return alert('Error: ' + error.message);
      showUserInfo(data.user);
    }

    // Sign out
    async function signOut() {
      await supabase.auth.signOut();
      document.getElementById('authUI').style.display = 'block';
      document.getElementById('userInfo').style.display = 'none';
    }

    // Show user info
    function showUserInfo(user) {
      document.getElementById('authUI').style.display = 'none';
      document.getElementById('userInfo').style.display = 'block';
      document.getElementById('userEmail').textContent = user.email;
    }

    checkUser();
  </script>
</body>
</html>
```

**OAuth Sign In** (Google, GitHub, etc.):

```javascript
// Sign in with Google
await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: 'https://your-app.ondigitalocean.app'
  }
});

// Sign in with GitHub
await supabase.auth.signInWithOAuth({
  provider: 'github'
});
```

**Note**: Configure OAuth providers in Studio → Authentication → Providers

---

## Example 3: File Upload and Storage

**What you'll learn**: Upload files, create storage buckets, and serve files

### Step 1: Create Storage Bucket (in Studio)

Go to Studio → Storage → Create Bucket:
- Name: `avatars`
- Public: Yes (for this example)

### Step 2: Set Up Storage Policies

```sql
-- Allow authenticated users to upload files
CREATE POLICY "Authenticated users can upload avatars"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'avatars');

-- Allow public to read avatars
CREATE POLICY "Anyone can view avatars"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'avatars');
```

### Step 3: Client Code

```html
<!DOCTYPE html>
<html>
<head>
  <title>File Upload</title>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
</head>
<body>
  <h1>Upload Avatar</h1>
  <input type="file" id="fileInput" accept="image/*">
  <button onclick="uploadFile()">Upload</button>
  <div id="preview"></div>

  <script>
    const supabase = window.supabase.createClient(
      'https://your-app.ondigitalocean.app',
      'your-anon-key'
    );

    async function uploadFile() {
      const fileInput = document.getElementById('fileInput');
      const file = fileInput.files[0];
      if (!file) return alert('Select a file first!');

      // Check authentication
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return alert('Please log in first!');

      // Generate unique filename
      const fileExt = file.name.split('.').pop();
      const fileName = `${user.id}-${Date.now()}.${fileExt}`;
      const filePath = `${fileName}`;

      // Upload file
      const { data, error } = await supabase.storage
        .from('avatars')
        .upload(filePath, file);

      if (error) return console.error('Upload error:', error);

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('avatars')
        .getPublicUrl(filePath);

      // Display preview
      document.getElementById('preview').innerHTML = `
        <h3>Uploaded successfully!</h3>
        <img src="${publicUrl}" width="200">
        <p>URL: ${publicUrl}</p>
      `;
    }
  </script>
</body>
</html>
```

**Download a file**:

```javascript
// Download file as blob
const { data, error } = await supabase.storage
  .from('avatars')
  .download('filename.jpg');

// Create object URL
const url = URL.createObjectURL(data);
```

**List files in bucket**:

```javascript
const { data, error } = await supabase.storage
  .from('avatars')
  .list('', {
    limit: 100,
    offset: 0,
    sortBy: { column: 'created_at', order: 'desc' }
  });
```

---

## Example 4: Real-time Subscriptions (Coming Soon)

**What you'll learn**: Listen to database changes in real-time

**Note**: Realtime requires Redis configuration. Coming in future update!

```javascript
// Subscribe to all inserts on todos table
const subscription = supabase
  .channel('todos-channel')
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'todos' },
    (payload) => {
      console.log('New todo added:', payload.new);
      // Update UI automatically
    }
  )
  .subscribe();

// Unsubscribe when done
subscription.unsubscribe();
```

---

## Example 5: Building a Notes App (Complete)

**What you'll learn**: Combine auth, database, and storage in one app

### Database Schema

```sql
-- Notes table
CREATE TABLE notes (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  attachment_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own notes"
  ON notes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notes"
  ON notes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notes"
  ON notes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notes"
  ON notes FOR DELETE
  USING (auth.uid() = user_id);

-- Update trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notes_updated_at
  BEFORE UPDATE ON notes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

### Complete Application

```html
<!DOCTYPE html>
<html>
<head>
  <title>Notes App</title>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  <style>
    body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
    .note { border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 5px; }
    .note h3 { margin: 0 0 10px 0; }
    button { margin: 5px; padding: 8px 15px; cursor: pointer; }
    input, textarea { width: 100%; padding: 8px; margin: 5px 0; box-sizing: border-box; }
    textarea { min-height: 100px; }
  </style>
</head>
<body>
  <div id="app">
    <!-- Auth Section -->
    <div id="auth" style="display:none">
      <h2>Please Log In</h2>
      <input type="email" id="authEmail" placeholder="Email">
      <input type="password" id="authPassword" placeholder="Password">
      <button onclick="handleAuth('signIn')">Log In</button>
      <button onclick="handleAuth('signUp')">Sign Up</button>
    </div>

    <!-- Notes Section -->
    <div id="notes" style="display:none">
      <h1>My Notes</h1>
      <button onclick="showNewNoteForm()">+ New Note</button>
      <button onclick="handleSignOut()">Sign Out</button>

      <!-- New Note Form -->
      <div id="noteForm" style="display:none; border: 1px solid #ccc; padding: 15px; margin: 20px 0;">
        <h3>New Note</h3>
        <input type="text" id="noteTitle" placeholder="Title">
        <textarea id="noteContent" placeholder="Content"></textarea>
        <input type="file" id="noteAttachment" accept="image/*,application/pdf">
        <br>
        <button onclick="saveNote()">Save</button>
        <button onclick="cancelNote()">Cancel</button>
      </div>

      <!-- Notes List -->
      <div id="notesList"></div>
    </div>
  </div>

  <script>
    const supabase = window.supabase.createClient(
      'https://your-app.ondigitalocean.app',
      'your-anon-key'
    );

    let currentUser = null;

    // Initialize app
    async function init() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        currentUser = user;
        showNotes();
        loadNotes();
      } else {
        showAuth();
      }
    }

    // Auth handlers
    function showAuth() {
      document.getElementById('auth').style.display = 'block';
      document.getElementById('notes').style.display = 'none';
    }

    function showNotes() {
      document.getElementById('auth').style.display = 'none';
      document.getElementById('notes').style.display = 'block';
    }

    async function handleAuth(type) {
      const email = document.getElementById('authEmail').value;
      const password = document.getElementById('authPassword').value;

      if (type === 'signUp') {
        const { error } = await supabase.auth.signUp({ email, password });
        if (error) return alert('Error: ' + error.message);
        alert('Check your email for confirmation!');
      } else {
        const { data, error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) return alert('Error: ' + error.message);
        currentUser = data.user;
        showNotes();
        loadNotes();
      }
    }

    async function handleSignOut() {
      await supabase.auth.signOut();
      currentUser = null;
      showAuth();
    }

    // Notes handlers
    function showNewNoteForm() {
      document.getElementById('noteForm').style.display = 'block';
    }

    function cancelNote() {
      document.getElementById('noteForm').style.display = 'none';
      document.getElementById('noteTitle').value = '';
      document.getElementById('noteContent').value = '';
      document.getElementById('noteAttachment').value = '';
    }

    async function saveNote() {
      const title = document.getElementById('noteTitle').value;
      const content = document.getElementById('noteContent').value;
      const fileInput = document.getElementById('noteAttachment');
      const file = fileInput.files[0];

      if (!title) return alert('Please enter a title');

      let attachment_url = null;

      // Upload attachment if present
      if (file) {
        const fileExt = file.name.split('.').pop();
        const fileName = `${currentUser.id}-${Date.now()}.${fileExt}`;
        const { data, error } = await supabase.storage
          .from('attachments')
          .upload(fileName, file);

        if (error) return alert('Upload error: ' + error.message);

        const { data: { publicUrl } } = supabase.storage
          .from('attachments')
          .getPublicUrl(fileName);

        attachment_url = publicUrl;
      }

      // Save note
      const { error } = await supabase.from('notes').insert({
        user_id: currentUser.id,
        title,
        content,
        attachment_url
      });

      if (error) return alert('Error saving note: ' + error.message);

      cancelNote();
      loadNotes();
    }

    async function loadNotes() {
      const { data, error } = await supabase
        .from('notes')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) return console.error('Error loading notes:', error);

      const notesList = document.getElementById('notesList');
      notesList.innerHTML = data.map(note => `
        <div class="note">
          <h3>${note.title}</h3>
          <p>${note.content || ''}</p>
          ${note.attachment_url ? `<a href="${note.attachment_url}" target="_blank">View Attachment</a>` : ''}
          <br>
          <small>Created: ${new Date(note.created_at).toLocaleString()}</small>
          <br>
          <button onclick="deleteNote(${note.id})">Delete</button>
        </div>
      `).join('');
    }

    async function deleteNote(id) {
      if (!confirm('Delete this note?')) return;

      const { error } = await supabase
        .from('notes')
        .delete()
        .eq('id', id);

      if (error) return alert('Error deleting note: ' + error.message);
      loadNotes();
    }

    // Initialize app
    init();
  </script>
</body>
</html>
```

**Don't forget**: Create the `attachments` bucket in Storage with public access!

---

## Next Steps

### Learn More

- **PostgREST Documentation**: [postgrest.org](https://postgrest.org)
- **Supabase JS Client**: [supabase.com/docs/reference/javascript](https://supabase.com/docs/reference/javascript)
- **PostgreSQL Functions**: Create custom database functions for complex queries
- **RLS Patterns**: Advanced security patterns with Row Level Security

### Build More Complex Apps

- **Multi-tenant SaaS**: Use organizations table with team-based RLS
- **E-commerce**: Products, orders, and payments with Stripe integration
- **Chat Application**: Real-time messaging with subscriptions
- **Blog Platform**: Posts, comments, and rich media

### Production Checklist

- [ ] Enable email confirmation (configure SMTP)
- [ ] Set up OAuth providers (Google, GitHub, etc.)
- [ ] Configure custom domain
- [ ] Enable database backups
- [ ] Set up monitoring and alerts
- [ ] Implement rate limiting
- [ ] Add custom error pages
- [ ] Document your API

---

**Questions?** Check the [main README](./README.md) for troubleshooting and support resources.
