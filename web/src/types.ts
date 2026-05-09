export type Cafe = {
  id: string;
  name: string;
  address: string;
  category: string;
  city: string;
  latitude: number;
  longitude: number;
  rating: number;
  reviewCount: number;
  priceNote: string;
  signatureMenu: string;
  shortDescription: string;
  vibeTags: string[];
  features: string[];
  openHours: string;
};

export type CafeReview = {
  id: string;
  userId: string | null;
  cafeId: string;
  authorNickname: string;
  overallRating: number;
  recommendedMenuName: string;
  content: string;
  createdAt: string;
};

export type AppUser = {
  id: string;
  nickname: string;
  email: string | null;
  profileImageUrl: string | null;
  status: string;
};

export type AuthIntent = "signin" | "signup";
export type ViewTab = "explore" | "saved" | "profile";
