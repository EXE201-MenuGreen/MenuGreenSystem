export interface AssignRoleRequest {
  role: string;
}

export interface UserAdmin {
  id: string;
  email: string;
  fullName: string;
  role: string;
  membershipTier: string;
  membershipStatus: string;
  entitlements: string[];
  membershipExpiresAt: string | null;
  isActive: boolean;
  emailConfirmed: boolean;
  createdAt: string;
  lastSignInAt: string | null;
}

export interface AdminMembershipItem {
  subscriptionId: string;
  planId: string;
  planName: string;
  featureGroup: string;
  status: string;
  startDate: string;
  endDate: string;
  cancelledAt: string | null;
  renewedAt: string | null;
  daysRemaining: number;
}

export interface AdminUserMembership {
  userId: string;
  tier: string;
  entitlements: string[];
  featureGroups: string[];
  expiresAt: string | null;
  memberships: AdminMembershipItem[];
}

export interface AdminGrantMembershipRequest {
  subscriptionPlanId: string;
  durationDays: number;
  startDate?: string;
  note?: string;
}
