import type {
  SubscriptionPlan,
  SubscriptionPlanUpsertRequest,
} from "@/features/subscription-plans/types";

export type SubscriptionPlanFormState = {
  name: string;
  description: string;
  durationDays: string;
  priceVnd: string;
  featureGroup: string;
  isActive: boolean;
};

export const subscriptionFeatureGroupOptions = [
  { value: "basic", label: "Cơ bản / Free (basic)" },
  { value: "casual", label: "Casual (casual)" },
  { value: "office", label: "Office (office)" },
  { value: "gym", label: "Gym/PT (gym)" },
] as const;

export function isSupportedSubscriptionFeatureGroup(value: string): boolean {
  return subscriptionFeatureGroupOptions.some((option) => option.value === value);
}

export const emptySubscriptionPlanForm = (): SubscriptionPlanFormState => ({
  name: "",
  description: "",
  durationDays: "30",
  priceVnd: "0",
  featureGroup: "basic",
  isActive: true,
});

export function planToFormState(plan: SubscriptionPlan): SubscriptionPlanFormState {
  return {
    name: plan.name,
    description: plan.description ?? "",
    durationDays: plan.durationDays.toString(),
    priceVnd: plan.priceVnd.toString(),
    featureGroup: plan.featureGroup ?? "",
    isActive: plan.isActive,
  };
}

export function formStateToPayload(
  form: SubscriptionPlanFormState,
): SubscriptionPlanUpsertRequest {
  return {
    name: form.name.trim(),
    description: form.description.trim() || null,
    durationDays: Number(form.durationDays) || 0,
    priceVnd: Number(form.priceVnd) || 0,
    featureGroup: form.featureGroup.trim() || null,
    isActive: form.isActive,
  };
}

export function validateSubscriptionPlanForm(
  form: SubscriptionPlanFormState,
): string | null {
  if (!form.name.trim()) return "Tên gói là bắt buộc.";
  if (!isSupportedSubscriptionFeatureGroup(form.featureGroup)) {
    return "Hãy chọn nhóm tính năng mới: basic, casual, office hoặc gym.";
  }
  if (Number.isNaN(Number(form.durationDays)) || Number(form.durationDays) < 0) {
    return "Số ngày phải là số không âm.";
  }
  if (Number.isNaN(Number(form.priceVnd)) || Number(form.priceVnd) < 0) {
    return "Giá phải là số không âm.";
  }
  return null;
}
