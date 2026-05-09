import { FormEvent, startTransition, useDeferredValue, useEffect, useMemo, useState } from "react";

import {
  demoCafes,
  demoCommunityPosts,
  demoHomeBaristaPosts,
  demoReviews,
  demoUser
} from "./lib/demoData";
import {
  addBookmark,
  addCommunityPost,
  addHomeBaristaPost,
  addReview,
  fetchBookmarks,
  fetchCafes,
  fetchCommunityPosts,
  fetchCurrentUserProfile,
  fetchHomeBaristaPosts,
  fetchReviews,
  hasSupabaseEnv,
  removeBookmark,
  signInWithEmail,
  signOutCurrentUser,
  signUpWithEmail
} from "./lib/supabase";
import type {
  AppUser,
  AuthIntent,
  Cafe,
  CafeReview,
  CommunityPost,
  HomeBaristaPost
} from "./types";

const demoBookmarksStorageKey = "brewspot-web-demo-bookmarks";
const demoReviewsStorageKey = "brewspot-web-demo-reviews";
const demoCommunityStorageKey = "brewspot-web-demo-community-posts";
const demoHomeBaristaStorageKey = "brewspot-web-demo-homebarista-posts";
const localCommunityFallbackStorageKey = "brewspot-web-local-community-posts";
const localHomeBaristaFallbackStorageKey = "brewspot-web-local-homebarista-posts";

type LocationAccessState = "prompt" | "granted" | "denied" | "unsupported";

const publicInfoLinks = [
  {
    href: `${import.meta.env.BASE_URL}privacy-policy.html`,
    label: "개인정보 / 보안",
    eyebrow: "Privacy",
    description: "개인정보 처리, 위치정보 안내, 보안 대응 기준을 확인할 수 있어요."
  },
  {
    href: `${import.meta.env.BASE_URL}terms.html`,
    label: "이용약관",
    eyebrow: "Terms",
    description: "서비스 이용 조건과 계정, 콘텐츠 운영 기준을 안내합니다."
  },
  {
    href: `${import.meta.env.BASE_URL}support.html`,
    label: "고객지원",
    eyebrow: "Support",
    description: "문의 방법과 운영 연락처, 추가 안내 링크를 확인할 수 있어요."
  }
] as const;
type BrowserLocation = {
  latitude: number;
  longitude: number;
  accuracy: number;
  timestamp: number;
};

type RankingMode = "overall" | "rating" | "reviews" | "nearby";

type AppRoute =
  | { name: "login" }
  | { name: "home" }
  | { name: "community" }
  | { name: "communityPost"; postId: string }
  | { name: "ranking" }
  | { name: "homebarista" }
  | { name: "homebaristaPost"; postId: string }
  | { name: "saved" }
  | { name: "profile" }
  | { name: "cafe"; cafeId: string };

function parseHash(hash: string): AppRoute {
  const normalized = hash.replace(/^#/, "") || "/login";
  const parts = normalized.split("/").filter(Boolean);

  if (parts[0] === "cafes" && parts[1]) {
    return { name: "cafe", cafeId: decodeURIComponent(parts[1]) };
  }

  if (parts[0] === "community" && parts[1]) {
    return { name: "communityPost", postId: decodeURIComponent(parts[1]) };
  }

  if (parts[0] === "homebarista" && parts[1]) {
    return { name: "homebaristaPost", postId: decodeURIComponent(parts[1]) };
  }

  switch (parts[0]) {
    case "home":
      return { name: "home" };
    case "community":
      return { name: "community" };
    case "ranking":
      return { name: "ranking" };
    case "homebarista":
      return { name: "homebarista" };
    case "saved":
      return { name: "saved" };
    case "profile":
      return { name: "profile" };
    case "login":
    default:
      return { name: "login" };
  }
}

function buildHash(route: AppRoute) {
  switch (route.name) {
    case "home":
      return "#/home";
    case "community":
      return "#/community";
    case "communityPost":
      return `#/community/${encodeURIComponent(route.postId)}`;
    case "ranking":
      return "#/ranking";
    case "homebarista":
      return "#/homebarista";
    case "homebaristaPost":
      return `#/homebarista/${encodeURIComponent(route.postId)}`;
    case "saved":
      return "#/saved";
    case "profile":
      return "#/profile";
    case "cafe":
      return `#/cafes/${encodeURIComponent(route.cafeId)}`;
    case "login":
    default:
      return "#/login";
  }
}

function formatRelativeDate(value: string) {
  const formatter = new Intl.RelativeTimeFormat("ko", { numeric: "auto" });
  const date = new Date(value).getTime();
  const diffMs = date - Date.now();
  const diffHours = Math.round(diffMs / (1000 * 60 * 60));

  if (Math.abs(diffHours) < 24) {
    return formatter.format(diffHours, "hour");
  }

  return formatter.format(Math.round(diffHours / 24), "day");
}

function loadStoredStringArray(key: string, fallback: string[]) {
  const saved = window.localStorage.getItem(key);

  if (!saved) {
    return fallback;
  }

  try {
    const parsed = JSON.parse(saved);
    return Array.isArray(parsed) ? parsed.filter((value) => typeof value === "string") : fallback;
  } catch {
    return fallback;
  }
}

function loadStoredObjectArray<T>(key: string, fallback: T[]) {
  const saved = window.localStorage.getItem(key);

  if (!saved) {
    return fallback;
  }

  try {
    const parsed = JSON.parse(saved);
    return Array.isArray(parsed) ? (parsed as T[]) : fallback;
  } catch {
    return fallback;
  }
}

function persistValue(key: string, value: unknown) {
  window.localStorage.setItem(key, JSON.stringify(value));
}

function formatDistance(distanceInMeters: number) {
  if (distanceInMeters < 1000) {
    return `${Math.round(distanceInMeters)}m`;
  }

  return `${(distanceInMeters / 1000).toFixed(1)}km`;
}

function calculateDistanceInMeters(
  fromLatitude: number,
  fromLongitude: number,
  toLatitude: number,
  toLongitude: number
) {
  const toRadians = (value: number) => (value * Math.PI) / 180;
  const earthRadius = 6371000;
  const latitudeDelta = toRadians(toLatitude - fromLatitude);
  const longitudeDelta = toRadians(toLongitude - fromLongitude);
  const startLatitude = toRadians(fromLatitude);
  const endLatitude = toRadians(toLatitude);

  const arc =
    Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
    Math.cos(startLatitude) *
      Math.cos(endLatitude) *
      Math.sin(longitudeDelta / 2) *
      Math.sin(longitudeDelta / 2);

  return 2 * earthRadius * Math.atan2(Math.sqrt(arc), Math.sqrt(1 - arc));
}

function findNearestCafe(location: BrowserLocation | null, cafes: Cafe[]): Cafe | null {
  if (!location || cafes.length === 0) {
    return null;
  }

  let nearestCafe: Cafe | null = null;
  let nearestDistance = Number.POSITIVE_INFINITY;

  cafes.forEach((cafe) => {
    const distance = calculateDistanceInMeters(
      location.latitude,
      location.longitude,
      cafe.latitude,
      cafe.longitude
    );

    if (distance < nearestDistance) {
      nearestCafe = cafe;
      nearestDistance = distance;
    }
  });

  return nearestCafe;
}

function buildMapLayout(cafes: Cafe[], currentLocation: BrowserLocation | null) {
  const latitudes = cafes.map((cafe) => cafe.latitude);
  const longitudes = cafes.map((cafe) => cafe.longitude);

  if (currentLocation) {
    latitudes.push(currentLocation.latitude);
    longitudes.push(currentLocation.longitude);
  }

  if (latitudes.length === 0 || longitudes.length === 0) {
    return {
      cafePins: [] as Array<{ cafe: Cafe; left: number; top: number }>,
      userPin: null as { left: number; top: number } | null
    };
  }

  const minLatitude = Math.min(...latitudes);
  const maxLatitude = Math.max(...latitudes);
  const minLongitude = Math.min(...longitudes);
  const maxLongitude = Math.max(...longitudes);
  const latitudePadding = Math.max((maxLatitude - minLatitude) * 0.2, 0.006);
  const longitudePadding = Math.max((maxLongitude - minLongitude) * 0.2, 0.006);
  const boundedMinLatitude = minLatitude - latitudePadding;
  const boundedMaxLatitude = maxLatitude + latitudePadding;
  const boundedMinLongitude = minLongitude - longitudePadding;
  const boundedMaxLongitude = maxLongitude + longitudePadding;
  const latitudeSpan = Math.max(boundedMaxLatitude - boundedMinLatitude, 0.01);
  const longitudeSpan = Math.max(boundedMaxLongitude - boundedMinLongitude, 0.01);

  const project = (latitude: number, longitude: number) => ({
    left: 10 + ((longitude - boundedMinLongitude) / longitudeSpan) * 80,
    top: 12 + ((boundedMaxLatitude - latitude) / latitudeSpan) * 72
  });

  return {
    cafePins: cafes.map((cafe) => ({
      cafe,
      ...project(cafe.latitude, cafe.longitude)
    })),
    userPin: currentLocation
      ? project(currentLocation.latitude, currentLocation.longitude)
      : null
  };
}

function formatRefreshTime(timestamp: number | null) {
  if (!timestamp) {
    return null;
  }

  return new Date(timestamp).toLocaleTimeString("ko-KR", {
    hour: "numeric",
    minute: "2-digit"
  });
}

function mergeById<T extends { id: string }>(localItems: T[], baseItems: T[]) {
  const dedupedBase = baseItems.filter(
    (baseItem) => !localItems.some((localItem) => localItem.id === baseItem.id)
  );

  return [...localItems, ...dedupedBase];
}

function previewText(content: string, length: number) {
  const trimmed = content.trim();
  if (trimmed.length <= length) {
    return trimmed;
  }

  return `${trimmed.slice(0, length)}...`;
}

export default function App() {
  const [route, setRoute] = useState<AppRoute>(() =>
    typeof window === "undefined" ? { name: "login" } : parseHash(window.location.hash)
  );
  const [authIntent, setAuthIntent] = useState<AuthIntent>("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [nickname, setNickname] = useState("");
  const [searchText, setSearchText] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("전체");
  const [selectedCity, setSelectedCity] = useState("전체");
  const [cafes, setCafes] = useState<Cafe[]>([]);
  const [selectedCafeId, setSelectedCafeId] = useState("");
  const [reviewsByCafe, setReviewsByCafe] = useState<Record<string, CafeReview[]>>({});
  const [bookmarkIds, setBookmarkIds] = useState<string[]>([]);
  const [communityPosts, setCommunityPosts] = useState<CommunityPost[]>([]);
  const [homeBaristaPosts, setHomeBaristaPosts] = useState<HomeBaristaPost[]>([]);
  const [currentUser, setCurrentUser] = useState<AppUser | null>(null);
  const [statusMessage, setStatusMessage] = useState(
    "브루스팟 모바일 웹을 불러오고 있어요."
  );
  const [isBooting, setIsBooting] = useState(true);
  const [isAuthBusy, setIsAuthBusy] = useState(false);
  const [isBookmarkBusy, setIsBookmarkBusy] = useState(false);
  const [isReviewBusy, setIsReviewBusy] = useState(false);
  const [isCommunityBusy, setIsCommunityBusy] = useState(false);
  const [isHomeBaristaBusy, setIsHomeBaristaBusy] = useState(false);
  const [reviewDraft, setReviewDraft] = useState("");
  const [recommendedMenuDraft, setRecommendedMenuDraft] = useState("");
  const [ratingDraft, setRatingDraft] = useState(5);
  const [locationAccessState, setLocationAccessState] = useState<LocationAccessState>("prompt");
  const [currentLocation, setCurrentLocation] = useState<BrowserLocation | null>(null);
  const [locationRequestCount, setLocationRequestCount] = useState(0);
  const [isLocationRefreshing, setIsLocationRefreshing] = useState(false);
  const [lastLocationRefreshAt, setLastLocationRefreshAt] = useState<number | null>(null);
  const [locationErrorMessage, setLocationErrorMessage] = useState<string | null>(null);
  const [communitySearchText, setCommunitySearchText] = useState("");
  const [communityCategory, setCommunityCategory] = useState("전체");
  const [communityComposerOpen, setCommunityComposerOpen] = useState(false);
  const [communityTitleDraft, setCommunityTitleDraft] = useState("");
  const [communityContentDraft, setCommunityContentDraft] = useState("");
  const [communityCityDraft, setCommunityCityDraft] = useState("성수");
  const [homeBaristaMethod, setHomeBaristaMethod] = useState("전체");
  const [homeBaristaComposerOpen, setHomeBaristaComposerOpen] = useState(false);
  const [brewMethodDraft, setBrewMethodDraft] = useState("V60");
  const [brewTitleDraft, setBrewTitleDraft] = useState("");
  const [beanNameDraft, setBeanNameDraft] = useState("");
  const [ratioNoteDraft, setRatioNoteDraft] = useState("");
  const [tastingNoteDraft, setTastingNoteDraft] = useState("");
  const [brewNoteDraft, setBrewNoteDraft] = useState("");
  const [rankingMode, setRankingMode] = useState<RankingMode>("overall");
  const [rankingCity, setRankingCity] = useState("전체");

  const deferredSearchText = useDeferredValue(searchText.trim().toLowerCase());
  const deferredCommunitySearchText = useDeferredValue(
    communitySearchText.trim().toLowerCase()
  );
  const isDemoMode = !hasSupabaseEnv;

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }

    const handleHashChange = () => setRoute(parseHash(window.location.hash));
    window.addEventListener("hashchange", handleHashChange);
    return () => window.removeEventListener("hashchange", handleHashChange);
  }, []);

  function navigate(nextRoute: AppRoute, replace = false) {
    const nextHash = buildHash(nextRoute);

    if (typeof window !== "undefined") {
      if (replace) {
        window.history.replaceState(null, "", nextHash);
      } else {
        window.location.hash = nextHash;
      }
    }

    setRoute(nextRoute);
  }

  useEffect(() => {
    async function boot() {
      if (isDemoMode) {
        const demoReviewList = loadStoredObjectArray<CafeReview>(demoReviewsStorageKey, demoReviews);
        const groupedReviews = demoReviewList.reduce<Record<string, CafeReview[]>>((result, review) => {
          result[review.cafeId] = [...(result[review.cafeId] ?? []), review];
          return result;
        }, {});

        setCafes(demoCafes);
        setBookmarkIds(
          loadStoredStringArray(demoBookmarksStorageKey, [
            demoCafes[0]?.id ?? "",
            demoCafes[2]?.id ?? ""
          ].filter(Boolean))
        );
        setReviewsByCafe(groupedReviews);
        setCommunityPosts(
          loadStoredObjectArray<CommunityPost>(demoCommunityStorageKey, demoCommunityPosts)
        );
        setHomeBaristaPosts(
          loadStoredObjectArray<HomeBaristaPost>(demoHomeBaristaStorageKey, demoHomeBaristaPosts)
        );
        setSelectedCafeId(demoCafes[0]?.id ?? "");
        setStatusMessage("기본 데이터로 화면을 불러왔어요. 로그인과 주요 흐름을 바로 둘러볼 수 있어요.");
        setIsBooting(false);
        return;
      }

      try {
        const [loadedCafes, profile, loadedBookmarks] = await Promise.all([
          fetchCafes(),
          fetchCurrentUserProfile(),
          fetchBookmarks()
        ]);

        setCafes(loadedCafes);
        setCurrentUser(profile);
        setBookmarkIds(loadedBookmarks);
        setSelectedCafeId(loadedCafes[0]?.id ?? "");

        const storedLocalCommunity = loadStoredObjectArray<CommunityPost>(
          localCommunityFallbackStorageKey,
          []
        );
        const storedLocalHomeBarista = loadStoredObjectArray<HomeBaristaPost>(
          localHomeBaristaFallbackStorageKey,
          []
        );

        try {
          const remoteCommunity = await fetchCommunityPosts();
          setCommunityPosts(mergeById(storedLocalCommunity, remoteCommunity));
        } catch {
          setCommunityPosts(mergeById(storedLocalCommunity, demoCommunityPosts));
        }

        try {
          const remoteHomeBarista = await fetchHomeBaristaPosts();
          setHomeBaristaPosts(mergeById(storedLocalHomeBarista, remoteHomeBarista));
        } catch {
          setHomeBaristaPosts(mergeById(storedLocalHomeBarista, demoHomeBaristaPosts));
        }

        setStatusMessage("브루스팟 계정과 연결되었어요. 모바일 웹에서 바로 이어서 사용할 수 있습니다.");
      } catch (error) {
        setStatusMessage(
          getErrorMessage(error, "Supabase 연결에 실패해서 현재 화면을 불러오지 못했어요.")
        );
      } finally {
        setIsBooting(false);
      }
    }

    void boot();
  }, [isDemoMode]);

  useEffect(() => {
    if (typeof window === "undefined" || isBooting) {
      return;
    }

    if (!window.location.hash) {
      navigate(currentUser ? { name: "home" } : { name: "login" }, true);
      return;
    }

    if (!currentUser && route.name !== "login") {
      navigate({ name: "login" }, true);
      return;
    }

    if (currentUser && route.name === "login") {
      navigate({ name: "home" }, true);
    }
  }, [currentUser, isBooting, route.name]);

  useEffect(() => {
    if (!selectedCafeId || isDemoMode) {
      return;
    }

    let cancelled = false;

    async function loadReviews() {
      try {
        const loadedReviews = await fetchReviews(selectedCafeId);
        if (!cancelled) {
          setReviewsByCafe((current) => ({
            ...current,
            [selectedCafeId]: loadedReviews
          }));
        }
      } catch (error) {
        if (!cancelled) {
          setStatusMessage(getErrorMessage(error, "리뷰를 불러오지 못했어요."));
        }
      }
    }

    void loadReviews();
    return () => {
      cancelled = true;
    };
  }, [isDemoMode, selectedCafeId]);

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }

    if (!("geolocation" in navigator)) {
      setLocationAccessState("unsupported");
      return;
    }

    let mounted = true;
    let permissionStatus: PermissionStatus | null = null;
    let handlePermissionChange: (() => void) | null = null;

    async function syncGeolocationPermission() {
      if (!("permissions" in navigator) || typeof navigator.permissions.query !== "function") {
        setLocationAccessState("prompt");
        return;
      }

      try {
        permissionStatus = await navigator.permissions.query({
          name: "geolocation" as PermissionName
        });

        if (!mounted || !permissionStatus) {
          return;
        }

        handlePermissionChange = () => {
          const nextState =
            permissionStatus?.state === "granted"
              ? "granted"
              : permissionStatus?.state === "denied"
                ? "denied"
                : "prompt";

          setLocationAccessState(nextState);

          if (nextState === "denied") {
            setCurrentLocation(null);
            setLocationErrorMessage("브라우저 설정에서 위치 권한을 허용하면 내 주변 카페를 볼 수 있어요.");
          }
        };

        handlePermissionChange();
        permissionStatus.addEventListener?.("change", handlePermissionChange);
      } catch {
        if (mounted) {
          setLocationAccessState("prompt");
        }
      }
    }

    void syncGeolocationPermission();

    return () => {
      mounted = false;
      if (permissionStatus && handlePermissionChange) {
        permissionStatus.removeEventListener?.("change", handlePermissionChange);
      }
    };
  }, []);

  useEffect(() => {
    if (route.name === "cafe") {
      setSelectedCafeId(route.cafeId);
    }
  }, [route]);

  useEffect(() => {
    if (locationAccessState === "granted" && !currentLocation && cafes.length > 0) {
      requestCurrentLocation({ incrementCount: false, announce: false });
    }
  }, [cafes.length, currentLocation, locationAccessState]);

  const categories = ["전체", ...Array.from(new Set(cafes.map((cafe) => cafe.category)))];
  const cities = ["전체", ...Array.from(new Set(cafes.map((cafe) => cafe.city)))];

  const filteredCafes = cafes.filter((cafe) => {
    const matchesSearch =
      !deferredSearchText ||
      [
        cafe.name,
        cafe.address,
        cafe.category,
        cafe.city,
        cafe.signatureMenu,
        ...cafe.vibeTags
      ]
        .join(" ")
        .toLowerCase()
        .includes(deferredSearchText);

    const matchesCategory = selectedCategory === "전체" || cafe.category === selectedCategory;
    const matchesCity = selectedCity === "전체" || cafe.city === selectedCity;

    return matchesSearch && matchesCategory && matchesCity;
  });

  const selectedCafe =
    cafes.find((cafe) => cafe.id === selectedCafeId) ??
    (route.name === "cafe" ? cafes.find((cafe) => cafe.id === route.cafeId) ?? null : null);
  const selectedCommunityPost =
    route.name === "communityPost"
      ? communityPosts.find((post) => post.id === route.postId) ?? null
      : null;
  const selectedHomeBaristaPost =
    route.name === "homebaristaPost"
      ? homeBaristaPosts.find((post) => post.id === route.postId) ?? null
      : null;

  const savedCafes = cafes.filter((cafe) => bookmarkIds.includes(cafe.id));
  const selectedCafeReviews = selectedCafe ? reviewsByCafe[selectedCafe.id] ?? [] : [];
  const myReviewCount = Object.values(reviewsByCafe)
    .flat()
    .filter((review) => review.userId === currentUser?.id).length;
  const nearestFilteredCafe = findNearestCafe(currentLocation, filteredCafes);
  const currentPlaceSummary = currentLocation
    ? nearestFilteredCafe
      ? `${nearestFilteredCafe.city} 근처`
      : `${currentLocation.latitude.toFixed(3)}, ${currentLocation.longitude.toFixed(3)}`
    : null;
  const locationRefreshText = isLocationRefreshing
    ? "현재 위치를 다시 확인하고 있어요."
    : locationErrorMessage
      ? locationErrorMessage
      : formatRefreshTime(lastLocationRefreshAt)
        ? `최근 확인: ${formatRefreshTime(lastLocationRefreshAt)}`
        : null;

  useEffect(() => {
    if (route.name === "communityPost" && !selectedCommunityPost && communityPosts.length > 0) {
      navigate({ name: "community" }, true);
    }
  }, [communityPosts.length, route, selectedCommunityPost]);

  useEffect(() => {
    if (
      route.name === "homebaristaPost" &&
      !selectedHomeBaristaPost &&
      homeBaristaPosts.length > 0
    ) {
      navigate({ name: "homebarista" }, true);
    }
  }, [homeBaristaPosts.length, route, selectedHomeBaristaPost]);

  const communityCategories = useMemo(
    () => ["전체", ...Array.from(new Set(communityPosts.map((post) => post.category)))],
    [communityPosts]
  );

  const filteredCommunityPosts = communityPosts.filter((post) => {
    const matchesCategory = communityCategory === "전체" || post.category === communityCategory;
    const matchesSearch =
      !deferredCommunitySearchText ||
      [post.title, post.content, post.authorName, post.city]
        .join(" ")
        .toLowerCase()
        .includes(deferredCommunitySearchText);

    return matchesCategory && matchesSearch;
  });

  const homeBaristaMethods = useMemo(
    () => ["전체", ...Array.from(new Set(homeBaristaPosts.map((post) => post.brewMethod)))],
    [homeBaristaPosts]
  );

  const filteredHomeBaristaPosts = homeBaristaPosts.filter(
    (post) => homeBaristaMethod === "전체" || post.brewMethod === homeBaristaMethod
  );

  const rankingCities = ["전체", ...Array.from(new Set(cafes.map((cafe) => cafe.city)))];
  const rankingCandidates = cafes.filter(
    (cafe) => rankingCity === "전체" || cafe.city === rankingCity
  );

  const rankingEntries = rankingCandidates
    .slice()
    .sort((left, right) => {
      if (rankingMode === "rating") {
        return right.rating - left.rating || right.reviewCount - left.reviewCount;
      }

      if (rankingMode === "reviews") {
        return right.reviewCount - left.reviewCount || right.rating - left.rating;
      }

      if (rankingMode === "nearby") {
        const leftDistance = currentLocation
          ? calculateDistanceInMeters(
              currentLocation.latitude,
              currentLocation.longitude,
              left.latitude,
              left.longitude
            )
          : Number.POSITIVE_INFINITY;
        const rightDistance = currentLocation
          ? calculateDistanceInMeters(
              currentLocation.latitude,
              currentLocation.longitude,
              right.latitude,
              right.longitude
            )
          : Number.POSITIVE_INFINITY;

        return leftDistance - rightDistance;
      }

      const leftScore = left.rating * 10 + left.reviewCount * 0.6;
      const rightScore = right.rating * 10 + right.reviewCount * 0.6;
      return rightScore - leftScore;
    })
    .slice(0, 10)
    .map((cafe, index) => ({
      rank: index + 1,
      cafe,
      highlight:
        rankingMode === "reviews"
          ? `리뷰 ${cafe.reviewCount}개`
          : rankingMode === "nearby"
            ? currentLocation
              ? getDistanceTextForLocation(currentLocation, cafe)
              : "위치 미확인"
            : `평점 ${cafe.rating.toFixed(1)}`,
      detail: `${cafe.city} · ${cafe.category} · ${cafe.signatureMenu}`
    }));

  function getDistanceText(cafe: Cafe) {
    return currentLocation ? getDistanceTextForLocation(currentLocation, cafe) : null;
  }

  function getDistanceTextForLocation(location: BrowserLocation, cafe: Cafe) {
    return formatDistance(
      calculateDistanceInMeters(location.latitude, location.longitude, cafe.latitude, cafe.longitude)
    );
  }

  function requestCurrentLocation(options?: { incrementCount?: boolean; announce?: boolean }) {
    if (!("geolocation" in navigator)) {
      setLocationAccessState("unsupported");
      setLocationErrorMessage("이 브라우저에서는 위치 기능을 지원하지 않아요.");
      if (options?.announce) {
        setStatusMessage("이 브라우저에서는 위치 기능을 지원하지 않아요.");
      }
      return;
    }

    if (options?.incrementCount ?? true) {
      setLocationRequestCount((count) => count + 1);
    }

    setIsLocationRefreshing(true);
    setLocationErrorMessage(null);

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const nextLocation: BrowserLocation = {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
          accuracy: position.coords.accuracy,
          timestamp: position.timestamp
        };

        setCurrentLocation(nextLocation);
        setLocationAccessState("granted");
        setLastLocationRefreshAt(Date.now());
        setIsLocationRefreshing(false);
        setLocationErrorMessage(null);

        if (options?.announce ?? true) {
          const nearestCafe = findNearestCafe(nextLocation, cafes);
          setStatusMessage(
            nearestCafe
              ? `현재 위치를 확인했어요. 가장 가까운 카페는 ${nearestCafe.name}입니다.`
              : "현재 위치를 확인했어요."
          );
        }
      },
      (error) => {
        const nextMessage =
          error.code === error.PERMISSION_DENIED
            ? "브라우저에서 위치 권한이 거부되어 있어요."
            : error.code === error.POSITION_UNAVAILABLE
              ? "현재 위치를 아직 찾지 못했어요. 잠시 후 다시 시도해 주세요."
              : error.code === error.TIMEOUT
                ? "위치 확인 시간이 초과됐어요. 다시 시도해 주세요."
                : "현재 위치를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.";

        setLocationAccessState((current) =>
          error.code === error.PERMISSION_DENIED ? "denied" : current
        );
        setCurrentLocation(null);
        setIsLocationRefreshing(false);
        setLocationErrorMessage(nextMessage);

        if (options?.announce ?? true) {
          setStatusMessage(nextMessage);
        }
      },
      {
        enableHighAccuracy: false,
        timeout: 10000,
        maximumAge: 1000 * 60 * 5
      }
    );
  }

  function handlePrimaryLocationAction() {
    if (locationAccessState === "granted" || locationAccessState === "prompt") {
      requestCurrentLocation({ incrementCount: true, announce: true });
      return;
    }

    if (locationAccessState === "denied") {
      const nextMessage = "브라우저 주소창 옆 사이트 설정에서 위치 권한을 허용해 주세요.";
      setLocationErrorMessage(nextMessage);
      setStatusMessage(nextMessage);
      return;
    }

    const nextMessage = "이 브라우저에서는 위치 기능을 사용할 수 없어요.";
    setLocationErrorMessage(nextMessage);
    setStatusMessage(nextMessage);
  }

  function openCafe(cafeId: string) {
    setSelectedCafeId(cafeId);
    navigate({ name: "cafe", cafeId });
  }

  function openCommunityPost(postId: string) {
    navigate({ name: "communityPost", postId });
  }

  function openHomeBaristaPost(postId: string) {
    navigate({ name: "homebaristaPost", postId });
  }

  async function handleAuthSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsAuthBusy(true);

    try {
      if (isDemoMode) {
        setCurrentUser({
          ...demoUser,
          nickname: nickname.trim() || demoUser.nickname,
          email: email.trim() || demoUser.email
        });
        setStatusMessage("미리보기 세션으로 로그인했어요. 전체 웹 흐름을 바로 둘러볼 수 있습니다.");
        navigate({ name: "home" }, true);
        return;
      }

      if (authIntent === "signin") {
        const profile = await signInWithEmail(email.trim(), password);
        const loadedBookmarks = await fetchBookmarks();
        setCurrentUser(profile);
        setBookmarkIds(loadedBookmarks);
        setStatusMessage("다시 돌아오신 걸 환영해요.");
        navigate({ name: "home" }, true);
      } else {
        await signUpWithEmail(email.trim(), password, nickname.trim());
        setStatusMessage("회원가입 요청을 보냈어요. 인증 확인 후 로그인해 주세요.");
        setAuthIntent("signin");
      }
    } catch (error) {
      setStatusMessage(getErrorMessage(error, "로그인 처리에 실패했어요."));
    } finally {
      setIsAuthBusy(false);
    }
  }

  async function handleSignOut() {
    try {
      if (isDemoMode) {
        setCurrentUser(null);
        setStatusMessage("로그아웃했어요.");
        navigate({ name: "login" }, true);
        return;
      }

      await signOutCurrentUser();
      setCurrentUser(null);
      setBookmarkIds([]);
      setStatusMessage("로그아웃했어요.");
      navigate({ name: "login" }, true);
    } catch (error) {
      setStatusMessage(getErrorMessage(error, "로그아웃에 실패했어요."));
    }
  }

  async function handleBookmarkToggle(cafeId: string) {
    if (!currentUser) {
      setStatusMessage("북마크하려면 먼저 로그인해 주세요.");
      navigate({ name: "login" });
      return;
    }

    setIsBookmarkBusy(true);

    try {
      const isSaved = bookmarkIds.includes(cafeId);

      if (isDemoMode) {
        const next = isSaved
          ? bookmarkIds.filter((id) => id !== cafeId)
          : [cafeId, ...bookmarkIds];
        setBookmarkIds(next);
        persistValue(demoBookmarksStorageKey, next);
      } else if (isSaved) {
        await removeBookmark(cafeId);
        setBookmarkIds((current) => current.filter((id) => id !== cafeId));
      } else {
        await addBookmark(cafeId);
        setBookmarkIds((current) => [cafeId, ...current]);
      }

      setStatusMessage(isSaved ? "저장한 카페에서 뺐어요." : "카페를 저장했어요.");
    } catch (error) {
      setStatusMessage(getErrorMessage(error, "북마크 처리에 실패했어요."));
    } finally {
      setIsBookmarkBusy(false);
    }
  }

  async function handleReviewSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!selectedCafe || !currentUser) {
      setStatusMessage("리뷰를 남기려면 카페를 선택하고 로그인해 주세요.");
      return;
    }

    setIsReviewBusy(true);

    try {
      if (isDemoMode) {
        const nextReview: CafeReview = {
          id: `demo-review-${crypto.randomUUID()}`,
          userId: currentUser.id,
          cafeId: selectedCafe.id,
          authorNickname: currentUser.nickname,
          overallRating: ratingDraft,
          recommendedMenuName: recommendedMenuDraft.trim(),
          content: reviewDraft.trim(),
          createdAt: new Date().toISOString()
        };

        const nextReviewMap = {
          ...reviewsByCafe,
          [selectedCafe.id]: [nextReview, ...(reviewsByCafe[selectedCafe.id] ?? [])]
        };
        setReviewsByCafe(nextReviewMap);
        persistValue(demoReviewsStorageKey, Object.values(nextReviewMap).flat());
      } else {
        const createdReview = await addReview({
          cafeId: selectedCafe.id,
          authorNickname: currentUser.nickname,
          overallRating: ratingDraft,
          content: reviewDraft.trim(),
          recommendedMenuName: recommendedMenuDraft.trim()
        });

        setReviewsByCafe((current) => ({
          ...current,
          [selectedCafe.id]: [createdReview, ...(current[selectedCafe.id] ?? [])]
        }));
      }

      setReviewDraft("");
      setRecommendedMenuDraft("");
      setRatingDraft(5);
      setStatusMessage("리뷰가 저장됐어요.");
    } catch (error) {
      setStatusMessage(getErrorMessage(error, "리뷰 저장에 실패했어요."));
    } finally {
      setIsReviewBusy(false);
    }
  }

  async function handleCommunitySubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!currentUser) {
      setStatusMessage("글을 남기려면 먼저 로그인해 주세요.");
      return;
    }

    setIsCommunityBusy(true);

    const fallbackPost: CommunityPost = {
      id: `community-${crypto.randomUUID()}`,
      authorId: currentUser.id,
      authorName: currentUser.nickname,
      category: communityCategory === "전체" ? "자유" : communityCategory,
      title: communityTitleDraft.trim(),
      content: communityContentDraft.trim(),
      city: communityCityDraft.trim() || "동네 미정",
      likeCount: 0,
      commentCount: 0,
      createdAt: new Date().toISOString(),
      source: isDemoMode ? "sample" : "localFallback"
    };

    try {
      if (isDemoMode) {
        const nextPosts = [fallbackPost, ...communityPosts];
        setCommunityPosts(nextPosts);
        persistValue(demoCommunityStorageKey, nextPosts);
      } else {
        try {
          const createdPost = await addCommunityPost({
            title: communityTitleDraft.trim(),
            content: communityContentDraft.trim(),
            category: communityCategory === "전체" ? "자유" : communityCategory,
            city: communityCityDraft.trim() || "동네 미정",
            authorNickname: currentUser.nickname
          });
          setCommunityPosts((current) => [createdPost, ...current]);
        } catch {
          const storedLocal = loadStoredObjectArray<CommunityPost>(
            localCommunityFallbackStorageKey,
            []
          );
          const nextPosts = [fallbackPost, ...communityPosts];
          setCommunityPosts(nextPosts);
          persistValue(localCommunityFallbackStorageKey, [fallbackPost, ...storedLocal]);
          setStatusMessage("커뮤니티 서버 대신 이 기기에 임시로 저장했어요.");
        }
      }

      setCommunityTitleDraft("");
      setCommunityContentDraft("");
      setCommunityComposerOpen(false);
      setStatusMessage("커뮤니티 글을 올렸어요.");
    } finally {
      setIsCommunityBusy(false);
    }
  }

  async function handleHomeBaristaSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!currentUser) {
      setStatusMessage("레시피를 공유하려면 먼저 로그인해 주세요.");
      return;
    }

    setIsHomeBaristaBusy(true);

    const fallbackPost: HomeBaristaPost = {
      id: `homebarista-${crypto.randomUUID()}`,
      authorId: currentUser.id,
      authorName: currentUser.nickname,
      brewMethod: brewMethodDraft,
      title: brewTitleDraft.trim(),
      beanName: beanNameDraft.trim(),
      ratioNote: ratioNoteDraft.trim(),
      tastingNote: tastingNoteDraft.trim(),
      brewNote: brewNoteDraft.trim(),
      createdAt: new Date().toISOString(),
      source: isDemoMode ? "sample" : "localFallback"
    };

    try {
      if (isDemoMode) {
        const nextPosts = [fallbackPost, ...homeBaristaPosts];
        setHomeBaristaPosts(nextPosts);
        persistValue(demoHomeBaristaStorageKey, nextPosts);
      } else {
        try {
          const createdPost = await addHomeBaristaPost({
            brewMethod: brewMethodDraft,
            title: brewTitleDraft.trim(),
            beanName: beanNameDraft.trim(),
            ratioNote: ratioNoteDraft.trim(),
            tastingNote: tastingNoteDraft.trim(),
            brewNote: brewNoteDraft.trim(),
            authorNickname: currentUser.nickname
          });
          setHomeBaristaPosts((current) => [createdPost, ...current]);
        } catch {
          const storedLocal = loadStoredObjectArray<HomeBaristaPost>(
            localHomeBaristaFallbackStorageKey,
            []
          );
          const nextPosts = [fallbackPost, ...homeBaristaPosts];
          setHomeBaristaPosts(nextPosts);
          persistValue(localHomeBaristaFallbackStorageKey, [fallbackPost, ...storedLocal]);
          setStatusMessage("홈바리스타 서버 대신 이 기기에 임시로 저장했어요.");
        }
      }

      setBrewTitleDraft("");
      setBeanNameDraft("");
      setRatioNoteDraft("");
      setTastingNoteDraft("");
      setBrewNoteDraft("");
      setHomeBaristaComposerOpen(false);
      setStatusMessage("홈바리스타 레시피를 공유했어요.");
    } finally {
      setIsHomeBaristaBusy(false);
    }
  }

  const isAuthenticated = Boolean(currentUser);
  const mapLayout = buildMapLayout(filteredCafes, currentLocation);

  return (
    <div className="mobile-web">
      <div className="device-frame">
        {route.name === "login" ? (
          <LoginPage
            authIntent={authIntent}
            email={email}
            isAuthBusy={isAuthBusy}
            nickname={nickname}
            onAuthIntentChange={setAuthIntent}
            onSubmit={handleAuthSubmit}
            password={password}
            setEmail={setEmail}
            setNickname={setNickname}
            setPassword={setPassword}
            statusMessage={statusMessage}
          />
        ) : (
          <>
            <TopBar
              onBack={
                route.name === "cafe"
                  ? () => navigate({ name: "home" })
                  : route.name === "communityPost"
                    ? () => navigate({ name: "community" })
                    : route.name === "homebaristaPost"
                      ? () => navigate({ name: "homebarista" })
                      : undefined
              }
              route={route}
              selectedCafeName={selectedCafe?.name ?? null}
              selectedCommunityTitle={selectedCommunityPost?.title ?? null}
              selectedHomeBaristaTitle={selectedHomeBaristaPost?.title ?? null}
            />

            <div className="screen-content">
              <StatusBanner message={statusMessage} />

              {route.name === "home" ? (
                <HomePage
                  bookmarkIds={bookmarkIds}
                  categories={categories}
                  cities={cities}
                  currentLocation={currentLocation}
                  currentPlaceSummary={currentPlaceSummary}
                  currentUser={currentUser}
                  filteredCafes={filteredCafes}
                  getDistanceText={getDistanceText}
                  handlePrimaryLocationAction={handlePrimaryLocationAction}
                  isBookmarkBusy={isBookmarkBusy}
                  isLocationRefreshing={isLocationRefreshing}
                  locationAccessState={locationAccessState}
                  locationRefreshText={locationRefreshText}
                  locationRequestCount={locationRequestCount}
                  mapLayout={mapLayout}
                  nearestVisibleCafe={nearestFilteredCafe}
                  onBookmarkToggle={handleBookmarkToggle}
                  onCategoryChange={setSelectedCategory}
                  onCityChange={setSelectedCity}
                  onOpenCafe={openCafe}
                  onRefreshLocation={() =>
                    requestCurrentLocation({ incrementCount: false, announce: true })
                  }
                  onSearchChange={setSearchText}
                  searchText={searchText}
                  selectedCategory={selectedCategory}
                  selectedCity={selectedCity}
                  selectedCafeId={selectedCafeId}
                />
              ) : null}

              {route.name === "community" ? (
                <CommunityPage
                  categories={communityCategories}
                  communityCategory={communityCategory}
                  communityCityDraft={communityCityDraft}
                  communityComposerOpen={communityComposerOpen}
                  communityContentDraft={communityContentDraft}
                  communityPosts={filteredCommunityPosts}
                  communitySearchText={communitySearchText}
                  communityTitleDraft={communityTitleDraft}
                  isCommunityBusy={isCommunityBusy}
                  onCategoryChange={setCommunityCategory}
                  onCityDraftChange={setCommunityCityDraft}
                  onComposerToggle={() => setCommunityComposerOpen((current) => !current)}
                  onContentDraftChange={setCommunityContentDraft}
                  onOpenPost={openCommunityPost}
                  onSearchChange={setCommunitySearchText}
                  onSubmit={handleCommunitySubmit}
                  onTitleDraftChange={setCommunityTitleDraft}
                />
              ) : null}

              {route.name === "communityPost" && selectedCommunityPost ? (
                <CommunityPostDetailPage post={selectedCommunityPost} />
              ) : null}

              {route.name === "ranking" ? (
                <RankingPage
                  currentLocation={currentLocation}
                  onCityChange={setRankingCity}
                  onModeChange={setRankingMode}
                  onOpenCafe={openCafe}
                  rankingCity={rankingCity}
                  rankingEntries={rankingEntries}
                  rankingMode={rankingMode}
                  rankingNote={
                    rankingMode === "overall"
                      ? "평점과 리뷰 균형"
                      : rankingMode === "rating"
                        ? "평점 우선"
                        : rankingMode === "reviews"
                          ? "리뷰 수 우선"
                          : currentLocation
                            ? "거리 우선"
                            : "위치 미확인"
                  }
                  rankingCities={rankingCities}
                />
              ) : null}

              {route.name === "homebarista" ? (
                <HomeBaristaPage
                  beanNameDraft={beanNameDraft}
                  brewMethodDraft={brewMethodDraft}
                  brewNoteDraft={brewNoteDraft}
                  composerOpen={homeBaristaComposerOpen}
                  isBusy={isHomeBaristaBusy}
                  methodFilter={homeBaristaMethod}
                  methods={homeBaristaMethods}
                  onBeanNameDraftChange={setBeanNameDraft}
                  onBrewMethodDraftChange={setBrewMethodDraft}
                  onBrewNoteDraftChange={setBrewNoteDraft}
                  onComposerToggle={() => setHomeBaristaComposerOpen((current) => !current)}
                  onMethodFilterChange={setHomeBaristaMethod}
                  onOpenPost={openHomeBaristaPost}
                  onRatioDraftChange={setRatioNoteDraft}
                  onSubmit={handleHomeBaristaSubmit}
                  onTastingDraftChange={setTastingNoteDraft}
                  onTitleDraftChange={setBrewTitleDraft}
                  posts={filteredHomeBaristaPosts}
                  ratioNoteDraft={ratioNoteDraft}
                  tastingNoteDraft={tastingNoteDraft}
                  titleDraft={brewTitleDraft}
                />
              ) : null}

              {route.name === "homebaristaPost" && selectedHomeBaristaPost ? (
                <HomeBaristaDetailPage post={selectedHomeBaristaPost} />
              ) : null}

              {route.name === "saved" ? (
                <SavedPage
                  currentUser={currentUser}
                  getDistanceText={getDistanceText}
                  isBookmarkBusy={isBookmarkBusy}
                  onBookmarkToggle={handleBookmarkToggle}
                  onOpenCafe={openCafe}
                  savedCafes={savedCafes}
                />
              ) : null}

              {route.name === "profile" ? (
                <ProfilePage
                  currentUser={currentUser}
                  onSignOut={handleSignOut}
                  savedCafeCount={savedCafes.length}
                  totalReviewCount={myReviewCount}
                />
              ) : null}

              {route.name === "cafe" && selectedCafe ? (
                <CafeDetailPage
                  cafe={selectedCafe}
                  currentUser={currentUser}
                  distanceText={getDistanceText(selectedCafe)}
                  isBookmarkBusy={isBookmarkBusy}
                  isReviewBusy={isReviewBusy}
                  isSaved={bookmarkIds.includes(selectedCafe.id)}
                  onBookmarkToggle={() => void handleBookmarkToggle(selectedCafe.id)}
                  onRecommendedMenuChange={setRecommendedMenuDraft}
                  onRatingChange={setRatingDraft}
                  onReviewSubmit={handleReviewSubmit}
                  onReviewTextChange={setReviewDraft}
                  ratingDraft={ratingDraft}
                  recommendedMenuDraft={recommendedMenuDraft}
                  reviewDraft={reviewDraft}
                  reviews={selectedCafeReviews}
                />
              ) : null}
            </div>

            {isAuthenticated ? (
              <BottomActionStack
                currentRoute={route}
                onNavigate={(nextRoute) => startTransition(() => navigate(nextRoute))}
              />
            ) : null}
          </>
        )}
      </div>
    </div>
  );
}

function LoginPage(props: {
  authIntent: AuthIntent;
  email: string;
  isAuthBusy: boolean;
  nickname: string;
  onAuthIntentChange: (value: AuthIntent) => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  password: string;
  setEmail: (value: string) => void;
  setNickname: (value: string) => void;
  setPassword: (value: string) => void;
  statusMessage: string;
}) {
  const {
    authIntent,
    email,
    isAuthBusy,
    nickname,
    onAuthIntentChange,
    onSubmit,
    password,
    setEmail,
    setNickname,
    setPassword,
    statusMessage
  } = props;

  return (
    <div className="login-screen">
      <div className="login-hero">
        <p className="eyebrow">BrewSpot Mobile Web</p>
        <h1>카페 탐색부터 라운지 기능까지 모바일 웹으로 이어집니다.</h1>
        <p>로그인 후 홈, 저장, 커뮤니티, 랭킹, 홈바리스타 페이지를 각각 따로 이동할 수 있어요.</p>
      </div>

      <div className="login-card">
        <div className="segmented-control">
          <button className={authIntent === "signin" ? "active" : ""} onClick={() => onAuthIntentChange("signin")} type="button">
            로그인
          </button>
          <button className={authIntent === "signup" ? "active" : ""} onClick={() => onAuthIntentChange("signup")} type="button">
            회원가입
          </button>
        </div>

        <form className="stack-form" onSubmit={onSubmit}>
          {authIntent === "signup" ? (
            <label>
              닉네임
              <input onChange={(event) => setNickname(event.target.value)} placeholder="brew_jane" value={nickname} />
            </label>
          ) : null}
          <label>
            이메일
            <input onChange={(event) => setEmail(event.target.value)} placeholder="user@example.com" type="email" value={email} />
          </label>
          <label>
            비밀번호
            <input onChange={(event) => setPassword(event.target.value)} placeholder="8자 이상" type="password" value={password} />
          </label>
          <button className="primary-cta" disabled={isAuthBusy} type="submit">
            {isAuthBusy ? "처리 중..." : authIntent === "signin" ? "이메일 로그인" : "이메일 회원가입"}
          </button>
        </form>

        <div className="info-panel">
          <p>{statusMessage}</p>
        </div>
      </div>
    </div>
  );
}

function HomePage(props: {
  bookmarkIds: string[];
  categories: string[];
  cities: string[];
  currentLocation: BrowserLocation | null;
  currentPlaceSummary: string | null;
  currentUser: AppUser | null;
  filteredCafes: Cafe[];
  getDistanceText: (cafe: Cafe) => string | null;
  handlePrimaryLocationAction: () => void;
  isBookmarkBusy: boolean;
  isLocationRefreshing: boolean;
  locationAccessState: LocationAccessState;
  locationRefreshText: string | null;
  locationRequestCount: number;
  mapLayout: ReturnType<typeof buildMapLayout>;
  nearestVisibleCafe: Cafe | null;
  onBookmarkToggle: (cafeId: string) => Promise<void>;
  onCategoryChange: (value: string) => void;
  onCityChange: (value: string) => void;
  onOpenCafe: (cafeId: string) => void;
  onRefreshLocation: () => void;
  onSearchChange: (value: string) => void;
  searchText: string;
  selectedCategory: string;
  selectedCity: string;
  selectedCafeId: string;
}) {
  const {
    bookmarkIds,
    categories,
    cities,
    currentLocation,
    currentPlaceSummary,
    currentUser,
    filteredCafes,
    getDistanceText,
    handlePrimaryLocationAction,
    isBookmarkBusy,
    isLocationRefreshing,
    locationAccessState,
    locationRefreshText,
    locationRequestCount,
    mapLayout,
    nearestVisibleCafe,
    onBookmarkToggle,
    onCategoryChange,
    onCityChange,
    onOpenCafe,
    onRefreshLocation,
    onSearchChange,
    searchText,
    selectedCategory,
    selectedCity,
    selectedCafeId
  } = props;

  return (
    <div className="page-stack">
      <section className="hero-panel">
        <div className="hero-row">
          <div>
            <p className="eyebrow">Home</p>
            <h2>{currentUser ? `${currentUser.nickname}님, 오늘은 어디로 갈까요?` : "오늘의 BrewSpot"}</h2>
          </div>
        </div>
        <p className="hero-copy">홈에서는 카페 탐색에 집중하고, 라운지 이야기는 하단 `라운지` 탭에서 이어보세요.</p>
        {nearestVisibleCafe ? (
          <div className="quick-stat-card">
            <span className="mini-label">가장 가까운 카페</span>
            <strong>{nearestVisibleCafe.name}</strong>
            <p>{getDistanceText(nearestVisibleCafe)} · 지금 보고 있는 카페 중 가장 가깝습니다.</p>
          </div>
        ) : null}
      </section>

      <section className="panel-card">
        <label className="field-block">
          <span>검색</span>
          <input
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder="카페 이름, 지역, 메뉴, 분위기"
            value={searchText}
          />
        </label>

        <div className="chip-section">
          <p className="section-caption">카테고리</p>
          <div className="chip-scroll">
            {categories.map((category) => (
              <button className={selectedCategory === category ? "filter-chip active" : "filter-chip"} key={category} onClick={() => onCategoryChange(category)} type="button">
                {category}
              </button>
            ))}
          </div>
        </div>

        <div className="chip-section">
          <p className="section-caption">지역</p>
          <div className="chip-scroll">
            {cities.map((city) => (
              <button className={selectedCity === city ? "filter-chip active" : "filter-chip"} key={city} onClick={() => onCityChange(city)} type="button">
                {city}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section className="panel-card">
        <div className="section-head">
          <div>
            <p className="section-caption">현재 위치</p>
            <h3>내 주변 탐색</h3>
          </div>
          <span className="meta-pill">요청 {locationRequestCount}회</span>
        </div>

        <div className="two-up">
          <div className="soft-card">
            <span className="mini-label">권한 상태</span>
            <strong>
              {locationAccessState === "granted"
                ? "허용됨"
                : locationAccessState === "denied"
                  ? "거부됨"
                  : locationAccessState === "unsupported"
                    ? "미지원"
                    : "대기 중"}
            </strong>
          </div>
          <div className="soft-card">
            <span className="mini-label">현재 기준</span>
            <strong>{currentPlaceSummary ?? "위치 정보 없음"}</strong>
          </div>
        </div>

        {locationRefreshText ? (
          <p className={locationAccessState === "denied" ? "feedback warning" : "feedback"}>
            {locationRefreshText}
          </p>
        ) : null}

        {currentLocation ? (
          <p className="helper-text">정확도 약 {Math.round(currentLocation.accuracy)}m 기준으로 표시 중입니다.</p>
        ) : null}

        <div className="button-row">
          <button className="primary-cta compact" onClick={handlePrimaryLocationAction} type="button">
            {locationAccessState === "granted" ? "내 위치 사용 중" : "위치 권한 요청"}
          </button>
          {locationAccessState === "granted" ? (
            <button className="secondary-cta compact" disabled={isLocationRefreshing} onClick={onRefreshLocation} type="button">
              현재 위치 새로고침
            </button>
          ) : null}
        </div>
      </section>

      <section className="panel-card">
        <div className="section-head">
          <div>
            <p className="section-caption">탐색 보드</p>
            <h3>한눈에 보는 위치</h3>
          </div>
          <span className="meta-pill">{filteredCafes.length}곳</span>
        </div>

        <div className="map-board">
          <div className="map-grid" />
          {mapLayout.userPin ? (
            <button className="map-pin user" style={{ left: `${mapLayout.userPin.left}%`, top: `${mapLayout.userPin.top}%` }} type="button">
              <span>내 위치</span>
            </button>
          ) : null}
          {mapLayout.cafePins.map(({ cafe, left, top }) => (
            <button className={selectedCafeId === cafe.id ? "map-pin active" : "map-pin"} key={cafe.id} onClick={() => onOpenCafe(cafe.id)} style={{ left: `${left}%`, top: `${top}%` }} type="button">
              <span>{cafe.name}</span>
            </button>
          ))}
        </div>
      </section>

      <section className="page-section">
        <div className="section-head">
          <div>
            <p className="section-caption">추천 카페</p>
            <h3>오늘의 셀렉션</h3>
          </div>
        </div>

        {filteredCafes.length === 0 ? (
          <EmptyBlock description="검색어나 필터를 조금 넓혀보면 다른 카페를 다시 볼 수 있어요." title="조건에 맞는 카페가 없어요." />
        ) : (
          <div className="card-list">
            {filteredCafes.map((cafe) => (
              <CafeListCard
                cafe={cafe}
                distanceText={getDistanceText(cafe)}
                isBookmarkBusy={isBookmarkBusy}
                isSaved={bookmarkIds.includes(cafe.id)}
                key={cafe.id}
                onBookmarkToggle={() => void onBookmarkToggle(cafe.id)}
                onOpen={() => onOpenCafe(cafe.id)}
              />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function CommunityPage(props: {
  categories: string[];
  communityCategory: string;
  communityCityDraft: string;
  communityComposerOpen: boolean;
  communityContentDraft: string;
  communityPosts: CommunityPost[];
  communitySearchText: string;
  communityTitleDraft: string;
  isCommunityBusy: boolean;
  onCategoryChange: (value: string) => void;
  onCityDraftChange: (value: string) => void;
  onComposerToggle: () => void;
  onContentDraftChange: (value: string) => void;
  onOpenPost: (postId: string) => void;
  onSearchChange: (value: string) => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onTitleDraftChange: (value: string) => void;
}) {
  const {
    categories,
    communityCategory,
    communityCityDraft,
    communityComposerOpen,
    communityContentDraft,
    communityPosts,
    communitySearchText,
    communityTitleDraft,
    isCommunityBusy,
    onCategoryChange,
    onCityDraftChange,
    onComposerToggle,
    onContentDraftChange,
    onOpenPost,
    onSearchChange,
    onSubmit,
    onTitleDraftChange
  } = props;

  return (
    <div className="page-stack">
      <section className="hero-panel compact">
        <p className="eyebrow">Brew Talk</p>
        <h2>카페 취향을 나누는 게시판</h2>
        <p className="hero-copy">추천, 질문, 동네 이야기를 모바일 웹 페이지에서 따로 읽고 쓸 수 있어요.</p>
      </section>

      <section className="panel-card">
        <label className="field-block">
          <span>게시글 검색</span>
          <input onChange={(event) => onSearchChange(event.target.value)} placeholder="제목, 내용, 작성자, 동네 검색" value={communitySearchText} />
        </label>
        <div className="chip-scroll">
          {categories.map((category) => (
            <button className={communityCategory === category ? "filter-chip active" : "filter-chip"} key={category} onClick={() => onCategoryChange(category)} type="button">
              {category}
            </button>
          ))}
        </div>
      </section>

      <section className="panel-card">
        <div className="section-head">
          <div>
            <p className="section-caption">새 글</p>
            <h3>커뮤니티에 남기기</h3>
          </div>
          <button className="secondary-cta compact" onClick={onComposerToggle} type="button">
            {communityComposerOpen ? "닫기" : "글쓰기"}
          </button>
        </div>

        {communityComposerOpen ? (
          <form className="stack-form" onSubmit={onSubmit}>
            <label>
              제목
              <input onChange={(event) => onTitleDraftChange(event.target.value)} placeholder="성수에서 오래 머물기 좋은 카페 추천해요" value={communityTitleDraft} />
            </label>
            <label>
              내용
              <textarea onChange={(event) => onContentDraftChange(event.target.value)} placeholder="카페 취향, 동선, 질문을 적어보세요." rows={4} value={communityContentDraft} />
            </label>
            <label>
              동네
              <input onChange={(event) => onCityDraftChange(event.target.value)} placeholder="성수" value={communityCityDraft} />
            </label>
            <button className="primary-cta" disabled={isCommunityBusy || !communityTitleDraft.trim() || !communityContentDraft.trim()} type="submit">
              {isCommunityBusy ? "올리는 중..." : "게시글 올리기"}
            </button>
          </form>
        ) : (
          <p className="helper-text">버튼을 누르면 모바일 폼이 열리고, 글을 올린 뒤 목록으로 바로 반영됩니다.</p>
        )}
      </section>

      {communityPosts.length === 0 ? (
        <EmptyBlock description="카테고리를 바꾸거나 검색어를 지우면 다른 게시글 흐름을 다시 볼 수 있어요." title="아직 맞는 게시글이 없어요." />
      ) : (
        <div className="card-list">
          {communityPosts.map((post) => (
            <button className="post-card" key={post.id} onClick={() => onOpenPost(post.id)} type="button">
              <div className="card-topline">
                <div className="chip-wrap">
                  <span className="city-badge">{post.city}</span>
                  <span className="ghost-chip">{post.category}</span>
                  <span className="ghost-chip">{post.source === "remote" ? "Live" : post.source === "localFallback" ? "로컬 저장" : "샘플"}</span>
                </div>
                <span className="meta-pill">{formatRelativeDate(post.createdAt)}</span>
              </div>
              <h4>{post.title}</h4>
              <p>{previewText(post.content, 110)}</p>
              <div className="meta-wrap">
                <span>{post.authorName}</span>
                <span>좋아요 {post.likeCount}</span>
                <span>댓글 {post.commentCount}</span>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function RankingPage(props: {
  currentLocation: BrowserLocation | null;
  onCityChange: (value: string) => void;
  onModeChange: (value: RankingMode) => void;
  onOpenCafe: (cafeId: string) => void;
  rankingCity: string;
  rankingCities: string[];
  rankingEntries: Array<{ rank: number; cafe: Cafe; highlight: string; detail: string }>;
  rankingMode: RankingMode;
  rankingNote: string;
}) {
  const {
    currentLocation,
    onCityChange,
    onModeChange,
    onOpenCafe,
    rankingCity,
    rankingCities,
    rankingEntries,
    rankingMode,
    rankingNote
  } = props;

  return (
    <div className="page-stack">
      <section className="hero-panel compact">
        <p className="eyebrow">Brew Rank</p>
        <h2>지금 주목할 카페 랭킹</h2>
        <p className="hero-copy">평점, 리뷰 수, 현재 위치를 기준으로 페이지 단위로 따로 볼 수 있어요.</p>
      </section>

      <section className="panel-card">
        <p className="section-caption">랭킹 모드</p>
        <div className="chip-scroll">
          {[
            { key: "overall", label: "종합" },
            { key: "rating", label: "평점" },
            { key: "reviews", label: "리뷰" },
            { key: "nearby", label: "내 주변" }
          ].map((mode) => (
            <button className={rankingMode === mode.key ? "filter-chip active" : "filter-chip"} key={mode.key} onClick={() => onModeChange(mode.key as RankingMode)} type="button">
              {mode.label}
            </button>
          ))}
        </div>

        <p className="section-caption">지역</p>
        <div className="chip-scroll">
          {rankingCities.map((city) => (
            <button className={rankingCity === city ? "filter-chip active" : "filter-chip"} key={city} onClick={() => onCityChange(city)} type="button">
              {city}
            </button>
          ))}
        </div>

        <p className="helper-text">
          {rankingMode === "nearby" && !currentLocation ? "현재 위치를 허용하면 내 주변 랭킹이 더 정확해져요." : rankingNote}
        </p>
      </section>

      {rankingEntries.length === 0 ? (
        <EmptyBlock description="지역 조건을 바꾸거나 카페 데이터가 더 쌓이면 랭킹이 채워집니다." title="랭킹에 표시할 카페가 아직 없어요." />
      ) : (
        <div className="card-list">
          {rankingEntries.map((entry) => (
            <button className="ranking-card" key={entry.cafe.id} onClick={() => onOpenCafe(entry.cafe.id)} type="button">
              <div className="ranking-badge">{entry.rank}</div>
              <div className="ranking-copy">
                <strong>{entry.cafe.name}</strong>
                <p>{entry.detail}</p>
                <span>{entry.highlight}</span>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function HomeBaristaPage(props: {
  beanNameDraft: string;
  brewMethodDraft: string;
  brewNoteDraft: string;
  composerOpen: boolean;
  isBusy: boolean;
  methodFilter: string;
  methods: string[];
  onBeanNameDraftChange: (value: string) => void;
  onBrewMethodDraftChange: (value: string) => void;
  onBrewNoteDraftChange: (value: string) => void;
  onComposerToggle: () => void;
  onMethodFilterChange: (value: string) => void;
  onOpenPost: (postId: string) => void;
  onRatioDraftChange: (value: string) => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onTastingDraftChange: (value: string) => void;
  onTitleDraftChange: (value: string) => void;
  posts: HomeBaristaPost[];
  ratioNoteDraft: string;
  tastingNoteDraft: string;
  titleDraft: string;
}) {
  const {
    beanNameDraft,
    brewMethodDraft,
    brewNoteDraft,
    composerOpen,
    isBusy,
    methodFilter,
    methods,
    onBeanNameDraftChange,
    onBrewMethodDraftChange,
    onBrewNoteDraftChange,
    onComposerToggle,
    onMethodFilterChange,
    onOpenPost,
    onRatioDraftChange,
    onSubmit,
    onTastingDraftChange,
    onTitleDraftChange,
    posts,
    ratioNoteDraft,
    tastingNoteDraft,
    titleDraft
  } = props;

  return (
    <div className="page-stack">
      <section className="hero-panel compact">
        <p className="eyebrow">Home Brew</p>
        <h2>집에서도 BrewSpot 취향을 이어가요</h2>
        <p className="hero-copy">레시피, 추출 메모, 원두 노트를 모바일 화면에서 따로 읽고 쓸 수 있어요.</p>
      </section>

      <section className="panel-card">
        <p className="section-caption">추출 방식 필터</p>
        <div className="chip-scroll">
          {methods.map((method) => (
            <button className={methodFilter === method ? "filter-chip active" : "filter-chip"} key={method} onClick={() => onMethodFilterChange(method)} type="button">
              {method}
            </button>
          ))}
        </div>
      </section>

      <section className="panel-card">
        <div className="section-head">
          <div>
            <p className="section-caption">새 레시피</p>
            <h3>홈바리스타에 공유하기</h3>
          </div>
          <button className="secondary-cta compact" onClick={onComposerToggle} type="button">
            {composerOpen ? "닫기" : "레시피 쓰기"}
          </button>
        </div>

        {composerOpen ? (
          <form className="stack-form" onSubmit={onSubmit}>
            <label>
              추출 방식
              <input onChange={(event) => onBrewMethodDraftChange(event.target.value)} placeholder="V60" value={brewMethodDraft} />
            </label>
            <label>
              제목
              <input onChange={(event) => onTitleDraftChange(event.target.value)} placeholder="성수 블렌드로 가볍게 내리는 아침 레시피" value={titleDraft} />
            </label>
            <label>
              원두 이름
              <input onChange={(event) => onBeanNameDraftChange(event.target.value)} placeholder="BrewSpot House Blend" value={beanNameDraft} />
            </label>
            <label>
              비율 메모
              <input onChange={(event) => onRatioDraftChange(event.target.value)} placeholder="15g : 240ml / 2분 30초" value={ratioNoteDraft} />
            </label>
            <label>
              테이스팅 노트
              <textarea onChange={(event) => onTastingDraftChange(event.target.value)} placeholder="첫 모금의 인상과 식으면서 올라오는 뉘앙스를 적어보세요." rows={3} value={tastingNoteDraft} />
            </label>
            <label>
              추출 메모
              <textarea onChange={(event) => onBrewNoteDraftChange(event.target.value)} placeholder="붓는 순서, 물줄기, 온도 등을 적어보세요." rows={4} value={brewNoteDraft} />
            </label>
            <button className="primary-cta" disabled={isBusy || !titleDraft.trim() || !beanNameDraft.trim() || !tastingNoteDraft.trim() || !brewNoteDraft.trim()} type="submit">
              {isBusy ? "공유 중..." : "레시피 공유하기"}
            </button>
          </form>
        ) : (
          <p className="helper-text">버튼을 누르면 모바일 폼이 열리고, 올린 레시피가 피드에 바로 반영됩니다.</p>
        )}
      </section>

      {posts.length === 0 ? (
        <EmptyBlock description="추출 방식을 바꾸거나 첫 레시피를 직접 올려보세요." title="아직 맞는 레시피가 없어요." />
      ) : (
        <div className="card-list">
          {posts.map((post) => (
            <button className="post-card" key={post.id} onClick={() => onOpenPost(post.id)} type="button">
              <div className="card-topline">
                <div className="chip-wrap">
                  <span className="city-badge">{post.brewMethod}</span>
                  <span className="ghost-chip">{post.source === "remote" ? "Live" : post.source === "localFallback" ? "로컬 저장" : "샘플"}</span>
                </div>
                <span className="meta-pill">{formatRelativeDate(post.createdAt)}</span>
              </div>
              <h4>{post.title}</h4>
              <p>{previewText(post.tastingNote, 96)}</p>
              <div className="meta-wrap">
                <span>{post.beanName}</span>
                <span>{post.ratioNote}</span>
                <span>{post.authorName}</span>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function CommunityPostDetailPage(props: { post: CommunityPost }) {
  const { post } = props;

  return (
    <div className="page-stack detail-page">
      <section className="detail-hero-panel">
        <div className="hero-row">
          <div>
            <p className="eyebrow">{post.city}</p>
            <h2>{post.title}</h2>
          </div>
          <span className="meta-pill">{formatRelativeDate(post.createdAt)}</span>
        </div>
        <p className="hero-copy">{post.category} 카테고리의 커뮤니티 글입니다.</p>
        <div className="meta-wrap">
          <span>{post.authorName}</span>
          <span>좋아요 {post.likeCount}</span>
          <span>댓글 {post.commentCount}</span>
        </div>
      </section>

      <section className="panel-card">
        <p className="section-caption">본문</p>
        <div className="detail-body-copy">
          {post.content.split("\n").map((line, index) => (
            <p key={`${post.id}-${index}`}>{line}</p>
          ))}
        </div>
      </section>
    </div>
  );
}

function HomeBaristaDetailPage(props: { post: HomeBaristaPost }) {
  const { post } = props;

  return (
    <div className="page-stack detail-page">
      <section className="detail-hero-panel">
        <div className="hero-row">
          <div>
            <p className="eyebrow">{post.brewMethod}</p>
            <h2>{post.title}</h2>
          </div>
          <span className="meta-pill">{formatRelativeDate(post.createdAt)}</span>
        </div>
        <p className="hero-copy">{post.authorName}님의 홈바리스타 메모입니다.</p>
        <div className="meta-wrap">
          <span>{post.beanName}</span>
          <span>{post.ratioNote}</span>
        </div>
      </section>

      <section className="detail-grid">
        <div className="panel-card soft">
          <span className="mini-label">원두</span>
          <strong>{post.beanName}</strong>
        </div>
        <div className="panel-card soft">
          <span className="mini-label">비율 메모</span>
          <strong>{post.ratioNote}</strong>
        </div>
      </section>

      <section className="panel-card">
        <p className="section-caption">테이스팅 노트</p>
        <div className="detail-body-copy">
          {post.tastingNote.split("\n").map((line, index) => (
            <p key={`${post.id}-tasting-${index}`}>{line}</p>
          ))}
        </div>
      </section>

      <section className="panel-card">
        <p className="section-caption">추출 메모</p>
        <div className="detail-body-copy">
          {post.brewNote.split("\n").map((line, index) => (
            <p key={`${post.id}-brew-${index}`}>{line}</p>
          ))}
        </div>
      </section>
    </div>
  );
}

function SavedPage(props: {
  currentUser: AppUser | null;
  getDistanceText: (cafe: Cafe) => string | null;
  isBookmarkBusy: boolean;
  onBookmarkToggle: (cafeId: string) => Promise<void>;
  onOpenCafe: (cafeId: string) => void;
  savedCafes: Cafe[];
}) {
  const { currentUser, getDistanceText, isBookmarkBusy, onBookmarkToggle, onOpenCafe, savedCafes } = props;

  return (
    <div className="page-stack">
      <section className="hero-panel compact">
        <p className="eyebrow">Saved</p>
        <h2>{currentUser?.nickname ?? "내"}가 저장한 카페</h2>
        <p className="hero-copy">마음에 든 카페를 다시 꺼내보는 별도 페이지입니다.</p>
      </section>

      {savedCafes.length === 0 ? (
        <EmptyBlock description="홈에서 마음에 드는 카페를 저장하면 이 페이지에 차곡차곡 모입니다." title="아직 저장한 카페가 없어요." />
      ) : (
        <div className="card-list">
          {savedCafes.map((cafe) => (
            <CafeListCard
              cafe={cafe}
              distanceText={getDistanceText(cafe)}
              isBookmarkBusy={isBookmarkBusy}
              isSaved
              key={cafe.id}
              onBookmarkToggle={() => void onBookmarkToggle(cafe.id)}
              onOpen={() => onOpenCafe(cafe.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function ProfilePage(props: {
  currentUser: AppUser | null;
  onSignOut: () => void;
  savedCafeCount: number;
  totalReviewCount: number;
}) {
  const { currentUser, onSignOut, savedCafeCount, totalReviewCount } = props;

  return (
    <div className="page-stack">
      <section className="profile-card">
        <div className="avatar-circle">{(currentUser?.nickname ?? "B").slice(0, 1)}</div>
        <strong>{currentUser?.nickname ?? "로그인 필요"}</strong>
        <p>{currentUser?.email ?? "이메일 로그인 후 계정 정보가 이곳에 표시됩니다."}</p>
      </section>

      <section className="stats-grid">
        <div className="stat-tile">
          <span>저장한 카페</span>
          <strong>{savedCafeCount}</strong>
        </div>
        <div className="stat-tile">
          <span>남긴 리뷰</span>
          <strong>{totalReviewCount}</strong>
        </div>
      </section>

      <section className="panel-card">
        <div className="section-head">
          <div>
            <p className="section-caption">안내 링크</p>
            <h3>운영 / 보안 정보</h3>
          </div>
        </div>
        <div className="resource-links">
          {publicInfoLinks.map((link) => (
            <a className="resource-link-card" href={link.href} key={link.href} rel="noreferrer" target="_blank">
              <span className="mini-label">{link.eyebrow}</span>
              <strong>{link.label}</strong>
              <p>{link.description}</p>
            </a>
          ))}
        </div>
      </section>

      <section className="panel-card">
        <div className="section-head">
          <div>
            <p className="section-caption">다음 작업</p>
            <h3>웹 확장 로드맵</h3>
          </div>
        </div>
        <ul className="simple-list">
          <li>커뮤니티 상세 읽기 페이지</li>
          <li>랭킹 세부 정렬 고도화</li>
          <li>홈바리스타 상세 읽기와 저장 기능</li>
        </ul>
      </section>

      <button className="secondary-cta full" onClick={onSignOut} type="button">
        로그아웃
      </button>
    </div>
  );
}

function CafeDetailPage(props: {
  cafe: Cafe;
  currentUser: AppUser | null;
  distanceText: string | null;
  isBookmarkBusy: boolean;
  isReviewBusy: boolean;
  isSaved: boolean;
  onBookmarkToggle: () => void;
  onRecommendedMenuChange: (value: string) => void;
  onRatingChange: (value: number) => void;
  onReviewSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onReviewTextChange: (value: string) => void;
  ratingDraft: number;
  recommendedMenuDraft: string;
  reviewDraft: string;
  reviews: CafeReview[];
}) {
  const {
    cafe,
    currentUser,
    distanceText,
    isBookmarkBusy,
    isReviewBusy,
    isSaved,
    onBookmarkToggle,
    onRecommendedMenuChange,
    onRatingChange,
    onReviewSubmit,
    onReviewTextChange,
    ratingDraft,
    recommendedMenuDraft,
    reviewDraft,
    reviews
  } = props;

  return (
    <div className="page-stack detail-page">
      <section className="detail-hero-panel">
        <div className="hero-row">
          <div>
            <p className="eyebrow">{cafe.city}</p>
            <h2>{cafe.name}</h2>
          </div>
          <span className="meta-pill">★ {cafe.rating.toFixed(1)}</span>
        </div>
        <p className="hero-copy">{cafe.shortDescription}</p>
        <div className="meta-wrap">
          <span>{cafe.category}</span>
          <span>{cafe.openHours}</span>
          {distanceText ? <span>{distanceText}</span> : null}
        </div>
        <button className={isSaved ? "primary-cta compact olive" : "secondary-cta compact"} disabled={isBookmarkBusy} onClick={onBookmarkToggle} type="button">
          {isSaved ? "저장됨" : "저장하기"}
        </button>
      </section>

      <section className="detail-grid">
        <div className="panel-card soft">
          <span className="mini-label">대표 메뉴</span>
          <strong>{cafe.signatureMenu}</strong>
        </div>
        <div className="panel-card soft">
          <span className="mini-label">예상 가격대</span>
          <strong>{cafe.priceNote}</strong>
        </div>
      </section>

      <section className="panel-card">
        <p className="section-caption">분위기</p>
        <div className="chip-wrap">
          {cafe.vibeTags.map((tag) => (
            <span className="ghost-chip" key={tag}>
              {tag}
            </span>
          ))}
        </div>
      </section>

      <section className="panel-card">
        <p className="section-caption">방문 포인트</p>
        <ul className="simple-list">
          {cafe.features.map((feature) => (
            <li key={feature}>{feature}</li>
          ))}
        </ul>
      </section>

      <section className="panel-card">
        <div className="section-head">
          <div>
            <p className="section-caption">리뷰 작성</p>
            <h3>{currentUser ? `${currentUser.nickname}님의 기록` : "로그인 후 리뷰 작성"}</h3>
          </div>
        </div>

        <form className="stack-form" onSubmit={onReviewSubmit}>
          <div className="rating-row">
            {[5, 4, 3, 2, 1].map((value) => (
              <button className={ratingDraft === value ? "score-pill active" : "score-pill"} key={value} onClick={() => onRatingChange(value)} type="button">
                ★ {value}
              </button>
            ))}
          </div>
          <label>
            추천 메뉴
            <input onChange={(event) => onRecommendedMenuChange(event.target.value)} placeholder="플랫화이트, 스콘 플레이트" value={recommendedMenuDraft} />
          </label>
          <label>
            방문 메모
            <textarea onChange={(event) => onReviewTextChange(event.target.value)} placeholder="커피 밸런스, 좌석 분위기, 다시 갈지 등을 적어보세요." rows={4} value={reviewDraft} />
          </label>
          <button className="primary-cta" disabled={isReviewBusy || !recommendedMenuDraft.trim() || !reviewDraft.trim()} type="submit">
            {isReviewBusy ? "저장 중..." : "리뷰 저장"}
          </button>
        </form>
      </section>

      <section className="page-section">
        <div className="section-head">
          <div>
            <p className="section-caption">리뷰</p>
            <h3>{reviews.length}개</h3>
          </div>
        </div>

        {reviews.length === 0 ? (
          <EmptyBlock description="첫 리뷰를 남겨서 이 카페의 분위기를 기록해 보세요." title="아직 리뷰가 없어요." />
        ) : (
          <div className="card-list">
            {reviews.map((review) => (
              <article className="review-card" key={review.id}>
                <div className="review-head">
                  <div>
                    <strong>{review.authorNickname}</strong>
                    <p>{formatRelativeDate(review.createdAt)}</p>
                  </div>
                  <span className="meta-pill">★ {review.overallRating}</span>
                </div>
                <h4>{review.recommendedMenuName}</h4>
                <p>{review.content}</p>
              </article>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function CafeListCard(props: {
  cafe: Cafe;
  distanceText: string | null;
  isBookmarkBusy: boolean;
  isSaved: boolean;
  onBookmarkToggle: () => void;
  onOpen: () => void;
}) {
  const { cafe, distanceText, isBookmarkBusy, isSaved, onBookmarkToggle, onOpen } = props;

  return (
    <article className="cafe-card">
      <button className="cafe-card-body" onClick={onOpen} type="button">
        <div className="card-topline">
          <span className="city-badge">{cafe.city}</span>
          <span className="meta-pill">★ {cafe.rating.toFixed(1)}</span>
        </div>
        <h4>{cafe.name}</h4>
        <p>{cafe.shortDescription}</p>
        <div className="meta-wrap">
          <span>{cafe.category}</span>
          <span>{cafe.signatureMenu}</span>
          {distanceText ? <span>{distanceText}</span> : null}
        </div>
      </button>
      <div className="card-bottomline">
        <div className="chip-wrap">
          {cafe.vibeTags.slice(0, 2).map((tag) => (
            <span className="ghost-chip" key={tag}>
              {tag}
            </span>
          ))}
        </div>
        <button className="bookmark-button" disabled={isBookmarkBusy} onClick={onBookmarkToggle} type="button">
          {isSaved ? "저장됨" : "저장"}
        </button>
      </div>
    </article>
  );
}

function TopBar(props: {
  onBack?: () => void;
  route: AppRoute;
  selectedCafeName: string | null;
  selectedCommunityTitle: string | null;
  selectedHomeBaristaTitle: string | null;
}) {
  const { onBack, route, selectedCafeName, selectedCommunityTitle, selectedHomeBaristaTitle } = props;

  let title = "BrewSpot";

  if (route.name === "community") {
    title = "커뮤니티";
  } else if (route.name === "communityPost") {
    title = selectedCommunityTitle ?? "게시글";
  } else if (route.name === "ranking") {
    title = "랭킹";
  } else if (route.name === "homebarista") {
    title = "홈바리스타";
  } else if (route.name === "homebaristaPost") {
    title = selectedHomeBaristaTitle ?? "레시피";
  } else if (route.name === "saved") {
    title = "저장한 카페";
  } else if (route.name === "profile") {
    title = "마이페이지";
  } else if (route.name === "cafe") {
    title = selectedCafeName ?? "카페 상세";
  }

  return (
    <header className="top-bar">
      <div className="top-bar-inner">
        {route.name === "cafe" || route.name === "communityPost" || route.name === "homebaristaPost" ? (
          <button className="icon-button" onClick={onBack} type="button">
            이전
          </button>
        ) : (
          <span className="brand-mark">B</span>
        )}
        <strong>{title}</strong>
        <span className="top-bar-spacer" />
      </div>
    </header>
  );
}

function BottomActionStack(props: {
  currentRoute: AppRoute;
  onNavigate: (route: AppRoute) => void;
}) {
  const { currentRoute, onNavigate } = props;
  const isLoungeRoute =
    currentRoute.name === "community" ||
    currentRoute.name === "communityPost" ||
    currentRoute.name === "ranking" ||
    currentRoute.name === "homebarista" ||
    currentRoute.name === "homebaristaPost";

  return (
    <div className="bottom-action-stack">
      {isLoungeRoute ? (
        <section className="lounge-tabs lounge-tabs-fixed">
          <button className={currentRoute.name === "community" || currentRoute.name === "communityPost" ? "active" : ""} onClick={() => onNavigate({ name: "community" })} type="button">
            커뮤니티
          </button>
          <button className={currentRoute.name === "ranking" ? "active" : ""} onClick={() => onNavigate({ name: "ranking" })} type="button">
            랭킹
          </button>
          <button className={currentRoute.name === "homebarista" || currentRoute.name === "homebaristaPost" ? "active" : ""} onClick={() => onNavigate({ name: "homebarista" })} type="button">
            홈바리스타
          </button>
        </section>
      ) : null}
      <nav className="bottom-nav">
        <button className={currentRoute.name === "home" || currentRoute.name === "cafe" ? "active" : ""} onClick={() => onNavigate({ name: "home" })} type="button">
          홈
        </button>
        <button className={isLoungeRoute ? "active" : ""} onClick={() => onNavigate({ name: "community" })} type="button">
          라운지
        </button>
        <button className={currentRoute.name === "saved" ? "active" : ""} onClick={() => onNavigate({ name: "saved" })} type="button">
          저장
        </button>
        <button className={currentRoute.name === "profile" ? "active" : ""} onClick={() => onNavigate({ name: "profile" })} type="button">
          마이
        </button>
      </nav>
    </div>
  );
}

function StatusBanner(props: { message: string }) {
  return (
    <section className="status-banner">
      <span className="status-dot" />
      <p>{props.message}</p>
    </section>
  );
}

function EmptyBlock(props: { description: string; title: string }) {
  return (
    <div className="empty-block">
      <strong>{props.title}</strong>
      <p>{props.description}</p>
    </div>
  );
}

function getErrorMessage(error: unknown, fallback: string) {
  if (error instanceof Error && error.message) {
    return error.message;
  }

  return fallback;
}
