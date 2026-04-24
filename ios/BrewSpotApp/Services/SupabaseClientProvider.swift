import Foundation
import Supabase

enum SupabaseClientProvider {
    static let client = SupabaseClient(
        supabaseURL: AppConfig.supabaseURL,
        supabaseKey: AppConfig.supabasePublishableKey,
        options: SupabaseClientOptions(
            auth: .init(
                redirectToURL: AppConfig.authRedirectURL
            )
        )
    )
}
