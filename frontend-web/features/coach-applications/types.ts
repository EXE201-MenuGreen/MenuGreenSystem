export type CoachApplicationStatus =
  | "Draft"
  | "PendingReview"
  | "NeedsRevision"
  | "Approved"
  | "Rejected"
  | "Suspended";

export interface CoachCertificate {
  name: string;
  issuer: string;
  credentialNumber: string;
  issuedDate: string | null;
  expiryDate: string | null;
  imageUrl: string;
}

export interface CoachApplication {
  id: string;
  userId: string;
  fullName: string;
  avatarUrl: string;
  email: string;
  phoneNumber: string;
  dateOfBirth: string | null;
  gender: string;
  city: string;
  headline: string;
  specialty: string;
  bio: string;
  experienceYears: number;
  languages: string[];
  coachingStyles: string[];
  clientLevels: string[];
  certificates: CoachCertificate[];
  galleryUrls: string[];
  achievements: string;
  identityDocumentUrl: string | null;
  applicationStatus: CoachApplicationStatus;
  reviewNote: string | null;
  submittedAt: string | null;
  reviewedAt: string | null;
  reviewedByUserId: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export type CoachReviewDecision =
  | "Approve"
  | "NeedsRevision"
  | "Reject"
  | "Suspend";

export interface CoachReviewRequest {
  decision: CoachReviewDecision;
  reason?: string;
}
