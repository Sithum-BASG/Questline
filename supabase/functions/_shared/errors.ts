/** Typed failure returned to the app as `{ code, message }`. */
export class AppError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly status = 400,
  ) {
    super(message);
  }
}

export function unauthorized(message = "Sign in required"): AppError {
  return new AppError("unauthorized", message, 401);
}

export function notFound(message = "Not found"): AppError {
  return new AppError("not_found", message, 404);
}

export function invalidArgument(message: string): AppError {
  return new AppError("invalid_argument", message, 400);
}
