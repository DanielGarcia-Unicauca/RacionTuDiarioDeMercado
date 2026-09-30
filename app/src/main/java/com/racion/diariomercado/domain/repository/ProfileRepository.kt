package com.racion.diariomercado.domain.repository

import com.racion.diariomercado.core.AppResult
import com.racion.diariomercado.domain.model.UserProfile
import kotlinx.coroutines.flow.Flow

/**
 * The user record and the onboarding flag.
 *
 * Contract:
 * - [observeProfile] emits `null` for a user who has not filled the profile in yet. `null` is a
 *   real state (fresh install), not an error.
 * - [completeOnboarding] is separate from [saveProfile] on purpose: onboarding is consent, not
 *   data, and it must be set independently so a failed profile write can never un-consent the
 *   user.
 */
interface ProfileRepository {

    /** Emits the stored profile, or `null` while it has never been written. */
    fun observeProfile(): Flow<UserProfile?>

    suspend fun saveProfile(profile: UserProfile): AppResult<Unit>

    /**
     * Marks the onboarding consent as accepted.
     *
     * This replaces the `SharedPreferences` boolean that `MainActivity` reads today. See the
     * TODO in `MainActivity`.
     */
    suspend fun completeOnboarding(): AppResult<Unit>

    /**
     * Emits whether onboarding was already completed. The first emission decides the start route,
     * so it must arrive from cache rather than after a network round trip.
     */
    fun observeOnboardingCompleted(): Flow<Boolean>
}
