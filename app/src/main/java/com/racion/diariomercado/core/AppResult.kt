package com.racion.diariomercado.core

/**
 * Result of any operation that can fail in a way the UI must distinguish.
 *
 * The sealed hierarchy exists so the UI can branch on *why* something failed
 * ([AppError.Network] -> "sin conexión", [AppError.RateLimited] -> "esperá un momento")
 * instead of parsing exception messages.
 *
 * [Failure] is [AppResult] of [Nothing], so `when` exhaustiveness works on the `Success` branch.
 * The repository methods are `suspend`, so the example has to be shown from inside a coroutine —
 * a `when` in a plain non-suspend function cannot call them at all:
 *
 * ```kotlin
 * suspend fun loadProduct(repo: FoodCatalogRepository, code: String) {
 *     when (val r = repo.productByBarcode(code)) {
 *         is AppResult.Success -> render(r.data)
 *         is AppResult.Failure -> render(r.error)
 *     }
 * }
 * ```
 *
 * If you need the same branching from a non-`suspend` function, cross the boundary with
 * `runCatching` first — it catches the `Exception` that a real repository returns in
 * [Failure], so you still land on the same two branches:
 *
 * ```kotlin
 * fun loadProductBlocking(repo: FoodCatalogRepository, code: String) {
 *     val r = runBlocking { runCatching { repo.productByBarcode(code) }.getOrNull() }
 *     when (r) {
 *         is AppResult.Success -> render(r.data)
 *         is AppResult.Failure -> render(r.error)
 *         null -> render(AppError.Unknown(cause = null))
 *     }
 * }
 * ```
 */
sealed interface AppResult<out T> {
    data class Success<T>(val data: T) : AppResult<T>
    data class Failure(val error: AppError) : AppResult<Nothing>
}

/**
 * Failure taxonomy. Every data-layer implementation must map its own exceptions into one of
 * these — raw `IOException` must never escape a repository.
 */
sealed interface AppError {
    /** No connectivity, DNS failure, or timeout. Retryable. */
    data object Network : AppError

    /** The resource does not exist. Note: Open Food Facts signals this with HTTP 200 + `status: 0`. */
    data object NotFound : AppError

    /** HTTP 429 or the Open Food Facts 503 rate-limit response. Retryable after a backoff. */
    data object RateLimited : AppError

    /** Any other non-success HTTP response. */
    data class Server(val code: Int?, val message: String?) : AppError

    /** Unmapped failure. [cause] is kept for logging only, never shown to the user verbatim. */
    data class Unknown(val cause: Throwable?) : AppError
}
