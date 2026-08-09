import { AuthGuard } from "@/features/auth/components/auth-guard";
import { AiCoachWorkspace } from "@/features/ai-assistant/components/ai-coach-workspace";

export default function AiCoachPage() {
  return (
    <AuthGuard>
      <AiCoachWorkspace />
    </AuthGuard>
  );
}
}
