export interface AssignRoleRequest {
  role: string;
}

export interface UserAdmin {
  id: string;
  email: string;
  fullName: string;
  role: string;
  isActive: boolean;
  emailConfirmed: boolean;
  createdAt: string;
  lastSignInAt: string | null;
}
