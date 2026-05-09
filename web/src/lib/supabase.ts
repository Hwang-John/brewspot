import { createClient } from "@supabase/supabase-js";

import type { AppUser, Cafe, CafeReview, CommunityPost, HomeBaristaPost } from "../types";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const hasSupabaseEnv = Boolean(supabaseUrl && supabaseAnonKey);

export const supabase = hasSupabaseEnv
  ? createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true
      }
    })
  : null;

type CafeRecord = {
  id: string;
  name: string;
  address: string;
  category: string | null;
  city: string | null;
  latitude: number | null;
  longitude: number | null;
  signature_menu_name: string | null;
  price_note: string | null;
  avg_rating: number | null;
  review_count: number | null;
  short_description: string | null;
  vibe_tags: string[] | null;
  features: string[] | null;
  open_hours: string | null;
};

type ReviewRecord = {
  id: string;
  user_id: string;
  cafe_id: string;
  author_nickname: string;
  overall_rating: number;
  content: string | null;
  recommended_menu_name: string | null;
  created_at: string;
};

type LegacyReviewRecord = {
  id: string;
  user_id: string;
  cafe_id: string;
  overall_rating: number;
  content: string | null;
  created_at: string;
  users: { nickname: string | null } | null;
};

type BookmarkRecord = {
  id: string;
  user_id: string;
  cafe_id: string;
  created_at: string;
};

type UserRecord = {
  id: string;
  nickname: string;
  email: string | null;
  profile_image_url: string | null;
  status: string;
};

type CommunityPostRecord = {
  id: string;
  user_id: string;
  author_nickname: string;
  board_type: string;
  title: string;
  content: string;
  city: string | null;
  like_count: number | null;
  comment_count: number | null;
  created_at: string;
};

type HomeBaristaPostRecord = {
  id: string;
  user_id: string;
  author_nickname: string;
  brew_method: string;
  title: string;
  bean_name: string;
  ratio_note: string;
  tasting_note: string;
  brew_note: string;
  created_at: string;
};

function getClient() {
  if (!supabase) {
    throw new Error("Supabase environment variables are missing.");
  }

  return supabase;
}

function inferCity(address: string) {
  const parts = address.split(" ");
  return parts.length > 1 ? parts[1] : "지역 정보";
}

function mapCafe(record: CafeRecord): Cafe {
  return {
    id: record.id,
    name: record.name,
    address: record.address,
    category: record.category ?? "카페",
    city: record.city ?? inferCity(record.address),
    latitude: record.latitude ?? 37.5665,
    longitude: record.longitude ?? 126.978,
    rating: record.avg_rating ?? 0,
    reviewCount: record.review_count ?? 0,
    priceNote: record.price_note ?? "현장 확인 필요",
    signatureMenu: record.signature_menu_name ?? "대표 메뉴 준비 중",
    shortDescription: record.short_description ?? "카페 소개를 준비 중이에요.",
    vibeTags: record.vibe_tags ?? [],
    features: record.features ?? [],
    openHours: record.open_hours ?? "운영 시간 정보 준비 중"
  };
}

function extractLegacyRecommendedMenu(content: string | null) {
  if (!content) {
    return "";
  }

  const firstLine = content.split("\n")[0] ?? "";
  const prefix = "[추천메뉴] ";
  return firstLine.startsWith(prefix) ? firstLine.replace(prefix, "") : "";
}

function extractLegacyVisitNote(content: string | null) {
  if (!content) {
    return "";
  }

  const lines = content.split("\n");
  if (!lines[0]?.startsWith("[추천메뉴]")) {
    return content;
  }

  return lines.slice(1).join("\n").trim();
}

function mapReview(record: ReviewRecord): CafeReview {
  return {
    id: record.id,
    userId: record.user_id,
    cafeId: record.cafe_id,
    authorNickname: record.author_nickname,
    overallRating: record.overall_rating,
    recommendedMenuName: record.recommended_menu_name ?? "",
    content: record.content ?? "",
    createdAt: record.created_at
  };
}

function mapLegacyReview(record: LegacyReviewRecord): CafeReview {
  return {
    id: record.id,
    userId: record.user_id,
    cafeId: record.cafe_id,
    authorNickname: record.users?.nickname ?? "브루스팟 사용자",
    overallRating: record.overall_rating,
    recommendedMenuName: extractLegacyRecommendedMenu(record.content),
    content: extractLegacyVisitNote(record.content),
    createdAt: record.created_at
  };
}

function mapUser(record: UserRecord): AppUser {
  return {
    id: record.id,
    nickname: record.nickname,
    email: record.email,
    profileImageUrl: record.profile_image_url,
    status: record.status
  };
}

function mapCommunityPost(record: CommunityPostRecord): CommunityPost {
  return {
    id: record.id,
    authorId: record.user_id,
    authorName: record.author_nickname,
    category: record.board_type,
    title: record.title,
    content: record.content,
    city: record.city ?? "동네 미정",
    likeCount: record.like_count ?? 0,
    commentCount: record.comment_count ?? 0,
    createdAt: record.created_at,
    source: "remote"
  };
}

function mapHomeBaristaPost(record: HomeBaristaPostRecord): HomeBaristaPost {
  return {
    id: record.id,
    authorId: record.user_id,
    authorName: record.author_nickname,
    brewMethod: record.brew_method,
    title: record.title,
    beanName: record.bean_name,
    ratioNote: record.ratio_note,
    tastingNote: record.tasting_note,
    brewNote: record.brew_note,
    createdAt: record.created_at,
    source: "remote"
  };
}

async function getAuthUser() {
  const client = getClient();
  const {
    data: { user }
  } = await client.auth.getUser();

  return user;
}

export async function fetchCafes() {
  const client = getClient();
  const { data, error } = await client
    .from("cafes")
    .select(
      "id, name, address, category, city, latitude, longitude, signature_menu_name, price_note, avg_rating, review_count, short_description, vibe_tags, features, open_hours"
    )
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return (data ?? []).map(mapCafe);
}

export async function fetchReviews(cafeId: string) {
  const client = getClient();

  const primary = await client
    .from("reviews")
    .select(
      "id, user_id, cafe_id, author_nickname, overall_rating, content, recommended_menu_name, created_at"
    )
    .eq("cafe_id", cafeId)
    .order("created_at", { ascending: false });

  if (!primary.error) {
    return (primary.data ?? []).map((record) => mapReview(record as ReviewRecord));
  }

  const fallback = await client
    .from("reviews")
    .select("id, user_id, cafe_id, overall_rating, content, created_at, users(nickname)")
    .eq("cafe_id", cafeId)
    .order("created_at", { ascending: false });

  if (fallback.error) {
    throw fallback.error;
  }

  return (fallback.data ?? []).map((record) =>
    mapLegacyReview(record as unknown as LegacyReviewRecord)
  );
}

export async function fetchCurrentUserProfile() {
  const client = getClient();
  const user = await getAuthUser();

  if (!user) {
    return null;
  }

  const { data: existing, error: existingError } = await client
    .from("users")
    .select("id, nickname, email, profile_image_url, status")
    .eq("id", user.id)
    .maybeSingle();

  if (existingError) {
    throw existingError;
  }

  if (existing) {
    return mapUser(existing as UserRecord);
  }

  const nickname =
    (typeof user.user_metadata.nickname === "string" && user.user_metadata.nickname) ||
    user.email?.split("@")[0] ||
    "브루스팟 사용자";

  const { data: inserted, error: insertError } = await client
    .from("users")
    .upsert(
      {
        id: user.id,
        nickname,
        email: user.email,
        status: "active"
      },
      { onConflict: "id" }
    )
    .select("id, nickname, email, profile_image_url, status")
    .single();

  if (insertError) {
    throw insertError;
  }

  return mapUser(inserted as UserRecord);
}

export async function fetchBookmarks() {
  const client = getClient();
  const user = await getAuthUser();

  if (!user) {
    return [];
  }

  const { data, error } = await client
    .from("bookmarks")
    .select("id, user_id, cafe_id, created_at")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return (data as BookmarkRecord[] | null)?.map((bookmark) => bookmark.cafe_id) ?? [];
}

export async function addBookmark(cafeId: string) {
  const client = getClient();
  const user = await getAuthUser();

  if (!user) {
    throw new Error("로그인이 필요해요.");
  }

  const { error } = await client.from("bookmarks").upsert(
    {
      user_id: user.id,
      cafe_id: cafeId
    },
    { onConflict: "user_id,cafe_id" }
  );

  if (error) {
    throw error;
  }
}

export async function removeBookmark(cafeId: string) {
  const client = getClient();
  const user = await getAuthUser();

  if (!user) {
    throw new Error("로그인이 필요해요.");
  }

  const { error } = await client
    .from("bookmarks")
    .delete()
    .eq("user_id", user.id)
    .eq("cafe_id", cafeId);

  if (error) {
    throw error;
  }
}

export async function signInWithEmail(email: string, password: string) {
  const client = getClient();
  const { error } = await client.auth.signInWithPassword({ email, password });

  if (error) {
    throw error;
  }

  return fetchCurrentUserProfile();
}

export async function signUpWithEmail(email: string, password: string, nickname: string) {
  const client = getClient();
  const { error } = await client.auth.signUp({
    email,
    password,
    options: {
      data: {
        nickname
      }
    }
  });

  if (error) {
    throw error;
  }
}

export async function signOutCurrentUser() {
  const client = getClient();
  const { error } = await client.auth.signOut();

  if (error) {
    throw error;
  }
}

export async function addReview(input: {
  cafeId: string;
  authorNickname: string;
  overallRating: number;
  content: string;
  recommendedMenuName: string;
}) {
  const client = getClient();
  const user = await getAuthUser();

  if (!user) {
    throw new Error("로그인이 필요해요.");
  }

  const primary = await client
    .from("reviews")
    .insert({
      user_id: user.id,
      cafe_id: input.cafeId,
      author_nickname: input.authorNickname,
      overall_rating: input.overallRating,
      content: input.content,
      recommended_menu_name: input.recommendedMenuName
    })
    .select(
      "id, user_id, cafe_id, author_nickname, overall_rating, content, recommended_menu_name, created_at"
    )
    .single();

  if (!primary.error && primary.data) {
    return mapReview(primary.data as ReviewRecord);
  }

  const fallback = await client
    .from("reviews")
    .insert({
      user_id: user.id,
      cafe_id: input.cafeId,
      overall_rating: input.overallRating,
      content: `[추천메뉴] ${input.recommendedMenuName}\n${input.content}`
    })
    .select("id, user_id, cafe_id, overall_rating, content, created_at, users(nickname)")
    .single();

  if (fallback.error) {
    throw fallback.error;
  }

  return mapLegacyReview(fallback.data as unknown as LegacyReviewRecord);
}

export async function fetchCommunityPosts() {
  const client = getClient();
  const { data, error } = await client
    .from("community_posts")
    .select(
      "id, user_id, author_nickname, board_type, title, content, city, like_count, comment_count, created_at"
    )
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return (data as CommunityPostRecord[] | null)?.map(mapCommunityPost) ?? [];
}

export async function addCommunityPost(input: {
  title: string;
  content: string;
  category: string;
  city: string;
  authorNickname: string;
}) {
  const client = getClient();
  const user = await getAuthUser();

  if (!user) {
    throw new Error("로그인이 필요해요.");
  }

  const { data, error } = await client
    .from("community_posts")
    .insert({
      user_id: user.id,
      author_nickname: input.authorNickname,
      board_type: input.category,
      title: input.title,
      content: input.content,
      city: input.city
    })
    .select(
      "id, user_id, author_nickname, board_type, title, content, city, like_count, comment_count, created_at"
    )
    .single();

  if (error) {
    throw error;
  }

  return mapCommunityPost(data as CommunityPostRecord);
}

export async function fetchHomeBaristaPosts() {
  const client = getClient();
  const { data, error } = await client
    .from("homebarista_posts")
    .select(
      "id, user_id, author_nickname, brew_method, title, bean_name, ratio_note, tasting_note, brew_note, created_at"
    )
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }

  return (data as HomeBaristaPostRecord[] | null)?.map(mapHomeBaristaPost) ?? [];
}

export async function addHomeBaristaPost(input: {
  brewMethod: string;
  title: string;
  beanName: string;
  ratioNote: string;
  tastingNote: string;
  brewNote: string;
  authorNickname: string;
}) {
  const client = getClient();
  const user = await getAuthUser();

  if (!user) {
    throw new Error("로그인이 필요해요.");
  }

  const { data, error } = await client
    .from("homebarista_posts")
    .insert({
      user_id: user.id,
      author_nickname: input.authorNickname,
      brew_method: input.brewMethod,
      title: input.title,
      bean_name: input.beanName,
      ratio_note: input.ratioNote,
      tasting_note: input.tastingNote,
      brew_note: input.brewNote
    })
    .select(
      "id, user_id, author_nickname, brew_method, title, bean_name, ratio_note, tasting_note, brew_note, created_at"
    )
    .single();

  if (error) {
    throw error;
  }

  return mapHomeBaristaPost(data as HomeBaristaPostRecord);
}
