import axios from "axios";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

export const api = axios.create({
  baseURL: API_URL,
  headers: {
    "Content-Type": "application/json",
  },
});

// Chat API
export interface ChatRequest {
  message: string;
  user_id: string;
  conversation_id?: string;
}

export interface ChatResponse {
  message: string;
  conversation_id: string;
  sources?: Array<{ content: string }>;
}

export const chatApi = {
  sendMessage: async (request: ChatRequest): Promise<ChatResponse> => {
    const response = await api.post<ChatResponse>("/ai/chat", request);
    return response.data;
  },

  streamMessage: async (
    request: ChatRequest,
    onChunk: (chunk: string) => void
  ): Promise<void> => {
    const response = await fetch(`${API_URL}/ai/chat/stream`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error("Failed to stream message");
    }

    const reader = response.body?.getReader();
    const decoder = new TextDecoder();

    if (!reader) {
      throw new Error("No reader available");
    }

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      onChunk(chunk);
    }
  },
};

// Health check
export const healthApi = {
  check: async () => {
    const response = await api.get("/health");
    return response.data;
  },
};
