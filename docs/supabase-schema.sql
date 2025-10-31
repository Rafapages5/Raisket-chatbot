-- Raisket Supabase Database Schema
-- Run this in Supabase SQL Editor after creating your project

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================================================
-- PROFILES TABLE
-- ============================================================================
-- Extends auth.users with additional profile information
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Trigger to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- CONVERSATIONS TABLE
-- ============================================================================
CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own conversations"
  ON public.conversations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own conversations"
  ON public.conversations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own conversations"
  ON public.conversations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own conversations"
  ON public.conversations FOR DELETE
  USING (auth.uid() = user_id);

-- Index for faster queries
CREATE INDEX idx_conversations_user_id ON public.conversations(user_id);
CREATE INDEX idx_conversations_created_at ON public.conversations(created_at DESC);

-- ============================================================================
-- MESSAGES TABLE
-- ============================================================================
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages from own conversations"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE conversations.id = messages.conversation_id
        AND conversations.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create messages in own conversations"
  ON public.messages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE conversations.id = messages.conversation_id
        AND conversations.user_id = auth.uid()
    )
  );

-- Indexes
CREATE INDEX idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);

-- ============================================================================
-- FINANCIAL PROFILES TABLE
-- ============================================================================
CREATE TABLE public.financial_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,

  -- Income & Expenses
  monthly_income DECIMAL(12,2),
  monthly_expenses DECIMAL(12,2),

  -- Assets & Liabilities
  savings DECIMAL(12,2),
  investments DECIMAL(12,2),
  debt DECIMAL(12,2),

  -- Risk Profile
  risk_tolerance TEXT CHECK (risk_tolerance IN ('conservative', 'moderate', 'aggressive')),

  -- Goals
  financial_goals JSONB DEFAULT '[]',

  -- Metadata
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.financial_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own financial profile"
  ON public.financial_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own financial profile"
  ON public.financial_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own financial profile"
  ON public.financial_profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- Index
CREATE INDEX idx_financial_profiles_user_id ON public.financial_profiles(user_id);

-- ============================================================================
-- DOCUMENTS TABLE (with vector embeddings)
-- ============================================================================
CREATE TABLE public.documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

  -- Document info
  title TEXT,
  content TEXT NOT NULL,
  document_type TEXT, -- e.g., 'guide', 'user_upload', 'financial_statement'

  -- Vector embedding (OpenAI text-embedding-3-small = 1536 dimensions)
  embedding vector(1536),

  -- Metadata
  metadata JSONB DEFAULT '{}',
  processed BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own documents"
  ON public.documents FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own documents"
  ON public.documents FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own documents"
  ON public.documents FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own documents"
  ON public.documents FOR DELETE
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_documents_user_id ON public.documents(user_id);
CREATE INDEX idx_documents_document_type ON public.documents(document_type);

-- Vector similarity search index (IVFFlat for better performance)
CREATE INDEX ON public.documents USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- ============================================================================
-- RECOMMENDATIONS TABLE
-- ============================================================================
CREATE TABLE public.recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

  category TEXT NOT NULL, -- e.g., 'savings', 'investment', 'debt', 'budget'
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  priority TEXT CHECK (priority IN ('high', 'medium', 'low')) DEFAULT 'medium',
  status TEXT CHECK (status IN ('pending', 'in_progress', 'completed', 'dismissed')) DEFAULT 'pending',

  estimated_impact DECIMAL(12,2), -- Estimated financial impact

  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own recommendations"
  ON public.recommendations FOR ALL
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_recommendations_user_id ON public.recommendations(user_id);
CREATE INDEX idx_recommendations_status ON public.recommendations(status);
CREATE INDEX idx_recommendations_priority ON public.recommendations(priority);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_financial_profiles_updated_at BEFORE UPDATE ON public.financial_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON public.documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recommendations_updated_at BEFORE UPDATE ON public.recommendations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function for vector similarity search
CREATE OR REPLACE FUNCTION match_documents(
  query_embedding vector(1536),
  match_threshold float,
  match_count int,
  filter_user_id uuid
)
RETURNS TABLE (
  id uuid,
  content text,
  metadata jsonb,
  similarity float
)
LANGUAGE sql STABLE
AS $$
  SELECT
    documents.id,
    documents.content,
    documents.metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  FROM documents
  WHERE
    documents.user_id = filter_user_id
    AND 1 - (documents.embedding <=> query_embedding) > match_threshold
  ORDER BY documents.embedding <=> query_embedding
  LIMIT match_count;
$$;

-- ============================================================================
-- SEED DATA (Optional - Financial guides for Mexico)
-- ============================================================================

-- Insert some base financial guidance documents
-- These will be available to all users for RAG context

INSERT INTO public.documents (user_id, title, content, document_type, processed) VALUES
(
  '00000000-0000-0000-0000-000000000000', -- System user ID
  'Guía de CETES',
  'Los Certificados de la Tesorería de la Federación (CETES) son instrumentos de inversión de renta fija emitidos por el Gobierno Federal de México. Son considerados la inversión más segura en México porque están respaldados por el gobierno. Características: Plazo mínimo de 28 días, inversión mínima de $100 pesos, rendimiento conocido desde el inicio.',
  'guide',
  true
),
(
  '00000000-0000-0000-0000-000000000000',
  'CONDUSEF - Protección al Usuario',
  'La Comisión Nacional para la Protección y Defensa de los Usuarios de Servicios Financieros (CONDUSEF) es un organismo público que protege y defiende los derechos de los usuarios de servicios financieros en México. Ofrece: Orientación y asesoría, defensoría legal gratuita, solución de controversias, registro de contratos de adhesión.',
  'guide',
  true
);

-- ============================================================================
-- USEFUL QUERIES
-- ============================================================================

-- Get user's complete financial profile
-- SELECT * FROM profiles p
-- LEFT JOIN financial_profiles fp ON p.id = fp.user_id
-- WHERE p.id = auth.uid();

-- Get recent conversations with message count
-- SELECT c.*, COUNT(m.id) as message_count
-- FROM conversations c
-- LEFT JOIN messages m ON c.id = m.conversation_id
-- WHERE c.user_id = auth.uid()
-- GROUP BY c.id
-- ORDER BY c.updated_at DESC;

-- Search similar documents (call from application)
-- SELECT * FROM match_documents(
--   query_embedding := '[...]'::vector,
--   match_threshold := 0.7,
--   match_count := 5,
--   filter_user_id := auth.uid()
-- );
