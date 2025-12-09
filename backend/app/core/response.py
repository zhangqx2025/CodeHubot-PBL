from typing import Any, Optional

from fastapi.responses import JSONResponse


def success_response(
    data: Optional[Any] = None,
    message: str = "success",
    code: int = 0,
    status_code: int = 200,
) -> JSONResponse:
    """Standard success response wrapper."""
    return JSONResponse(
        status_code=status_code,
        content={"success": True, "code": code, "message": message, "data": data},
    )


def error_response(
    message: str = "error",
    code: int = 400,
    status_code: int = 400,
    data: Optional[Any] = None,
) -> JSONResponse:
    """Standard error response wrapper."""
    return JSONResponse(
        status_code=status_code,
        content={"success": False, "code": code, "message": message, "data": data},
    )

