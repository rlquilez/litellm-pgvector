from typing import Optional, Dict, Any, List
from pydantic import BaseModel
from datetime import datetime


class VectorStoreCreateRequest(BaseModel):
    name: str
    file_ids: Optional[List[str]] = None
    expires_after: Optional[Dict[str, Any]] = None
    chunking_strategy: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = None


class VectorStoreResponse(BaseModel):
    id: str
    object: str = "vector_store"
    created_at: int
    name: str
    usage_bytes: int
    file_counts: Dict[str, int]
    status: str
    expires_after: Optional[Dict[str, Any]] = None
    expires_at: Optional[int] = None
    last_active_at: Optional[int] = None
    metadata: Optional[Dict[str, Any]] = None


class VectorStoreSearchRequest(BaseModel):
    query: str
    limit: Optional[int] = 20
    filters: Optional[Dict[str, Any]] = None
    return_metadata: Optional[bool] = True


class SearchResult(BaseModel):
    id: str
    content: str
    score: float
    metadata: Optional[Dict[str, Any]] = None


class VectorStoreSearchResponse(BaseModel):
    object: str = "vector_store.search"
    data: List[SearchResult]
    usage: Dict[str, int] 