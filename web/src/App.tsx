import { FormEvent, startTransition, useDeferredValue, useEffect, useState } from "react";

import { demoCafes, demoReviews, demoUser } from "./lib/demoData";
import {
  addBookmark,
  addReview,
  fetchBookmarks,
  fetchCafes,
  fetchCurrentUserProfile,
  fetchReviews,
  hasSupabaseEnv,
  removeBookmark,
  signInWithEmail,
  signOutCurrentUser,
  signUpWithEmail
} from "./lib/supabase";
import type { AppUser, AuthIntent, Cafe, CafeReview } from "./types";

const demoBookmarksStorageKey = "brewspot-web-demo-bookmarks";
const demoReviewsStorageKey = "brewspot-web-demo-reviews";

type LocationAccessState = "prompt" | "granted" | "denied" | "unsupported";
type BrowserLocation = {
  latitude: number;
  longitude: number;
  accuracy: number;
  timestamp: number;
};

type AppRoute =
  | { name: "login" }
  | { name: "home" }
  | { name: "saved" }
  | { name: "profile" }
  | { name: "cafe"; cafeId: string };

function parseHash(hash: string): AppRoute {
  const normalized = hash.replace(/^#/, "") || "/login";
  const parts = normalized.split("/").filter(Boolean);

  if (parts[0] === "cafes" && parts[1]) {
    return { name: "cafe", cafeId: decodeURIComponent(parts[1]) };
  }

  switch (parts[0]) {
    case "home":
      return { name: "home" };
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

function loadStoredDemoBookmarks() {
  const saved = window.localStorage.getItem(demoBookmarksStorageKey);

  if (!saved) {
    return [demoCafes[0]?.id ?? "", demoCafes[2]?.id ?? ""].filter(Boolean);
  }

  try {
    const parsed = JSON.parse(saved);
    return Array.isArray(parsed) ? parsed.filter((value) => typeof value === "string") : [];
  } catch {
    return [];
  }
}

function loadStoredDemoReviews() {
  const saved = window.localStorage.getItem(demoReviewsStorageKey);

  if (!saved) {
    return demoReviews;
  }

  try {
    const parsed = JSON.parse(saved);
    return Array.isArray(parsed) ? (parsed as CafeReview[]) : demoReviews;
  } catch {
    return demoReviews;
  }
}

function persistDemoBookmarks(bookmarkIds: string[]) {
  window.localStorage.setItem(demoBookmarksStorageKey, JSON.stringify(bookmarkIds));
}

function persistDemoReviews(reviews: CafeReview[]) {
  window.localStorage.setItem(demoReviewsStorageKey, JSON.stringify(reviews));
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
  const [currentUser, setCurrentUser] = useState<AppUser | null>(null);
  const [statusMessage, setStatusMessage] = useState(
    "모바일 웹 버전으로 구조를 다시 정리하고 있어요."
  );
  const [isBooting, setIsBooting] = useState(true);
  const [isAuthBusy, setIsAuthBusy] = useState(false);
  const [isBookmarkBusy, setIsBookmarkBusy] = useState(false);
  const [isReviewBusy, setIsReviewBusy] = useState(false);
  const [reviewDraft, setReviewDraft] = useState("");
  const [recommendedMenuDraft, setRecommendedMenuDraft] = useState("");
  const [ratingDraft, setRatingDraft] = useState(5);
  const [locationAccessState, setLocationAccessState] = useState<LocationAccessState>("prompt");
  const [currentLocation, setCurrentLocation] = useState<BrowserLocation | null>(null);
  const [locationRequestCount, setLocationRequestCount] = useState(0);
  const [isLocationRefreshing, setIsLocationRefreshing] = useState(false);
  const [lastLocationRefreshAt, setLastLocationRefreshAt] = useState<number | null>(null);
  const [locationErrorMessage, setLocationErrorMessage] = useState<string | null>(null);

  const deferredSearchText = useDeferredValue(searchText.trim().toLowerCase());
  const isDemoMode = !hasSupabaseEnv;

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }

    const handleHashChange = () => {
      setRoute(parseHash(window.location.hash));
    };

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
        const demoReviewList = loadStoredDemoReviews();
        const groupedReviews = demoReviewList.reduce<Record<string, CafeReview[]>>((result, review) => {
          result[review.cafeId] = [...(result[review.cafeId] ?? []), review];
          return result;
        }, {});

        setCafes(demoCafes);
        setBookmarkIds(loadStoredDemoBookmarks());
        setReviewsByCafe(groupedReviews);
        setSelectedCafeId(demoCafes[0]?.id ?? "");
        setStatusMessage("데모 데이터로 모바일 웹앱 구조를 확인할 수 있어요.");
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
        setStatusMessage("Supabase와 연결되었어요. 모바일 웹 흐름으로 이어서 볼 수 있습니다.");
      } catch (error) {
        setStatusMessage(getErrorMessage(error, "Supabase 연결에 실패해서 현재 화면을 불러오지 못했어요."));
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

  const categories = ["전체", ...Array.from(new Set(cafes.map((cafe) => cafe.category)))];
  const cities = ["전체", ...Array.from(new Set(cafes.map((cafe) => cafe.city)))];

  const visibleCafes = cafes.filter((cafe) => {
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
    const matchesSaved = route.name !== "saved" || bookmarkIds.includes(cafe.id);

    return matchesSearch && matchesCategory && matchesCity && matchesSaved;
  });

  const selectedCafe =
    cafes.find((cafe) => cafe.id === selectedCafeId) ??
    (route.name === "cafe" ? cafes.find((cafe) => cafe.id === route.cafeId) ?? null : null);

  const selectedCafeReviews = selectedCafe ? reviewsByCafe[selectedCafe.id] ?? [] : [];
  const savedCafes = cafes.filter((cafe) => bookmarkIds.includes(cafe.id));
  const myReviewCount = Object.values(reviewsByCafe)
    .flat()
    .filter((review) => review.userId === currentUser?.id).length;
  const nearestVisibleCafe = findNearestCafe(currentLocation, visibleCafes);
  const currentPlaceSummary = currentLocation
    ? nearestVisibleCafe
      ? `${nearestVisibleCafe.city} 근처`
      : `${currentLocation.latitude.toFixed(3)}, ${currentLocation.longitude.toFixed(3)}`
    : null;
  const formattedRefreshTime = formatRefreshTime(lastLocationRefreshAt);
  const locationRefreshText = isLocationRefreshing
    ? "현재 위치를 다시 확인하고 있어요."
    : locationErrorMessage
      ? locationErrorMessage
      : formattedRefreshTime
        ? `최근 확인: ${formattedRefreshTime}`
        : null;

  useEffect(() => {
    if (route.name === "cafe") {
      setSelectedCafeId(route.cafeId);
    }
  }, [route]);

  useEffect(() => {
    if (route.name === "cafe" && !selectedCafe && cafes.length > 0) {
      navigate({ name: "home" }, true);
    }
  }, [cafes.length, route, selectedCafe]);

  useEffect(() => {
    if (locationAccessState === "granted" && !currentLocation && cafes.length > 0) {
      requestCurrentLocation({ incrementCount: false, announce: false });
    }
  }, [cafes.length, currentLocation, locationAccessState]);

  function getDistanceText(cafe: Cafe) {
    if (!currentLocation) {
      return null;
    }

    return formatDistance(
      calculateDistanceInMeters(
        currentLocation.latitude,
        currentLocation.longitude,
        cafe.latitude,
        cafe.longitude
      )
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

  function getLocationButtonLabel() {
    switch (locationAccessState) {
      case "granted":
        return "내 위치 사용 중";
      case "denied":
        return "브라우저 설정 확인";
      case "unsupported":
        return "위치 미지원";
      case "prompt":
      default:
        return "위치 권한 요청";
    }
  }

  function openCafe(cafeId: string) {
    setSelectedCafeId(cafeId);
    navigate({ name: "cafe", cafeId });
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
        setStatusMessage("데모 계정으로 로그인했어요. 모바일 흐름을 바로 확인할 수 있습니다.");
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
        setStatusMessage("데모 로그아웃 상태예요. 다시 로그인하면 이어서 확인할 수 있어요.");
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
        persistDemoBookmarks(next);
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

        const nextGroup = [nextReview, ...(reviewsByCafe[selectedCafe.id] ?? [])];
        const nextReviewMap = {
          ...reviewsByCafe,
          [selectedCafe.id]: nextGroup
        };

        setReviewsByCafe(nextReviewMap);
        persistDemoReviews(Object.values(nextReviewMap).flat());
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

  const isAuthenticated = Boolean(currentUser);
  const mapLayout = buildMapLayout(visibleCafes, currentLocation);

  return (
    <div className="mobile-web">
      <div className="device-frame">
        {route.name === "login" ? (
          <LoginPage
            authIntent={authIntent}
            email={email}
            isAuthBusy={isAuthBusy}
            isDemoMode={isDemoMode}
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
              onBack={route.name === "cafe" ? () => navigate({ name: "home" }) : undefined}
              route={route}
              selectedCafeName={selectedCafe?.name ?? null}
            />
            <div className="screen-content">
              <StatusBanner message={statusMessage} />

              {route.name === "home" ? (
                <HomePage
                  bookmarkIds={bookmarkIds}
                  currentLocation={currentLocation}
                  currentPlaceSummary={currentPlaceSummary}
                  currentUser={currentUser}
                  getDistanceText={getDistanceText}
                  handlePrimaryLocationAction={handlePrimaryLocationAction}
                  isBookmarkBusy={isBookmarkBusy}
                  isDemoMode={isDemoMode}
                  isLocationRefreshing={isLocationRefreshing}
                  locationAccessState={locationAccessState}
                  locationRefreshText={locationRefreshText}
                  locationRequestCount={locationRequestCount}
                  mapLayout={mapLayout}
                  nearestVisibleCafe={nearestVisibleCafe}
                  onBookmarkToggle={handleBookmarkToggle}
                  onCategoryChange={setSelectedCategory}
                  onCityChange={setSelectedCity}
                  onOpenCafe={openCafe}
                  onRefreshLocation={() =>
                    requestCurrentLocation({
                      incrementCount: false,
                      announce: true
                    })
                  }
                  onSearchChange={setSearchText}
                  searchText={searchText}
                  selectedCategory={selectedCategory}
                  selectedCity={selectedCity}
                  selectedCafeId={selectedCafeId}
                  visibleCafes={visibleCafes}
                  categories={categories}
                  cities={cities}
                />
              ) : null}

              {route.name === "saved" ? (
                <SavedPage
                  bookmarkIds={bookmarkIds}
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
                  isDemoMode={isDemoMode}
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
                  onReviewSubmit={handleReviewSubmit}
                  onReviewTextChange={setReviewDraft}
                  onRatingChange={setRatingDraft}
                  ratingDraft={ratingDraft}
                  recommendedMenuDraft={recommendedMenuDraft}
                  reviewDraft={reviewDraft}
                  reviews={selectedCafeReviews}
                />
              ) : null}
            </div>
            {isAuthenticated ? (
              <BottomNavigation
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
  isDemoMode: boolean;
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
    isDemoMode,
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
        <h1>내 취향에 맞는 카페를 휴대폰에서 바로 찾아보세요.</h1>
        <p>
          로그인 후 홈에서 카페를 탐색하고, 저장하고, 리뷰를 남기는 모바일 웹앱 구조로
          다시 정리했습니다.
        </p>
      </div>

      <div className="login-card">
        <div className="segmented-control">
          <button
            className={authIntent === "signin" ? "active" : ""}
            onClick={() => onAuthIntentChange("signin")}
            type="button"
          >
            로그인
          </button>
          <button
            className={authIntent === "signup" ? "active" : ""}
            onClick={() => onAuthIntentChange("signup")}
            type="button"
          >
            회원가입
          </button>
        </div>

        <form className="stack-form" onSubmit={onSubmit}>
          {authIntent === "signup" ? (
            <label>
              닉네임
              <input
                onChange={(event) => setNickname(event.target.value)}
                placeholder="brew_jane"
                value={nickname}
              />
            </label>
          ) : null}
          <label>
            이메일
            <input
              onChange={(event) => setEmail(event.target.value)}
              placeholder="user@example.com"
              type="email"
              value={email}
            />
          </label>
          <label>
            비밀번호
            <input
              onChange={(event) => setPassword(event.target.value)}
              placeholder="8자 이상"
              type="password"
              value={password}
            />
          </label>
          <button className="primary-cta" disabled={isAuthBusy} type="submit">
            {isAuthBusy
              ? "처리 중..."
              : authIntent === "signin"
                ? isDemoMode
                  ? "데모로 시작"
                  : "이메일 로그인"
                : "이메일 회원가입"}
          </button>
        </form>

        <div className="info-panel">
          <span className={`mode-badge ${isDemoMode ? "demo" : "live"}`}>
            {isDemoMode ? "Demo Data" : "Supabase Live"}
          </span>
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
  getDistanceText: (cafe: Cafe) => string | null;
  handlePrimaryLocationAction: () => void;
  isBookmarkBusy: boolean;
  isDemoMode: boolean;
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
  visibleCafes: Cafe[];
}) {
  const {
    bookmarkIds,
    categories,
    cities,
    currentLocation,
    currentPlaceSummary,
    currentUser,
    getDistanceText,
    handlePrimaryLocationAction,
    isBookmarkBusy,
    isDemoMode,
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
    selectedCafeId,
    visibleCafes
  } = props;

  return (
    <div className="page-stack">
      <section className="hero-panel">
        <div className="hero-row">
          <div>
            <p className="eyebrow">Home</p>
            <h2>{currentUser ? `${currentUser.nickname}님, 오늘은 어디로 갈까요?` : "오늘의 브루 스팟"}</h2>
          </div>
          <span className={`mode-badge ${isDemoMode ? "demo" : "live"}`}>
            {isDemoMode ? "Demo" : "Live"}
          </span>
        </div>
        <p className="hero-copy">
          로그인 후 바로 홈으로 들어와, 검색과 탭 이동으로 원하는 카페를 찾는 모바일 흐름입니다.
        </p>
        {nearestVisibleCafe ? (
          <div className="quick-stat-card">
            <span className="mini-label">가장 가까운 카페</span>
            <strong>{nearestVisibleCafe.name}</strong>
            <p>{getDistanceText(nearestVisibleCafe)} · 지금 보이는 카페 중 가장 가깝습니다.</p>
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
              <button
                className={selectedCategory === category ? "filter-chip active" : "filter-chip"}
                key={category}
                onClick={() => onCategoryChange(category)}
                type="button"
              >
                {category}
              </button>
            ))}
          </div>
        </div>

        <div className="chip-section">
          <p className="section-caption">지역</p>
          <div className="chip-scroll">
            {cities.map((city) => (
              <button
                className={selectedCity === city ? "filter-chip active" : "filter-chip"}
                key={city}
                onClick={() => onCityChange(city)}
                type="button"
              >
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
          <span className="meta-pill">{visibleCafes.length}곳</span>
        </div>

        <div className="map-board">
          <div className="map-grid" />
          {mapLayout.userPin ? (
            <button
              className="map-pin user"
              style={{ left: `${mapLayout.userPin.left}%`, top: `${mapLayout.userPin.top}%` }}
              type="button"
            >
              <span>내 위치</span>
            </button>
          ) : null}
          {mapLayout.cafePins.map(({ cafe, left, top }) => (
            <button
              className={selectedCafeId === cafe.id ? "map-pin active" : "map-pin"}
              key={cafe.id}
              onClick={() => onOpenCafe(cafe.id)}
              style={{ left: `${left}%`, top: `${top}%` }}
              type="button"
            >
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

        {visibleCafes.length === 0 ? (
          <EmptyBlock
            description="검색어나 필터를 조금 넓혀보면 다른 카페를 다시 볼 수 있어요."
            title="조건에 맞는 카페가 없어요."
          />
        ) : (
          <div className="card-list">
            {visibleCafes.map((cafe) => (
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

function SavedPage(props: {
  bookmarkIds: string[];
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
        <p className="hero-copy">홈에서 저장한 카페를 모아서 다시 꺼내보는 페이지입니다.</p>
      </section>

      {savedCafes.length === 0 ? (
        <EmptyBlock
          description="홈에서 마음에 드는 카페를 저장하면 이 페이지에 차곡차곡 모입니다."
          title="아직 저장한 카페가 없어요."
        />
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
  isDemoMode: boolean;
  onSignOut: () => void;
  savedCafeCount: number;
  totalReviewCount: number;
}) {
  const { currentUser, isDemoMode, onSignOut, savedCafeCount, totalReviewCount } = props;

  return (
    <div className="page-stack">
      <section className="profile-card">
        <div className="avatar-circle">{(currentUser?.nickname ?? "B").slice(0, 1)}</div>
        <strong>{currentUser?.nickname ?? "로그인 필요"}</strong>
        <p>{currentUser?.email ?? "이메일 로그인 후 계정 정보가 이곳에 표시됩니다."}</p>
        <span className={`mode-badge ${isDemoMode ? "demo" : "live"}`}>
          {isDemoMode ? "Demo Account" : "Linked to Supabase"}
        </span>
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
            <p className="section-caption">다음 작업</p>
            <h3>웹 확장 로드맵</h3>
          </div>
        </div>
        <ul className="simple-list">
          <li>커뮤니티 게시판 웹 전환</li>
          <li>카페 랭킹 페이지 추가</li>
          <li>홈바리스타 피드 모바일 화면 구성</li>
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
              <button
                className={ratingDraft === value ? "score-pill active" : "score-pill"}
                key={value}
                onClick={() => onRatingChange(value)}
                type="button"
              >
                ★ {value}
              </button>
            ))}
          </div>
          <label>
            추천 메뉴
            <input
              onChange={(event) => onRecommendedMenuChange(event.target.value)}
              placeholder="플랫화이트, 스콘 플레이트"
              value={recommendedMenuDraft}
            />
          </label>
          <label>
            방문 메모
            <textarea
              onChange={(event) => onReviewTextChange(event.target.value)}
              placeholder="커피 밸런스, 좌석 분위기, 다시 갈지 등을 적어보세요."
              rows={4}
              value={reviewDraft}
            />
          </label>
          <button
            className="primary-cta"
            disabled={isReviewBusy || !recommendedMenuDraft.trim() || !reviewDraft.trim()}
            type="submit"
          >
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
}) {
  const { onBack, route, selectedCafeName } = props;

  let title = "BrewSpot";

  if (route.name === "saved") {
    title = "저장한 카페";
  } else if (route.name === "profile") {
    title = "마이페이지";
  } else if (route.name === "cafe") {
    title = selectedCafeName ?? "카페 상세";
  }

  return (
    <header className="top-bar">
      <div className="top-bar-inner">
        {route.name === "cafe" ? (
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

function BottomNavigation(props: {
  currentRoute: AppRoute;
  onNavigate: (route: AppRoute) => void;
}) {
  const { currentRoute, onNavigate } = props;

  return (
    <nav className="bottom-nav">
      <button
        className={currentRoute.name === "home" || currentRoute.name === "cafe" ? "active" : ""}
        onClick={() => onNavigate({ name: "home" })}
        type="button"
      >
        홈
      </button>
      <button
        className={currentRoute.name === "saved" ? "active" : ""}
        onClick={() => onNavigate({ name: "saved" })}
        type="button"
      >
        저장
      </button>
      <button
        className={currentRoute.name === "profile" ? "active" : ""}
        onClick={() => onNavigate({ name: "profile" })}
        type="button"
      >
        마이
      </button>
    </nav>
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
