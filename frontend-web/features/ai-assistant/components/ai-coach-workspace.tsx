"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { aiCoachApi } from "@/features/ai-assistant/api/ai-coach-api";
import type {
  AiCoachSession,
  AiConversationDetail,
  AiConversationSummary,
} from "@/features/ai-assistant/types";
import { getErrorMessage } from "@/lib/api/errors";
import { formatDateTime } from "@/lib/utils/format";

export function AiCoachWorkspace() {
  const [session, setSession] = useState<AiCoachSession | null>(() =>
    aiCoachApi.getSession(),
  );
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [authLoading, setAuthLoading] = useState(false);
  const [loadingConversations, setLoadingConversations] = useState(false);
  const [sending, setSending] = useState(false);
  const [conversations, setConversations] = useState<AiConversationSummary[]>([]);
  const [activeConversation, setActiveConversation] =
    useState<AiConversationDetail | null>(null);
  const [selectedConversationId, setSelectedConversationId] = useState<
    string | null
  >(null);
  const [draft, setDraft] = useState("");
  const [error, setError] = useState<string | null>(null);

  const loadConversations = useCallback(
    async (selectConversationId?: string | null) => {
      setLoadingConversations(true);
      setError(null);

      try {
        const items = await aiCoachApi.getConversations(20);
        setConversations(items);

        const nextConversationId =
          selectConversationId ??
          selectedConversationId ??
          items[0]?.conversationId;

        if (nextConversationId) {
          const detail = await aiCoachApi.getConversation(nextConversationId);
          setActiveConversation(detail);
          setSelectedConversationId(nextConversationId);
        } else {
          setActiveConversation(null);
          setSelectedConversationId(null);
        }
      } catch (err) {
        setError(getErrorMessage(err, "Khong the tai du lieu AI Coach."));
      } finally {
        setLoadingConversations(false);
      }
    },
    [selectedConversationId],
  );

  useEffect(() => {
    if (!session) return;

    const timer = window.setTimeout(() => {
      void loadConversations();
    }, 0);

    return () => window.clearTimeout(timer);
  }, [loadConversations, session]);

  async function handleLogin(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setAuthLoading(true);
    setError(null);

    try {
      const nextSession = await aiCoachApi.login({ email, password });
      setSession(nextSession);
      setPassword("");
      await loadConversations();
    } catch (err) {
      setError(getErrorMessage(err, "Dang nhap AI Coach that bai."));
    } finally {
      setAuthLoading(false);
    }
  }

  async function handleLogout() {
    aiCoachApi.clearSession();
    setSession(null);
    setConversations([]);
    setActiveConversation(null);
    setSelectedConversationId(null);
    setDraft("");
    setError(null);
  }

  async function handleSelectConversation(conversationId: string) {
    setSelectedConversationId(conversationId);
    setError(null);

    try {
      const detail = await aiCoachApi.getConversation(conversationId);
      setActiveConversation(detail);
    } catch (err) {
      setError(getErrorMessage(err, "Khong the mo conversation."));
    }
  }

  function handleNewConversation() {
    setSelectedConversationId(null);
    setActiveConversation(null);
    setDraft("");
    setError(null);
  }

  async function handleSendMessage(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!draft.trim()) return;

    setSending(true);
    setError(null);

    try {
      const response = await aiCoachApi.sendMessage({
        conversationId: selectedConversationId,
        message: draft.trim(),
        language: "vi",
        stream: false,
      });

      setDraft("");
      await loadConversations(response.conversationId);
    } catch (err) {
      setError(getErrorMessage(err, "Khong the gui tin nhan."));
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(16,185,129,0.18),_transparent_34%),linear-gradient(180deg,_#f5fffb_0%,_#f7f7f6_45%,_#eef7f2_100%)] text-zinc-900">
      <div className="mx-auto flex min-h-screen max-w-7xl flex-col px-4 py-6 lg:px-6">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-sm font-medium uppercase tracking-[0.28em] text-emerald-700">
              MenuGreen AI Demo
            </p>
            <h1 className="mt-2 text-3xl font-semibold tracking-tight text-zinc-950">
              User AI Coach Workspace
            </h1>
            <p className="mt-2 max-w-2xl text-sm leading-6 text-zinc-600">
              Giao dien nay danh cho demo web. Business state van duoc doc va
              luu o backend MenuGreenSystem, con runtime RAG xu ly hoi dap.
            </p>
          </div>
          <div className="flex gap-2">
            <Link href="/dashboard/ai-assistant">
              <Button variant="secondary">Ve Admin AI</Button>
            </Link>
            {session ? (
              <Button variant="ghost" onClick={handleLogout}>
                Dang xuat
              </Button>
            ) : null}
          </div>
        </div>

        {error ? (
          <div className="mb-4 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        ) : null}

        <div className="grid flex-1 gap-6 lg:grid-cols-[340px_minmax(0,1fr)]">
          <aside className="rounded-[28px] border border-white/80 bg-white/90 p-5 shadow-[0_20px_80px_-48px_rgba(16,24,40,0.55)] backdrop-blur">
            {!session ? (
              <div>
                <p className="text-sm font-medium text-zinc-500">Dang nhap user</p>
                <h2 className="mt-2 text-2xl font-semibold text-zinc-950">
                  Ket noi AI Coach
                </h2>
                <p className="mt-2 text-sm leading-6 text-zinc-600">
                  Dung tai khoan user binh thuong. Session trang nay duoc tach
                  rieng, khong anh huong den admin dashboard.
                </p>

                <form className="mt-6 space-y-4" onSubmit={handleLogin}>
                  <Input
                    label="Email"
                    type="email"
                    autoComplete="email"
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                    required
                  />
                  <Input
                    label="Password"
                    type="password"
                    autoComplete="current-password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    required
                  />
                  <Button className="w-full" loading={authLoading} type="submit">
                    Dang nhap AI Coach
                  </Button>
                </form>
              </div>
            ) : (
              <div className="flex h-full flex-col">
                <div className="rounded-3xl bg-emerald-600 px-4 py-4 text-white">
                  <p className="text-xs uppercase tracking-[0.24em] text-emerald-100">
                    Active session
                  </p>
                  <p className="mt-2 text-lg font-semibold">
                    {session.fullName || session.email}
                  </p>
                  <p className="mt-1 text-sm text-emerald-100">{session.email}</p>
                  <p className="mt-2 text-xs text-emerald-100/90">{`User ID: ${session.userId}`}</p>
                </div>

                <div className="mt-5 flex items-center justify-between">
                  <div>
                    <p className="text-sm font-semibold text-zinc-900">
                      Conversations
                    </p>
                    <p className="text-xs text-zinc-500">
                      Lich su chat da luu trong DB
                    </p>
                  </div>
                  <Button variant="secondary" className="h-9 px-3 text-xs" onClick={handleNewConversation}>
                    Moi
                  </Button>
                </div>

                <div className="mt-4 flex-1 space-y-3 overflow-y-auto pr-1">
                  {loadingConversations ? (
                    <div className="rounded-2xl border border-dashed border-zinc-300 px-4 py-6 text-sm text-zinc-500">
                      Dang tai hoi thoai...
                    </div>
                  ) : conversations.length === 0 ? (
                    <div className="rounded-2xl border border-dashed border-zinc-300 px-4 py-6 text-sm text-zinc-500">
                      Chua co conversation nao. Thu gui cau hoi dau tien.
                    </div>
                  ) : (
                    conversations.map((conversation) => {
                      const isActive =
                        conversation.conversationId === selectedConversationId;

                      return (
                        <button
                          key={conversation.conversationId}
                          type="button"
                          onClick={() =>
                            handleSelectConversation(conversation.conversationId)
                          }
                          className={`w-full rounded-2xl border px-4 py-3 text-left transition ${
                            isActive
                              ? "border-emerald-300 bg-emerald-50 shadow-sm"
                              : "border-zinc-200 bg-white hover:border-zinc-300"
                          }`}
                        >
                          <div className="flex items-center justify-between gap-3">
                            <p className="line-clamp-1 font-medium text-zinc-900">
                              {conversation.title}
                            </p>
                            <Badge variant={isActive ? "success" : "neutral"}>
                              {conversation.messageCount}
                            </Badge>
                          </div>
                          <p className="mt-2 line-clamp-2 text-sm leading-6 text-zinc-600">
                            {conversation.lastMessagePreview || "Khong co preview"}
                          </p>
                          <p className="mt-2 text-xs text-zinc-500">
                            {formatDateTime(conversation.lastMessageAt)}
                          </p>
                        </button>
                      );
                    })
                  )}
                </div>
              </div>
            )}
          </aside>

          <section className="flex min-h-[680px] flex-col overflow-hidden rounded-[32px] border border-white/80 bg-white/90 shadow-[0_20px_80px_-48px_rgba(16,24,40,0.55)] backdrop-blur">
            <div className="border-b border-zinc-200/80 px-6 py-5">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="text-sm text-zinc-500">Conversation</p>
                  <h2 className="mt-1 text-xl font-semibold text-zinc-950">
                    {activeConversation?.title || "Bat dau hoi dap moi"}
                  </h2>
                </div>
                <Badge variant="info">
                  {session ? "Authorized user" : "Login required"}
                </Badge>
              </div>
            </div>

            <div className="flex-1 space-y-4 overflow-y-auto bg-[linear-gradient(180deg,_rgba(240,253,244,0.75),_rgba(255,255,255,0.96)_24%,_rgba(255,255,255,0.98)_100%)] px-6 py-6">
              {!activeConversation?.messages.length ? (
                <div className="mx-auto max-w-2xl rounded-[28px] border border-dashed border-zinc-300 bg-white/90 px-6 py-10 text-center">
                <p className="text-lg font-semibold text-zinc-900">
                  AI Coach san sang
                </p>
                <p className="mt-2 text-sm leading-6 text-zinc-600">
                  Ban co the hoi ve mon an, bua trong ngay, goi y meal plan,
                  macro, calorie, budget, allergy, muc tieu tang giam can.
                </p>
              </div>
              ) : (
                activeConversation.messages.map((message) => {
                  const isUser = message.role === "user";

                  return (
                    <div
                      key={message.messageId}
                      className={`flex ${isUser ? "justify-end" : "justify-start"}`}
                    >
                      <div
                        className={`max-w-3xl rounded-[28px] px-5 py-4 shadow-sm ${
                          isUser
                            ? "bg-zinc-950 text-white"
                            : "border border-emerald-100 bg-emerald-50 text-zinc-900"
                        }`}
                      >
                        <p className="text-xs uppercase tracking-[0.18em] opacity-70">
                          {isUser ? "User" : "AI Coach"}
                        </p>
                        <p className="mt-2 whitespace-pre-wrap text-sm leading-7">
                          {message.content}
                        </p>
                        <p
                          className={`mt-3 text-xs ${
                            isUser ? "text-zinc-300" : "text-zinc-500"
                          }`}
                        >
                          {formatDateTime(message.createdAt)}
                        </p>
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            <form className="border-t border-zinc-200/80 bg-white px-6 py-5" onSubmit={handleSendMessage}>
              <Textarea
                label="Tin nhan"
                placeholder="Vi du: Hom nay toi con bao nhieu kcal va nen an gi de giam can duoi 60k?"
                value={draft}
                onChange={(event) => setDraft(event.target.value)}
                disabled={!session || sending}
              />
              <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
                <p className="text-xs text-zinc-500">
                  Luong nay la web demo tam thoi. Mobile nen goi qua backend chinh
                  thay vi hit truc tiep runtime AI.
                </p>
                <Button type="submit" loading={sending} disabled={!session || !draft.trim()}>
                  Gui cho AI Coach
                </Button>
              </div>
            </form>
          </section>
        </div>
      </div>
    </div>
  );
}
