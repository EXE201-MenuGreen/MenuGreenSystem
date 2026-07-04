export interface AiBridgeHealth {
  workerConfigured: boolean;
  workerUrl: string;
  workerReachable: boolean;
  statusCode: number | null;
  workerService: string | null;
  error: string | null;
  checkedAt: string;
}

export interface AiConversationSummary {
  conversationId: string;
  title: string;
  lastMessagePreview: string;
  lastMessageAt: string | null;
  messageCount: number;
}

export interface AiMessage {
  messageId: string;
  role: string;
  content: string;
  tokensUsed: number | null;
  createdAt: string | null;
}

export interface AiConversationDetail {
  conversationId: string;
  title: string;
  createdAt: string | null;
  messages: AiMessage[];
}

export interface AiAdminOverview {
  bridgeHealth: AiBridgeHealth;
  totalAiProfiles: number;
  totalConversations: number;
  totalMessages: number;
  messagesLast7Days: number;
  latestConversationAt: string | null;
  recentConversations: AiConversationSummary[];
}

export interface AiChatRequest {
  conversationId?: string | null;
  message: string;
  language?: string;
  stream?: boolean;
}

export interface AiChatResponse {
  conversationId: string;
  userMessageId: string;
  assistantMessageId: string;
  assistantMessage: string;
  createdAt: string;
  suggestedQuestions: string[];
  safetyNotice: string | null;
  intent: string | null;
  source: string | null;
  requestId: string | null;
  threadId: string | null;
  intentConfidence: number | null;
  subscriptionTier: string | null;
}

export interface AiCoachSession {
  accessToken: string;
  refreshToken: string;
  email: string;
  fullName: string;
  userId: string;
}

export interface AiCoachLoginPayload {
  email: string;
  password: string;
}
