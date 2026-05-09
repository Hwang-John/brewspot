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

export type ContentSource = "remote" | "localFallback" | "sample";

export type CommunityPost = {
  id: string;
  authorId: string | null;
  authorName: string;
  category: string;
  title: string;
  content: string;
  city: string;
  likeCount: number;
  commentCount: number;
  createdAt: string;
  source: ContentSource;
};

export type HomeBaristaPost = {
  id: string;
  authorId: string | null;
  authorName: string;
  brewMethod: string;
  title: string;
  beanName: string;
  ratioNote: string;
  tastingNote: string;
  brewNote: string;
  createdAt: string;
  source: ContentSource;
};

export type AuthIntent = "signin" | "signup";
export type ViewTab = "explore" | "saved" | "profile";
