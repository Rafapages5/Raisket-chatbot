# Raisket Frontend

Next.js 15 application for Raisket AI Financial Advisor.

## Tech Stack

- **Next.js 15** - React framework with App Router
- **TypeScript** - Type safety
- **Tailwind CSS** - Utility-first styling
- **Supabase** - Authentication and database
- **Axios** - HTTP client
- **Zustand** - State management (ready to add)
- **Lucide React** - Icons

## Project Structure

```
frontend/
├── app/                    # Next.js App Router
│   ├── page.tsx           # Landing page
│   ├── layout.tsx         # Root layout
│   ├── globals.css        # Global styles
│   ├── chat/              # Chat interface
│   ├── dashboard/         # User dashboard (TODO)
│   └── auth/              # Authentication pages (TODO)
├── components/            # React components
│   ├── ui/               # Reusable UI components
│   ├── chat/             # Chat-specific components
│   └── layout/           # Layout components
├── lib/                  # Utilities
│   ├── api.ts           # Backend API client
│   ├── supabase.ts      # Supabase client
│   └── utils.ts         # Helper functions
├── hooks/               # Custom React hooks
└── public/              # Static assets
```

## Getting Started

### Install Dependencies

```bash
npm install
```

### Configure Environment

```bash
cp .env.local.example .env.local
```

Edit `.env.local`:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

### Run Development Server

```bash
npm run dev
```

Open http://localhost:3000

## Available Scripts

- `npm run dev` - Start development server with Turbopack
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript type checking

## Key Features Implemented

### ✅ Landing Page
- Hero section
- Feature cards
- Call-to-action sections
- Responsive design

### ✅ Chat Interface
- Real-time chat with AI
- Message history
- Loading states
- Error handling

### 🚧 TODO - Week 1

#### Authentication Pages
Create `app/auth/page.tsx`:
```tsx
- Email/password login
- Email/password signup
- Google OAuth (optional)
- Password reset
```

#### Protected Routes
Create `middleware.ts`:
```tsx
- Redirect unauthenticated users
- Protect /dashboard, /chat routes
```

#### User Context
Create `lib/auth-context.tsx`:
```tsx
- Supabase auth state
- User profile
- Sign in/out functions
```

## Adding UI Components

This project is ready for shadcn/ui components:

```bash
# Initialize shadcn/ui (if needed)
npx shadcn-ui@latest init

# Add components
npx shadcn-ui@latest add button
npx shadcn-ui@latest add card
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add input
npx shadcn-ui@latest add form
```

## API Integration

### Using the API Client

```tsx
import { chatApi } from '@/lib/api';

// Send message
const response = await chatApi.sendMessage({
  message: "¿Cómo puedo ahorrar?",
  user_id: userId,
});

// Stream message
await chatApi.streamMessage(
  { message, user_id: userId },
  (chunk) => {
    console.log('Received chunk:', chunk);
  }
);
```

### Using Supabase

```tsx
import { supabase } from '@/lib/supabase';

// Sign up
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password',
});

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password',
});

// Get user
const { data: { user } } = await supabase.auth.getUser();

// Query data
const { data, error } = await supabase
  .from('conversations')
  .select('*')
  .order('created_at', { ascending: false });
```

## Styling

### Tailwind CSS

This project uses Tailwind CSS with a custom theme:

```tsx
// Example: Card component
<div className="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
  <h3 className="text-lg font-semibold mb-2">Title</h3>
  <p className="text-gray-600">Description</p>
</div>
```

### CSS Variables

Custom colors are defined in `app/globals.css`:
- `--primary` - Primary brand color
- `--secondary` - Secondary color
- `--accent` - Accent color
- etc.

### Dark Mode (Ready)

Dark mode is configured but not activated. To enable:

```tsx
// Add to root layout
<html lang="es" className="dark">
```

## State Management

### Option 1: React Context (Simple)

```tsx
// Create context
const UserContext = createContext();

// Provider
<UserContext.Provider value={user}>
  {children}
</UserContext.Provider>

// Use
const user = useContext(UserContext);
```

### Option 2: Zustand (Recommended)

Already installed, ready to use:

```tsx
// stores/user-store.ts
import { create } from 'zustand';

interface UserState {
  user: User | null;
  setUser: (user: User) => void;
}

export const useUserStore = create<UserState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));

// Use in components
const { user, setUser } = useUserStore();
```

## Deployment

### Vercel (Recommended)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Or connect GitHub repo in Vercel dashboard
```

Environment variables to set in Vercel:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_API_URL`

### Other Platforms

Build command:
```bash
npm run build
```

Start command:
```bash
npm start
```

## Performance Optimization

### Image Optimization

```tsx
import Image from 'next/image';

<Image
  src="/image.png"
  alt="Description"
  width={500}
  height={300}
  priority // For LCP images
/>
```

### Font Optimization

Already configured with `next/font`:

```tsx
import { Inter } from 'next/font/google';

const inter = Inter({ subsets: ['latin'] });
```

### Code Splitting

Next.js automatically code-splits. For dynamic imports:

```tsx
import dynamic from 'next/dynamic';

const DynamicComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <p>Loading...</p>,
  ssr: false, // Disable SSR if needed
});
```

## Week 1 Priorities

1. **Authentication** (Day 1-2)
   - [ ] Create auth pages
   - [ ] Implement login/signup
   - [ ] Add protected routes
   - [ ] User session management

2. **Chat Improvements** (Day 3-4)
   - [ ] Add streaming responses
   - [ ] Save conversations to Supabase
   - [ ] Load conversation history
   - [ ] Display sources from RAG

3. **Financial Onboarding** (Day 5-6)
   - [ ] Multi-step form
   - [ ] Save financial profile
   - [ ] Data validation
   - [ ] Progress indicator

4. **Dashboard** (Day 7)
   - [ ] Financial summary cards
   - [ ] Recent conversations
   - [ ] Quick actions
   - [ ] Recommendations widget

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Shadcn/ui](https://ui.shadcn.com/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
